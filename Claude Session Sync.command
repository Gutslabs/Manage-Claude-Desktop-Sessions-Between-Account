#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"${SCRIPT_DIR}/sync-claude-local-sessions.sh"

echo
read -r -n 1 -s -p "Sync finished. Press any key to close..."
echo
