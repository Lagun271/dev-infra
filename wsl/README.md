# WSL Baseline

The WSL host is intentionally minimal. It provides authentication, Docker socket access, and enough shell comfort to open devcontainers. Development tooling lives inside containers.

## What belongs here vs. in the container

| Host (wsl/apt.txt) | Container (Dockerfile) |
|---|---|
| gh, git, curl | Node, Python, .NET |
| docker CLI, compose | build tools, linters |
| gnupg, jq, wget | project CLIs |
| SSH/Git credential store | coding agents |

## Docker socket

Docker Desktop for Windows exposes a socket inside WSL automatically when "Use the WSL 2 based engine" and the distro integration are enabled in Docker Desktop settings.

The `bashrc.append` script sets `DOCKER_HOST` to whichever socket is present at login.

If `docker ps` fails:
1. Confirm Docker Desktop is running on Windows.
2. In Docker Desktop → Settings → Resources → WSL Integration, enable the distro.
3. Log out and back in to WSL.

## Git credential helper

After running `install.sh`, configure Git to use the GitHub CLI credential helper so HTTPS clones work without a PAT:

```bash
gh auth setup-git
```

## SSH agent (optional)

If you prefer SSH over HTTPS, add your key and configure Git:

```bash
ssh-keygen -t ed25519 -C "your@email"
gh ssh-key add ~/.ssh/id_ed25519.pub --title "WSL $(hostname)"
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

## Updating the baseline

Add a package to `wsl/apt.txt`, commit, then re-run:

```bash
cd ~/dev-infra && git pull && bash wsl/install.sh
```
