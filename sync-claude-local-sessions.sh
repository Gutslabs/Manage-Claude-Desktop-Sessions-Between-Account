#!/usr/bin/env bash

set -euo pipefail

base_path="${HOME}/Library/Application Support/Claude"
skip_backup=0
dry_run=0

usage() {
  cat <<'EOF'
Usage: ./sync-claude-local-sessions.sh [--base-path PATH] [--skip-backup] [--dry-run]

Options:
  --base-path PATH   Override the Claude app data directory
  --skip-backup      Do not create a backup before syncing
  --dry-run          Show what would be copied without changing anything
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-path)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --base-path" >&2
        exit 1
      fi
      base_path="$2"
      shift 2
      ;;
    --skip-backup)
      skip_backup=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

session_root="${base_path}/claude-code-sessions"
if [[ ! -d "${session_root}" ]]; then
  echo "Session root not found: ${session_root}" >&2
  exit 1
fi

mapfile -t leaf_dirs < <(find "${session_root}" -mindepth 2 -maxdepth 2 -type d | sort)
if [[ ${#leaf_dirs[@]} -lt 2 ]]; then
  echo "Expected at least 2 account/org session directories under ${session_root}" >&2
  exit 1
fi

mapfile -t source_files < <(find "${session_root}" -type f -name 'local_*.json' | sort)
if [[ ${#source_files[@]} -eq 0 ]]; then
  echo "No local session files found under ${session_root}" >&2
  exit 1
fi

backup_path=""
if [[ "${skip_backup}" -eq 0 && "${dry_run}" -eq 0 ]]; then
  timestamp="$(date +"%Y%m%d-%H%M%S")"
  backup_path="${base_path}/backup-claude-code-sessions-${timestamp}"
  cp -R "${session_root}" "${backup_path}"
fi

copied=0
skipped=0
copied_items=()

for target_dir in "${leaf_dirs[@]}"; do
  for src in "${source_files[@]}"; do
    dest="${target_dir}/$(basename "${src}")"
    if [[ -e "${dest}" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    copied_items+=("$(basename "${src}") -> ${target_dir}")
    copied=$((copied + 1))

    if [[ "${dry_run}" -eq 0 ]]; then
      cp "${src}" "${dest}"
    fi
  done
done

echo
if [[ "${dry_run}" -eq 1 ]]; then
  echo "Claude local session sync dry-run complete."
else
  echo "Claude local session sync complete."
fi

if [[ -n "${backup_path}" ]]; then
  echo "Backup: ${backup_path}"
fi

echo "Leaf dirs:"
for dir in "${leaf_dirs[@]}"; do
  echo " - ${dir}"
done

echo "Would copy: ${copied}"
if [[ "${dry_run}" -eq 0 ]]; then
  echo "Skipped existing: ${skipped}"
fi

if [[ ${#copied_items[@]} -gt 0 ]]; then
  echo
  if [[ "${dry_run}" -eq 1 ]]; then
    echo "Missing session files:"
  else
    echo "New copies:"
  fi

  for item in "${copied_items[@]}"; do
    echo " - ${item}"
  done
fi

echo
echo "Current session inventory:"
find "${session_root}" -type f -name 'local_*.json' | sort | while read -r file; do
  echo " - $(basename "${file}")"
done

if [[ "${dry_run}" -eq 0 ]]; then
  if pgrep -x "Claude" >/dev/null 2>&1 || pgrep -f "/Claude.app/" >/dev/null 2>&1; then
    echo "Warning: Claude is running. Restart Claude to reload synced sessions." >&2
  fi
fi
