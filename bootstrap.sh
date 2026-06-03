#!/usr/bin/env bash
# Public bootstrap — safe to curl | bash from a fresh WSL distro.
# Installs only what is needed to authenticate and clone this repo,
# then hands off to wsl/install.sh for the full baseline.
set -euo pipefail

INFRA_REPO="${INFRA_REPO:-Lagun271/dev-infra}"
INFRA_DIR="${INFRA_DIR:-$HOME/dev-infra}"

# Prefer IPv4 over IPv6 to prevent network reachability issues in dual-stack networks with no IPv6 routing
if [[ -f /etc/gai.conf ]] && ! grep -E -q "^precedence\s+::ffff:0:0/96\s+100" /etc/gai.conf; then
  echo "==> Configuring gai.conf to prefer IPv4 over IPv6"
  if grep -q "^#precedence\s\+::ffff:0:0/96\s\+100" /etc/gai.conf; then
    sudo sed -i 's/^#precedence\s\+::ffff:0:0\/96\s\+100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf
  else
    echo "precedence ::ffff:0:0/96 100" | sudo tee -a /etc/gai.conf > /dev/null
  fi
fi

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
