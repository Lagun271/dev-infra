#!/usr/bin/env bash
# Runs once after the container is created (devcontainer postCreateCommand).
# Installs user-level tooling from the infra repo package lists.
set -euo pipefail

INFRA_DIR="${INFRA_DIR:-$HOME/dev-infra}"
NPM_LIST="$INFRA_DIR/packages/npm-global.txt"

# ── Global npm packages ───────────────────────────────────────────────────────
if [[ -f "$NPM_LIST" ]]; then
  echo "==> Installing global npm packages"
  PACKAGES=$(grep -v '^\s*#' "$NPM_LIST" | grep -v '^\s*$')
  if [[ -n "$PACKAGES" ]]; then
    # shellcheck disable=SC2086
    npm install -g $PACKAGES
  fi
fi

# ── Git identity (inherited from host via devcontainer gitconfig mount) ───────
# VS Code devcontainers mount ~/.gitconfig automatically.
# Run gh auth setup-git manually after first open if HTTPS auth is needed.

# ── Shell comfort ─────────────────────────────────────────────────────────────
MARKER="# dev-infra bashrc"
if [[ -f "$INFRA_DIR/wsl/shell/bashrc.append" ]] && ! grep -qF "$MARKER" "$HOME/.bashrc"; then
  echo "" >> "$HOME/.bashrc"
  echo "$MARKER" >> "$HOME/.bashrc"
  cat "$INFRA_DIR/wsl/shell/bashrc.append" >> "$HOME/.bashrc"
fi

echo ""
echo "==> post-create complete."
