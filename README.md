# dev-infra

Development environment definitions for WSL baseline and devcontainers.

## Model

| Layer | Contents |
|---|---|
| Windows host | RobotStudio, GUI apps, Docker Desktop |
| WSL host | Git, GitHub CLI, Docker socket access, minimal shell |
| Devcontainer | All development tooling, CLIs, coding agents |

## Fresh WSL Setup

From an elevated PowerShell prompt on the Windows host:

```powershell
# Install a fresh Ubuntu distro if needed
wsl --install -d Ubuntu-24.04

# Inside WSL, run the public bootstrap
curl -fsSL https://raw.githubusercontent.com/<user>/dev-infra/main/bootstrap.sh | bash
```

The bootstrap installs the minimum tools to authenticate and clone this repo, then hands off to `wsl/install.sh`.

## Working Rule

Manual installs are fine for experiments. Durable changes belong in this repo:

| What | Where |
|---|---|
| WSL apt package | `wsl/apt.txt` |
| WSL shell setup | `wsl/shell/bashrc.append` |
| WSL install step | `wsl/install.sh` |
| npm global tool | `packages/npm-global.txt` |
| Container apt/tool | `devcontainers/general/.devcontainer/Dockerfile` |
| Container post-create step | `devcontainers/general/.devcontainer/post-create.sh` |
| Host/network fix | `wsl/README.md` |
| Secret/token | Document the required variable — never commit the value |
