# --- dev-infra Windows PowerShell 7 baseline profile ---
# Staged to $env:ProgramData\dev-infra\windows\shell\profile.ps1 and sourced by
# $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1.

# Alias powershell / powershell.exe to pwsh inside interactive sessions
# (PowerShell resolves aliases before PATH).
Set-Alias -Name powershell     -Value pwsh -Scope Global
Set-Alias -Name powershell.exe -Value pwsh -Scope Global
