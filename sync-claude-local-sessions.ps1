[CmdletBinding()]
param(
    [string]$BasePath = (Join-Path $env:APPDATA "Claude"),
    [switch]$SkipBackup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Get-LeafSessionDirectories {
    param([string]$SessionRoot)

    Get-ChildItem -Path $SessionRoot -Directory |
        ForEach-Object { Get-ChildItem -Path $_.FullName -Directory } |
        Select-Object -ExpandProperty FullName
}

$sessionRoot = Join-Path $BasePath "claude-code-sessions"
if (-not (Test-Path $sessionRoot)) {
    throw "Session root not found: $sessionRoot"
}

$leafDirs = @(Get-LeafSessionDirectories -SessionRoot $sessionRoot)
if ($leafDirs.Count -lt 2) {
    throw "Expected at least 2 account/org session directories under $sessionRoot"
}

$sourceFiles = @(Get-ChildItem -Path $sessionRoot -Recurse -File -Filter "local_*.json")
if ($sourceFiles.Count -eq 0) {
    throw "No local session files found under $sessionRoot"
}

$backupPath = $null
if (-not $SkipBackup -and -not $DryRun) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $BasePath ("backup-claude-code-sessions-" + $timestamp)
    Copy-Item -Recurse -Force $sessionRoot $backupPath
}

$copied = New-Object System.Collections.Generic.List[object]
$skipped = 0

foreach ($targetDir in $leafDirs) {
    foreach ($src in $sourceFiles) {
        $dest = Join-Path $targetDir $src.Name
        if (Test-Path $dest) {
            $skipped++
            continue
        }

        $copied.Add([PSCustomObject]@{
            File = $src.Name
            TargetDir = $targetDir
        })

        if (-not $DryRun) {
            Copy-Item -Path $src.FullName -Destination $dest
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Claude local session sync dry-run complete." -ForegroundColor Yellow
} else {
    Write-Host "Claude local session sync complete." -ForegroundColor Green
}

if ($backupPath) {
    Write-Host "Backup:" $backupPath
}

Write-Host "Leaf dirs:"
$leafDirs | ForEach-Object { Write-Host " - $_" }

Write-Host "Would copy:" $copied.Count
if (-not $DryRun) {
    Write-Host "Skipped existing:" $skipped
}

if ($copied.Count -gt 0) {
    Write-Host ""
    if ($DryRun) {
        Write-Host "Missing session files:"
    } else {
        Write-Host "New copies:"
    }

    $copied | ForEach-Object {
        Write-Host " - $($_.File) -> $($_.TargetDir)"
    }
}

Write-Host ""
Write-Host "Current session inventory:"
Get-ChildItem -Path $sessionRoot -Recurse -File -Filter "local_*.json" |
    Sort-Object FullName |
    ForEach-Object {
        $json = Get-Content -Raw $_.FullName | ConvertFrom-Json
        Write-Host " - $($_.Name) | $($json.title)"
    }

if (-not $DryRun -and (Get-Process -Name "Claude" -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude is running. Restart Claude to reload synced sessions."
}
