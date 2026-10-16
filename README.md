# dev-infra

Personal development environment definitions for Windows + WSL 2 + devcontainers. The goal is a reproducible setup where a new machine can be brought to a working state with a single command, and where every durable change is committed here rather than living only on the host.

## Layer model

| Layer | Responsibility |
|---|---|
| Windows host | RobotStudio, Visual Studio, GUI apps, Docker Desktop, PowerShell 7 (`pwsh`), Antigravity CLI |
| WSL host | Git, GitHub CLI, Docker socket access, minimal shell |
| Devcontainer | All development tooling, CLIs, coding agents |

Keeping the WSL host minimal means the container carries everything needed for development and can be rebuilt cleanly at any time.

## Fresh Windows setup

Run from PowerShell:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\windows\install.ps1
```

The `-ExecutionPolicy Bypass` flag is required because scripts on UNC paths (e.g. cloned into a WSL filesystem) are treated as remote and blocked by default. The script asks for elevation once (a single UAC prompt), copies itself to `C:\ProgramData\dev-infra\windows`, and runs the rest unattended in an administrator window.

### PowerShell 7 (`pwsh`) for terminals and coding agents

`install.ps1` installs PowerShell 7 (`Microsoft.PowerShell` in `windows/winget.json`) and configures it so your terminals and coding agents use PowerShell 7 instead of Windows PowerShell 5.1:

1. **Windows Terminal default**: Sets PowerShell 7 (`pwsh.exe`) as the `defaultProfile` in Windows Terminal and hides the legacy `Windows PowerShell` (5.1) entry from the tab menu.
2. **PowerShell 7 profile (`windows/shell/profile.ps1`)**: Staged to `$env:ProgramData\dev-infra\windows\shell\profile.ps1` and sourced from `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`. It aliases `powershell` and `powershell.exe` to `pwsh` inside interactive sessions.

### Visual Studio 2026

Visual Studio 2026 (Community) is installed by a separate step in `install.ps1`, because `winget import` can't pass installer options. Its workloads come from `windows/vs2026.vsconfig`. On first run the script installs VS with that config. On later runs it re-applies the config with the VS Installer's `modify` command, so workloads added to the file get installed. Workloads removed from the file stay installed: the VS Installer adds components from a `.vsconfig` but never removes them. To get component IDs from an existing install, open VS Installer → More → Export configuration.

### .NET debugging from Claude Code (ClrVoyant)

`install.ps1` installs the ClrVoyant MCP server (`packages/dotnet-tool-windows.txt`) and a pinned netcoredbg (`windows/install-netcoredbg.ps1`). ClrVoyant's bundled netcoredbg is too old: its call stacks fail with `0x80004002` through native frames, e.g. in WinForms event handlers or RobotStudio add-ins ([Samsung/netcoredbg#215](https://github.com/Samsung/netcoredbg/issues/215)). Register it once per machine, pointing at the pinned netcoredbg:

```powershell
claude mcp add clrvoyant --scope user --transport stdio `
  --env DOTNET_ROLL_FORWARD=Major `
  --env "CLRVOYANT_NETCOREDBG=$env:LOCALAPPDATA\Programs\netcoredbg\3.2.0-1092\netcoredbg.exe" `
  -- "$env:USERPROFILE\.dotnet\tools\clrvoyant.exe"
```

The name goes first because `--env` takes every following argument up to the next option. `DOTNET_ROLL_FORWARD=Major` lets the net8.0 tool run when only a newer .NET runtime is installed. Drop `CLRVOYANT_NETCOREDBG` once ClrVoyant bundles netcoredbg 3.2.0-1092 or later.

## Fresh WSL setup

**Step 1 — Install the distro** (PowerShell on the Windows host):

```powershell
wsl --install -d Ubuntu-26.04
```

**Step 2 — Run the bootstrap** (inside the WSL shell, not PowerShell — `curl` in PowerShell is an alias for `Invoke-WebRequest` and will not work):

```bash
curl -fsSL https://raw.githubusercontent.com/Lagun271/dev-infra/main/bootstrap.sh | bash
```

The bootstrap installs `gh`, authenticates with GitHub, clones this repo, then runs `wsl/install.sh` to apply the full baseline.

## Repo structure

```
bootstrap.sh                        # curl-pipeable entry point for a fresh distro
windows/
  install.ps1                       # Windows baseline installer
  install-netcoredbg.ps1            # pinned netcoredbg from its GitHub release
  shell/profile.ps1                 # PowerShell 7 profile config sourced by $PROFILE
  winget.json                       # winget package list
  vs2026.vsconfig                   # Visual Studio 2026 workloads/components
wsl/
  apt.txt                           # WSL host packages
  install.sh                        # idempotent baseline installer
  shell/bashrc.sh                   # shell config sourced by ~/.bashrc
  README.md                         # Docker socket setup, credential helpers
devcontainers/
  general/                          # one general-purpose devcontainer for all projects
    .devcontainer/
      devcontainer.json
      Dockerfile
      post-create.sh
packages/
  npm-global.txt                    # global npm tools installed in the container
  dotnet-tool-windows.txt           # .NET global tools installed on the Windows host
scripts/
  check-tools.sh                    # verify expected tools are present
  check-network.sh                  # verify DNS, HTTPS, and Docker socket
```

## Working rule

Manual installs are fine for experiments. Durable changes belong in this repo:

| What | Where |
|---|---|
| Windows apps | `windows/winget.json` |
| Windows PowerShell 7 profile config | `windows/shell/profile.ps1` |
| Visual Studio workload or component | `windows/vs2026.vsconfig` |
| WSL apt package | `wsl/apt.txt` |
| WSL shell config | `wsl/shell/bashrc.sh` |
| WSL install step | `wsl/install.sh` |
| npm global tool | `packages/npm-global.txt` |
| .NET global tool on Windows (e.g. ilspycmd) | `packages/dotnet-tool-windows.txt` |
| Windows binary not on winget, or too old there | Its own pinned, checksum-verified script in `windows/` (e.g. `install-netcoredbg.ps1`) |
| Container tool or package | `devcontainers/general/.devcontainer/Dockerfile` |
| Container post-create step | `devcontainers/general/.devcontainer/post-create.sh` |
| Host or network fix | `wsl/README.md` |
| Secret or token | Document the required variable — never commit the value |
