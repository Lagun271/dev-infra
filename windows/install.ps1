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
    Copy-Item -Recurse -Force -Path "$scriptDir\*" -Destination $stageDir
    Copy-Item -Force -Path (Join-Path $scriptDir '..\packages\dotnet-tool-windows.txt') -Destination $stageDir

    Write-Host "==> Elevating once; installation continues in an administrator window."
    $sysPowershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $proc = Start-Process -FilePath $sysPowershell -Verb RunAs -Wait -PassThru -ArgumentList `
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

    # Configure PowerShell 7 (pwsh) as the default shell for terminals and coding agents:
    # 1. Wire $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 to source
    #    $env:ProgramData\dev-infra\windows\shell\profile.ps1.
    # 2. Set PowerShell 7 as the default profile in Windows Terminal and hide 5.1.
    Write-Host ""
    Write-Host "==> Configuring PowerShell 7 profile and Windows Terminal default"
    $docsDir = [Environment]::GetFolderPath('MyDocuments')
    $pwshProfileDir = Join-Path $docsDir 'PowerShell'
    New-Item -ItemType Directory -Force -Path $pwshProfileDir | Out-Null
    $pwshProfile = Join-Path $pwshProfileDir 'Microsoft.PowerShell_profile.ps1'
    $sourceLine = '. "$env:ProgramData\dev-infra\windows\shell\profile.ps1"'
    if (-not (Test-Path $pwshProfile)) {
        Set-Content -Path $pwshProfile -Encoding UTF8 -Value $sourceLine
    } elseif (-not (Select-String -Path $pwshProfile -SimpleMatch -Quiet $sourceLine)) {
        Add-Content -Path $pwshProfile -Encoding UTF8 -Value "`r`n$sourceLine"
    }

    $wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wtSettings) {
        $wtJson = Get-Content -Raw -Path $wtSettings | ConvertFrom-Json
        $pwshGuid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
        $ps5Guid  = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
        $wtJson.defaultProfile = $pwshGuid
        $hasPwsh = $false
        foreach ($p in $wtJson.profiles.list) {
            if ($p.guid -eq $pwshGuid) {
                $p.hidden = $false
                $hasPwsh = $true
            } elseif ($p.guid -eq $ps5Guid) {
                $p.hidden = $true
            }
        }
        if (-not $hasPwsh) {
            $wtJson.profiles.list = @([pscustomobject]@{
                guid   = $pwshGuid
                name   = 'PowerShell'
                source = 'Windows.Terminal.PowershellCore'
                hidden = $false
            }) + @($wtJson.profiles.list)
        }
        $wtJson | ConvertTo-Json -Depth 32 | Set-Content -Path $wtSettings -Encoding UTF8
    }

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

    # .NET global tools, e.g. ilspycmd (ILSpy CLI). Runs after Visual Studio so the
    # .NET SDK it provides is on PATH. `dotnet tool update -g` installs a tool that
    # isn't present yet and updates one that is, so this step is idempotent.
    $toolsFile = Join-Path $scriptDir 'dotnet-tool-windows.txt'
    if (Test-Path $toolsFile) {
        Write-Host ""
        Write-Host "==> Installing .NET global tools from packages/dotnet-tool-windows.txt"
        Get-Content $toolsFile | ForEach-Object {
            $tool = $_.Trim()
            if ($tool -and -not $tool.StartsWith('#')) {
                Write-Host "    - $tool"
                dotnet tool update -g $tool
                if ($LASTEXITCODE -ne 0) {
                    throw "dotnet tool update -g $tool failed (exit code $LASTEXITCODE)"
                }
            }
        }
    }

    # netcoredbg, pinned from its GitHub release (winget's version is too old for ClrVoyant).
    Write-Host ""
    Write-Host "==> Installing netcoredbg"
    & (Join-Path $scriptDir 'install-netcoredbg.ps1')
} catch {
    # The elevated window closes on exit - keep it open so the error can be read.
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
