#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/community.coolify"

install -d -m 0755 "$plugin_dir"
install -d -m 0755 "$plugin_dir/assets"
install -m 0644 "$project_dir/plugin/manifest.json" "$plugin_dir/manifest.json"
install -m 0644 "$project_dir/plugin/Panel.qml" "$plugin_dir/Panel.qml"
install -m 0755 "$project_dir/plugin/coolify_mcp.py" "$plugin_dir/coolify_mcp.py"
install -m 0644 "$project_dir/plugin/assets/coolify.svg" "$plugin_dir/assets/coolify.svg"

omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
omarchy plugin enable community.coolify right
printf 'Coolify plugin installed. Open it from the Omarchy bar to configure.\n'
