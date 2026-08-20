#!/usr/bin/env python3
"""Small stdlib-only MCP client for the Coolify Omarchy widget.

Configuration is stored in the user's own directory (~/.config/omarchy-coolify),
never inside the plugin directory, so distributing the plugin does not ship a
private API token. Subcommands:

  poll      -> fetch infrastructure overview (servers, projects, apps, counts)
  config    -> print public config (no token)
  configure -> read JSON on stdin and save the connection settings
  key       -> print the stored token (for the settings form only)
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

ROOT = os.path.dirname(os.path.abspath(__file__))
ICON = os.path.join(ROOT, "assets", "coolify.svg")

# Legacy location: the first Codex version stored config + state next to the
# plugin. Migrate once, then remove the copies so a distributed plugin never
# leaks a token.
LEGACY_CONFIG = os.path.join(ROOT, "config.json")
LEGACY_STATE = os.path.join(ROOT, "state.json")

APP_DIR = Path.home() / ".config" / "omarchy-coolify"
CONFIG_FILE = APP_DIR / "config.json"
STATE_FILE = APP_DIR / "state.json"

LANGUAGES = {"en", "tr"}

STRINGS = {
    "en": {
        "configure_first": "Save connection settings first",
        "unauthorized": "Unauthorized — check your API key",
        "mcp_not_found": "MCP not found — check the Coolify address",
        "http_error": "Coolify returned HTTP {code}",
        "connection_error": "Connection error: {error}",
        "config_missing": "Coolify MCP settings missing",
        "mcp_init_failed": "Couldn't initialize MCP",
        "tool_failed": "{name} failed",
        "bad_input": "Couldn't read settings data",
        "bad_payload": "Invalid settings data",
        "empty_url": "Coolify address can't be empty",
        "invalid_url": "Enter a valid Coolify address (http/https)",
        "empty_key": "API key can't be empty",
        "down_title": "Coolify: application stopped",
        "recovered_title": "Coolify: application recovered",
        "app_fallback": "Application",
        "and_more": " and {n} more applications",

    },
    "tr": {
        "configure_first": "Önce bağlantı ayarlarını kaydedin",
        "unauthorized": "Yetkisiz erişim — API key'i kontrol edin",
        "mcp_not_found": "MCP bulunamadı — Coolify adresini kontrol edin",
        "http_error": "Coolify HTTP {code} döndürdü",
        "connection_error": "Bağlantı hatası: {error}",
        "config_missing": "Coolify MCP ayarları eksik",
        "mcp_init_failed": "MCP başlatılamadı",
        "tool_failed": "{name} başarısız",
        "bad_input": "Ayar verisi okunamadı",
        "bad_payload": "Ayar verisi geçersiz",
        "app_fallback": "Uygulama",
        "empty_url": "Coolify adresi boş bırakılamaz",

        "invalid_url": "Geçerli bir Coolify adresi girin (http/https)",
        "empty_key": "API key boş bırakılamaz",
        "down_title": "Coolify: uygulama durdu",
        "recovered_title": "Coolify: uygulama düzeldi",
        "and_more": " ve {n} uygulama daha",
    },
}


def t(lang: str, key: str, **kwargs) -> str:
    table = STRINGS.get(lang, STRINGS["en"])
    text = table.get(key, key)
    return text.format(**kwargs) if kwargs else text


def detect_language() -> str:
    raw = (os.environ.get("LANG") or os.environ.get("LC_ALL") or os.environ.get("LC_MESSAGES") or "")
    code = raw.split("_", 1)[0].split(".", 1)[0].strip().lower()
    return code if code in LANGUAGES else "en"


def effective_language(config: dict) -> str:
    chosen = str(config.get("language", "")).strip().lower()
    return chosen if chosen in LANGUAGES else detect_language()


# Coolify's MCP resource summaries now include project_uuid, so resources are
# grouped automatically. Keep this map only as a manual override for older
# Coolify versions whose list_applications omitted the parent project UUID.
PROJECT_BY_APP = {
}


def default_config() -> dict:
    return {
        "url": "",
        "token": "",
        "refresh_seconds": 30,
        "language": "",
    }


def read_json(path: Path, fallback: dict) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else fallback.copy()
    except (OSError, json.JSONDecodeError):
        return fallback.copy()


def atomic_write(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        os.chmod(temp_name, 0o600)
        os.replace(temp_name, path)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def migrate_legacy_config() -> None:
    """Move the old plugin-directory config into the user directory, then remove
    the plugin-directory copies so a distributed plugin never ships a token."""
    if CONFIG_FILE.exists() or not os.path.exists(LEGACY_CONFIG):
        return
    try:
        with open(LEGACY_CONFIG, "r", encoding="utf-8") as handle:
            legacy = json.load(handle)
        if not isinstance(legacy, dict):
            legacy = {}
    except (OSError, json.JSONDecodeError):
        legacy = {}

    url = str(legacy.get("endpoint", "")).strip()
    if url.endswith("/mcp"):
        url = url[:-4]
    url = url.rstrip("/")

    config = default_config()
    if url:
        config["url"] = url
    config["token"] = str(legacy.get("token", "")).strip()
    try:
        config["refresh_seconds"] = int(legacy.get("refresh_seconds", 30))
    except (TypeError, ValueError):
        config["refresh_seconds"] = 30

    if config["url"] or config["token"]:
        atomic_write(CONFIG_FILE, config)

    for legacy_path in (LEGACY_CONFIG, LEGACY_STATE):
        try:
            os.unlink(legacy_path)
        except OSError:
            pass


def load_config() -> dict:
    migrate_legacy_config()
    return read_json(CONFIG_FILE, default_config())


def public_config(config: dict, **extra) -> dict:
    site_url = str(config.get("url", "")).strip().rstrip("/")
    result = {
        "configured": bool(site_url and str(config.get("token", "")).strip()),
        "siteUrl": site_url,
        "dashboard": (site_url + "/") if site_url else "",
        "refreshSeconds": int(config.get("refresh_seconds", 30)),
        "language": effective_language(config),
    }
    result.update(extra)
    return result


def normalize_url(raw: str) -> str:
    url = raw.strip().rstrip("/")
    if url.endswith("/mcp"):
        url = url[:-4].rstrip("/")
    if not url:
        raise ValueError("empty_url")
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("invalid_url")
    return url


def post(endpoint, token, payload, session=""):
    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
        "User-Agent": "curl/8.17.0",
    }
    if session:
        headers["Mcp-Session-Id"] = session
    request = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        raw = response.read().decode("utf-8")
        return json.loads(raw) if raw.strip() else {}, response.headers.get("Mcp-Session-Id", "")


def tool_data(endpoint, token, session, request_id, lang, name, arguments=None):
    result, _ = post(endpoint, token, {
        "jsonrpc": "2.0", "id": request_id, "method": "tools/call",
        "params": {"name": name, "arguments": arguments or {}},
    }, session)
    if "error" in result:
        raise RuntimeError(result["error"].get("message", t(lang, "tool_failed", name=name)))
    blocks = result.get("result", {}).get("content", [])
    text = next((item.get("text", "") for item in blocks if item.get("type") == "text"), "")
    parsed = json.loads(text)
    return parsed.get("data", parsed)


def app_display_name(app):
    repository = str(app.get("git_repository") or "").rstrip("/")
    if repository:
        return repository.split("/")[-1]
    name = str(app.get("name") or "Uygulama")
    return name.split(":", 1)[0]


def short_resource_name(name):
    # Service and database names carry a "-<uuid>" suffix Coolify appends;
    # strip it so the panel shows the human-chosen name only.
    value = str(name or "")
    return re.sub(r"-[a-z0-9]{16,}$", "", value) or value


def notify(title, body, critical=False):
    subprocess.run(
        ["notify-send", "-u", "critical" if critical else "normal", "-a", "Coolify", "-i", ICON, title, body],
        check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    sounds = (
        (["canberra-gtk-play", "-i", "dialog-warning"], ["paplay", "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"])
        if critical else
        (["canberra-gtk-play", "-i", "complete"], ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"])
    )
    for command in sounds:
        try:
            if subprocess.run(command, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
                break
        except FileNotFoundError:
            continue


def notify_transitions(applications, lang):
    APP_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    current = {str(app.get("uuid") or ""): str(app.get("status") or "unknown") for app in applications}
    previous = read_json(STATE_FILE, {})
    previous = previous.get("statuses", {}) if isinstance(previous.get("statuses"), dict) else {}

    if previous:
        down = [app_display_name(app) for app in applications
                if "running:healthy" not in current.get(str(app.get("uuid") or ""), "")
                and "running:healthy" in str(previous.get(str(app.get("uuid") or ""), ""))]
        recovered = [app_display_name(app) for app in applications
                     if "running:healthy" in current.get(str(app.get("uuid") or ""), "")
                     and "running:healthy" not in str(previous.get(str(app.get("uuid") or ""), ""))]
        if down:
            body = down[0] if len(down) == 1 else down[0] + t(lang, "and_more", n=len(down) - 1)
            notify(t(lang, "down_title"), body, True)
        if recovered:
            body = recovered[0] if len(recovered) == 1 else recovered[0] + t(lang, "and_more", n=len(recovered) - 1)
            notify(t(lang, "recovered_title"), body)

    atomic_write(STATE_FILE, {"statuses": current})


def overview(config, lang):
    site_url = str(config.get("url", "")).strip().rstrip("/")
    endpoint = site_url + "/mcp"
    token = str(config.get("token", "")).strip()
    if not site_url or not token:
        raise RuntimeError(t(lang, "config_missing"))

    initialized, session = post(endpoint, token, {
        "jsonrpc": "2.0", "id": 1, "method": "initialize",
        "params": {
            "protocolVersion": "2025-03-26", "capabilities": {},
            "clientInfo": {"name": "omarchy-coolify", "version": "0.1.0"},
        },
    })
    if "error" in initialized:
        raise RuntimeError(initialized["error"].get("message", t(lang, "mcp_init_failed")))
    post(endpoint, token, {"jsonrpc": "2.0", "method": "notifications/initialized"}, session)
    data = tool_data(endpoint, token, session, 2, lang, "get_infrastructure_overview")
    applications = tool_data(endpoint, token, session, 3, lang, "list_applications", {"page": 1, "per_page": 100})
    services = tool_data(endpoint, token, session, 4, lang, "list_services", {"page": 1, "per_page": 100})
    databases = tool_data(endpoint, token, session, 5, lang, "list_databases", {"page": 1, "per_page": 100})
    applications = applications if isinstance(applications, list) else []
    services = services if isinstance(services, list) else []
    databases = databases if isinstance(databases, list) else []
    notify_transitions(applications, lang)

    def group(items, kind):
        by_project = {}
        for item in items:
            item = dict(item)
            uuid = str(item.get("uuid") or "")
            project_uuid = str(item.get("project_uuid") or PROJECT_BY_APP.get(uuid, ""))
            item["display_name"] = app_display_name(item) if kind == "application" else short_resource_name(item.get("name"))
            item["urls"] = [url.strip() for url in str(item.get("fqdn") or "").split(",") if url.strip()]
            item["primary_url"] = item["urls"][0] if item["urls"] else ""
            status = str(item.get("status") or "")
            item["status_label"] = status.rsplit(":", 1)[-1] if status else ""
            by_project.setdefault(project_uuid, []).append(item)
        return by_project

    apps_by_project = group(applications, "application")
    services_by_project = group(services, "service")
    databases_by_project = group(databases, "database")

    def by_name(items):
        return sorted(items, key=lambda item: str(item.get("display_name", "")).casefold())

    for project in data.get("projects", []):
        project_uuid = str(project.get("uuid") or "")
        project["applications"] = by_name(apps_by_project.get(project_uuid, []))
        project["services"] = by_name(services_by_project.get(project_uuid, []))
        project["databases"] = by_name(databases_by_project.get(project_uuid, []))
    data["dashboard"] = site_url + "/"
    data["refreshSeconds"] = int(config.get("refresh_seconds", 30))
    return data


def poll() -> int:
    config = load_config()
    lang = effective_language(config)
    base = public_config(config)
    if not base["configured"]:
        print(json.dumps(public_config(config, error=t(lang, "configure_first")), ensure_ascii=False))
        return 0
    try:
        data = overview(config, lang)
    except urllib.error.HTTPError as error:
        if error.code in {401, 403}:
            message = t(lang, "unauthorized")
        elif error.code == 404:
            message = t(lang, "mcp_not_found")
        else:
            message = t(lang, "http_error", code=error.code)
        print(json.dumps(public_config(config, error=message), ensure_ascii=False))
        return 1
    except (OSError, ValueError, RuntimeError, urllib.error.URLError) as error:
        print(json.dumps(public_config(config, error=t(lang, "connection_error", error=str(error))), ensure_ascii=False))
        return 1
    data.update(base)
    print(json.dumps(data, ensure_ascii=False))
    return 0


def configure() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        print(t(detect_language(), "bad_input"), file=sys.stderr)
        return 2
    if not isinstance(payload, dict):
        print(t(detect_language(), "bad_payload"), file=sys.stderr)
        return 2

    requested = str(payload.get("language", "")).strip().lower()
    lang = requested if requested in LANGUAGES else detect_language()

    config = load_config()
    try:
        config["url"] = normalize_url(str(payload.get("url", "")))
    except ValueError as error:
        print(t(lang, str(error)), file=sys.stderr)
        return 2
    token = str(payload.get("key", "")).strip()
    if token:
        config["token"] = token
    if not str(config.get("token", "")).strip():
        print(t(lang, "empty_key"), file=sys.stderr)
        return 2
    try:
        interval = int(payload.get("interval", 30))
    except (TypeError, ValueError):
        interval = 30
    config["refresh_seconds"] = max(10, min(3600, interval))
    config["language"] = requested if requested in LANGUAGES else ""
    atomic_write(CONFIG_FILE, config)
    print(json.dumps(public_config(config), ensure_ascii=False))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("poll")
    subparsers.add_parser("config")
    subparsers.add_parser("key")
    subparsers.add_parser("configure")
    args = parser.parse_args()

    if args.command == "poll":
        return poll()
    if args.command == "configure":
        return configure()
    if args.command == "key":
        config = load_config()
        print(str(config.get("token", "")).strip())
        return 0
    config = load_config()
    print(json.dumps(public_config(config), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
