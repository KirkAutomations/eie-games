<#
.SYNOPSIS
    Auto-snapshot + git commit + push to GitHub Pages.
    Run from the project root.

.PARAMETER Message
    Commit message. Defaults to timestamped message.

.PARAMETER Tag
    Optional git tag (e.g. "v2.0").

.PARAMETER SnapshotOnly
    Just create a snapshot without committing/pushing.
#>
param(
    [string]$Message,
    [string]$Tag,
    [switch]$SnapshotOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"

# --- Step 1: Snapshot ---
$snapshotDir = Join-Path $projectRoot "versions\$timestamp"
New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
Get-ChildItem $projectRoot -Filter "*.html" | Copy-Item -Destination $snapshotDir
$fileCount = (Get-ChildItem $snapshotDir).Count
Write-Host "[SNAPSHOT] $fileCount files -> versions\$timestamp" -ForegroundColor Cyan

if ($SnapshotOnly) {
    Write-Host "[DONE] Snapshot only — no commit/push." -ForegroundColor Green
    return
}

# --- Step 2: Git commit ---
git add -A
if (-not $Message) {
    $Message = "deploy: $timestamp"
}
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Nothing to commit." -ForegroundColor Yellow
}

# --- Step 3: Tag (optional) ---
if ($Tag) {
    git tag $Tag
    Write-Host "[TAG] $Tag" -ForegroundColor Magenta
}

# --- Step 4: Push ---
$remote = git remote 2>&1
if ($remote) {
    git push origin HEAD --tags
    Write-Host "[PUSHED] to $remote" -ForegroundColor Green
} else {
    Write-Host "[SKIP] No remote configured — commit is local only." -ForegroundColor Yellow
}

Write-Host "[DONE] Snapshot + commit complete." -ForegroundColor Green
