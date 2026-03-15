# Claude Local Session Sync

Sync `Claude Code` local sessions across multiple Claude Desktop accounts on the same machine.

## Status

Windows only for now. macOS support is planned soon.

## What it does

Claude Desktop stores local Claude Code sessions under:

```text
%APPDATA%\Claude\claude-code-sessions\<accountId>\<orgId>\local_*.json
```

This script finds every `local_*.json` session file and copies missing ones into the other account/org session folders, so the same local sessions become visible from multiple Claude accounts on the same Windows install.

## What it does not do

- It does not migrate cloud chat history from `claude.ai`
- It does not merge or edit remote account data
- It only works with local Claude Code session files already present on your machine

## Requirements

- Windows only for now
- Claude Desktop installed
- At least two Claude account/org session folders already created locally

## Files

- `sync-claude-local-sessions.ps1`: main sync script for Windows
- `Claude Session Sync.bat`: double-click launcher for Windows users

## Usage

### Option 1: Double-click

Double-click `Claude Session Sync.bat`

### Option 2: PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-claude-local-sessions.ps1
```

### Dry run

See what would be copied without changing anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-claude-local-sessions.ps1 -DryRun
```

### Skip backup

By default the script creates a backup under `%APPDATA%\Claude\backup-claude-code-sessions-<timestamp>`.

To skip that:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-claude-local-sessions.ps1 -SkipBackup
```

## Safety

- Default behavior creates a backup before writing
- Existing session files are not overwritten
- If Claude Desktop is open, restart it after sync so it reloads the updated local session list


## How it works

1. Detect every account/org leaf folder under `%APPDATA%\Claude\claude-code-sessions`
2. Collect every `local_*.json` file found there
3. Copy missing session files into the other leaf folders
4. Leave existing files untouched

## Notes

- This project is based on observed local Claude Desktop storage behavior and may need updates if Anthropic changes the folder structure in future releases.
