#!/usr/bin/env bash
set -euo pipefail

omarchy plugin disable community.coolify 2>/dev/null || true
omarchy plugin remove community.coolify --yes
printf 'Plugin removed. User credentials remain in ~/.config/omarchy-coolify.\n'
