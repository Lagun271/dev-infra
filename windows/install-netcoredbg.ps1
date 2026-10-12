# Installs a pinned netcoredbg (Samsung's MIT-licensed .NET debugger) from its GitHub
# release, verified by SHA-256, into %LOCALAPPDATA%\Programs\netcoredbg\<version>.
# Called by install.ps1; can also be run on its own (no elevation needed).
# Idempotent - skips the download if that version is already installed.
#
# Not from winget: Samsung.NetCoreDbg there is 3.1.3-1062, whose stackTrace fails with
# 0x80004002 on frames reached through native code (Samsung/netcoredbg#215, fixed in
# 3.2.0-1092). ClrVoyant uses this copy via CLRVOYANT_NETCOREDBG.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$version = '3.2.0-1092'
$sha256 = '3c410a45fa502415203a94fcb88654af65bf8e3dac158a5527a722e7a6b9274a'
$url = "https://github.com/Samsung/netcoredbg/releases/download/$version/netcoredbg-win64.zip"
$dest = Join-Path $env:LOCALAPPDATA "Programs\netcoredbg\$version"

if (Test-Path (Join-Path $dest 'netcoredbg.exe')) {
    Write-Host "    netcoredbg $version already installed in $dest"
    return
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "netcoredbg-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp 'netcoredbg-win64.zip'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $zip
    $got = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
    if ($got -ne $sha256) {
        throw "netcoredbg checksum mismatch: expected $sha256, got $got"
    }
    Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'x')
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -Recurse -Force -Path (Join-Path $tmp 'x\netcoredbg\*') -Destination $dest
    Write-Host "    netcoredbg $version installed in $dest"
}
finally {
    Remove-Item -Recurse -Force -Path $tmp -ErrorAction SilentlyContinue
}
