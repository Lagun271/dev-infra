#!/usr/bin/env bash
# WSL baseline installer. Run after bootstrapping GitHub auth and cloning this repo.
# Idempotent — safe to re-run after adding packages to apt.txt.
set -euo pipefail

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "This installer is intended for WSL only." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add Google Cloud apt repo if not already present
if [[ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]]; then
  echo "==> Adding Google Cloud apt repository"
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
fi

echo "==> Installing WSL apt packages from apt.txt"
PACKAGES=$(grep -v '^\s*#' "$SCRIPT_DIR/apt.txt" | grep -v '^\s*$')
sudo apt-get update -qq
# shellcheck disable=SC2086
sudo apt-get install -y --no-install-recommends $PACKAGES

# Add current user to docker group so Docker socket works without sudo
if getent group docker &>/dev/null && ! id -nG "$USER" | grep -qw docker; then
  echo "==> Adding $USER to docker group"
  sudo usermod -aG docker "$USER"
  echo "    NOTE: log out and back in (or run 'newgrp docker') for this to take effect"
fi

# Install nvm if not present
if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
  echo "==> Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Install global npm packages from npm-host.txt
# shellcheck source=/dev/null
. "$HOME/.nvm/nvm.sh"
if ! nvm which current &>/dev/null; then
  echo "==> Installing default Node via nvm"
  nvm install --lts
  nvm alias default lts/*
fi
echo "==> Installing host npm packages"
NPM_PACKAGES=$(grep -v '^\s*#' "$SCRIPT_DIR/../packages/npm-host.txt" | grep -v '^\s*$')
if [[ -n "$NPM_PACKAGES" ]]; then
  # shellcheck disable=SC2086
  npm install -g $NPM_PACKAGES
fi

# Wire shell config via a single source line — changes to bashrc.sh take effect
# on the next shell open with no further edits to ~/.bashrc needed.
SOURCE_LINE="source \"$SCRIPT_DIR/shell/bashrc.sh\""
if ! grep -qF "$SOURCE_LINE" "$HOME/.bashrc"; then
  echo "==> Adding source line to ~/.bashrc"
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
fi

# Wire gh as git credential helper so pushes work without manual auth
gh auth setup-git

# Configure git identity from GitHub account if not already set
if ! git config --global user.email &>/dev/null; then
  echo "==> Configuring git identity from GitHub account"
  GH_USER=$(gh api user)
  GH_ID=$(echo "$GH_USER" | jq -r '.id')
  GH_LOGIN=$(echo "$GH_USER" | jq -r '.login')
  GH_NAME=$(echo "$GH_USER" | jq -r '.name // .login')
  GH_EMAIL=$(echo "$GH_USER" | jq -r '.email // empty')
  GH_EMAIL="${GH_EMAIL:-${GH_ID}+${GH_LOGIN}@users.noreply.github.com}"
  git config --global user.email "$GH_EMAIL"
  git config --global user.name "$GH_NAME"
fi

# Install Claude Code plugins from claude-plugins.txt
if command -v claude &>/dev/null; then
  echo "==> Installing Claude Code plugins"
  # Add wshobson/agents marketplace if not already present
  if ! claude plugin marketplace list 2>/dev/null | grep -q 'claude-code-workflows'; then
    claude plugin marketplace add wshobson/agents
  fi
  CLAUDE_PLUGINS=$(grep -v '^\s*#' "$SCRIPT_DIR/../packages/claude-plugins.txt" | grep -v '^\s*$')
  INSTALLED=$(claude plugin list 2>/dev/null || true)
  while IFS= read -r plugin; do
    plugin_name="${plugin%%@*}"
    if ! echo "$INSTALLED" | grep -q "$plugin_name"; then
      claude plugin install "$plugin"
    fi
  done <<< "$CLAUDE_PLUGINS"
fi

# Configure Bitwarden CLI to use EU server
if command -v bw &>/dev/null; then
  echo "==> Configuring Bitwarden CLI to use EU server"
  bw config server https://vault.bitwarden.eu
fi

# Install Claude Code on the Windows host so the Remote Control feature works
# (lets you dispatch and monitor sessions from your phone or browser).
# Auth and enabling Remote Control (/config) must be done manually afterward.
# Runs powershell.exe from WSL — intentionally mutates the Windows host.
WIN_HOME=$(powershell.exe -NoProfile -Command '$env:USERPROFILE' | tr -d '\r\n')
WIN_CLAUDE=$(wslpath "$WIN_HOME/.local/bin/claude.exe" 2>/dev/null || true)
if [[ -n "$WIN_CLAUDE" && ! -f "$WIN_CLAUDE" ]]; then
  echo "==> Installing Claude Code on Windows host"
  powershell.exe -NoProfile -Command "irm https://claude.ai/install.ps1 | iex"
  echo "    NOTE: open a new PowerShell window, run 'claude' to authenticate,"
  echo "    then enable Remote Control via /config inside Claude Code."
else
  echo "==> Claude Code already installed on Windows host, skipping"
fi

echo ""
echo "==> WSL baseline installed."
echo "    Open a new shell or run: source ~/.bashrc"
