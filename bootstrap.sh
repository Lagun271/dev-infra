#!/usr/bin/env bash
# Public bootstrap — safe to curl | bash from a fresh WSL distro.
# Installs only what is needed to authenticate and clone the private infra repo,
# then hands off to wsl/install.sh for the full baseline.
set -euo pipefail

INFRA_REPO="${INFRA_REPO:-niklas-skoglund/dev-infra}"
INFRA_DIR="${INFRA_DIR:-$HOME/dev-infra}"

echo "==> Updating apt and installing bootstrap dependencies"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  gpg

# Install GitHub CLI if not present
if ! command -v gh &>/dev/null; then
  echo "==> Installing GitHub CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gh
fi

# Authenticate with GitHub
if ! gh auth status &>/dev/null; then
  echo "==> Authenticating with GitHub (browser/device flow)"
  gh auth login --web --git-protocol https
fi

# Clone or update the infra repo
if [[ -d "$INFRA_DIR/.git" ]]; then
  echo "==> Updating existing infra repo at $INFRA_DIR"
  git -C "$INFRA_DIR" pull --ff-only
else
  echo "==> Cloning $INFRA_REPO to $INFRA_DIR"
  gh repo clone "$INFRA_REPO" "$INFRA_DIR"
fi

echo "==> Running WSL baseline installer"
bash "$INFRA_DIR/wsl/install.sh"
