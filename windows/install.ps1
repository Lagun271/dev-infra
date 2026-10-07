# Windows baseline installer. Run from PowerShell as a regular user.
# Requires winget (included with Windows 11).
# Idempotent - safe to re-run.
#
# Asks for elevation once (a single UAC prompt), then installs everything
# unattended in an elevated window.
param([switch]$Elevated)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stageDir = Join-Path $env:ProgramData 'dev-infra\windows'

if (-not $Elevated) {
    # Stage the scripts on a local path: an elevated process may not be able to
    # read a UNC path (repo cloned into WSL), and the VS installer needs a local
    # config path without spaces.
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
    Copy-Item -Force -Path "$scriptDir\*" -Destination $stageDir

    Write-Host "==> Elevating once; installation continues in an administrator window."
    $proc = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList `
        "-NoProfile -ExecutionPolicy Bypass -File `"$stageDir\install.ps1`" -Elevated"
    if ($proc.ExitCode -ne 0) {
        throw "Elevated install failed (exit code $($proc.ExitCode))"
    }
    Write-Host ""
    Write-Host "==> Windows baseline installed."
    Write-Host "    Restart your terminal for PATH changes to take effect."
    Write-Host "    A reboot may be needed to finish the Visual Studio install."
    exit 0
}

try {
    Write-Host "==> Installing Windows packages from winget.json"
    winget import -i "$scriptDir\winget.json" --accept-package-agreements --accept-source-agreements `
        --ignore-versions --disable-interactivity

    # Visual Studio 2026 is installed separately: winget import cannot pass installer
    # overrides, and the workload selection lives in vs2026.vsconfig.
    $vsPackageId = 'Microsoft.VisualStudio.Community'
    $vsProduct = 'Microsoft.VisualStudio.Product.Community'
    $vsVersionRange = '[18.0,19.0)'
    $vsConfig = "$scriptDir\vs2026.vsconfig"

    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vsPath = $null
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -products $vsProduct -version $vsVersionRange -property installationPath | Select-Object -First 1
    }

    if (-not $vsPath) {
        Write-Host ""
        Write-Host "==> Installing Visual Studio 2026 ($vsPackageId) - this takes a while"
        winget install --id $vsPackageId -e --accept-package-agreements --accept-source-agreements `
            --disable-interactivity `
            --override "--quiet --wait --norestart --includeRecommended --config $vsConfig"
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
            throw "Visual Studio install failed (exit code $LASTEXITCODE)"
        }
    } else {
        Write-Host ""
        Write-Host "==> Syncing Visual Studio 2026 workloads from vs2026.vsconfig ($vsPath)"
        $setup = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
        $proc = Start-Process -FilePath $setup -Wait -PassThru -ArgumentList `
            "modify --installPath `"$vsPath`" --config `"$vsConfig`" --includeRecommended --quiet --norestart"
        if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
            throw "Visual Studio modify failed (exit code $($proc.ExitCode))"
        }
    }
} catch {
    # The elevated window closes on exit - keep it open so the error can be read.
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
