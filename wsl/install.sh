#!/usr/bin/env bash
# WSL baseline installer. Run after bootstrapping GitHub auth and cloning this repo.
# Idempotent — safe to re-run after adding packages to apt.txt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Append shell config if not already present
MARKER="# dev-infra bashrc"
if ! grep -qF "$MARKER" "$HOME/.bashrc"; then
  echo "==> Appending shell config to ~/.bashrc"
  echo "" >> "$HOME/.bashrc"
  echo "$MARKER" >> "$HOME/.bashrc"
  cat "$SCRIPT_DIR/shell/bashrc.append" >> "$HOME/.bashrc"
fi

echo ""
echo "==> WSL baseline installed."
echo "    Open a new shell or run: source ~/.bashrc"
