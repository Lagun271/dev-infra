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

# Wire shell config via a single source line — changes to bashrc.sh take effect
# on the next shell open with no further edits to ~/.bashrc needed.
SOURCE_LINE="source \"$SCRIPT_DIR/shell/bashrc.sh\""
if ! grep -qF "$SOURCE_LINE" "$HOME/.bashrc"; then
  echo "==> Adding source line to ~/.bashrc"
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
fi

echo ""
echo "==> WSL baseline installed."
echo "    Open a new shell or run: source ~/.bashrc"
