# Windows baseline installer. Run from PowerShell as a regular user.
# Requires winget (included with Windows 11).
# Idempotent — safe to re-run.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Installing Windows packages from winget.json"
winget import -i "$scriptDir\winget.json" --accept-package-agreements --accept-source-agreements --ignore-versions

Write-Host ""
Write-Host "==> Windows baseline installed."
Write-Host "    Restart your terminal for PATH changes to take effect."
