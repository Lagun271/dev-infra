# dev-infra

Personal development environment definitions for Windows + WSL 2 + devcontainers. The goal is a reproducible setup where a new machine can be brought to a working state with a single command, and where every durable change is committed here rather than living only on the host.

## Layer model

| Layer | Responsibility |
|---|---|
| Windows host | RobotStudio, GUI apps, Docker Desktop |
| WSL host | Git, GitHub CLI, Docker socket access, minimal shell |
| Devcontainer | All development tooling, CLIs, coding agents |

Keeping the WSL host minimal means the container carries everything needed for development and can be rebuilt cleanly at any time.

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
scripts/
  check-tools.sh                    # verify expected tools are present
  check-network.sh                  # verify DNS, HTTPS, and Docker socket
```

## Working rule

Manual installs are fine for experiments. Durable changes belong in this repo:

| What | Where |
|---|---|
| WSL apt package | `wsl/apt.txt` |
| WSL shell config | `wsl/shell/bashrc.sh` |
| WSL install step | `wsl/install.sh` |
| npm global tool | `packages/npm-global.txt` |
| Container tool or package | `devcontainers/general/.devcontainer/Dockerfile` |
| Container post-create step | `devcontainers/general/.devcontainer/post-create.sh` |
| Host or network fix | `wsl/README.md` |
| Secret or token | Document the required variable — never commit the value |
