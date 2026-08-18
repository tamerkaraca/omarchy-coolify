# Omarchy Coolify

An Omarchy Shell bar plugin for Coolify. It talks to your Coolify panel's MCP
endpoint, shows servers, projects, and applications with quick URL access, and
alerts when an application stops or recovers.

## Features

- In-plugin setup page for the Coolify panel URL and API key (English/Turkish UI)
- API key stored outside the repository in a mode `0600` user config file
- Servers, projects, and resource counts in a native Omarchy popup
- Per-project application list with domains; open or copy URLs from the keyboard
- j/k selection, o open, c copy, r refresh, s settings, ? shortcuts
- Desktop notification and a warning sound on healthy-to-down changes and recoveries
- No alert storm on first launch
- Configurable refresh interval and UI language
- API key configuration is passed to the helper over stdin, not process arguments

## Install

```bash
git clone https://github.com/tamerkaraca/omarchy-coolify.git
cd omarchy-coolify
./scripts/install.sh
```

Click the Coolify icon in the Omarchy bar, enter your Coolify base URL and an
API key, then choose **Save & Connect**. The plugin connects to the MCP endpoint
at `<url>/mcp`, so your Coolify instance must expose MCP and the API key must
have access to it.

The private configuration is stored at:

```text
~/.config/omarchy-coolify/config.json
```

## Project grouping

Coolify's MCP `list_applications` response currently omits the parent project
UUID, so the plugin keeps an optional `PROJECT_BY_APP` mapping
(application UUID → project UUID) in `plugin/coolify_mcp.py`. It ships empty:
add your own pairs if applications do not appear under their projects.

## Development

```bash
omarchy plugin validate plugin
```

Re-run `./scripts/install.sh` after changes. Omarchy Shell rescans the plugin.

## Uninstall

```bash
./scripts/uninstall.sh
```

Credentials are deliberately left in place. Remove
`~/.config/omarchy-coolify` yourself if you also want to erase settings.
