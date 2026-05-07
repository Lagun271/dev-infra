#!/usr/bin/env bash
# Verify basic network connectivity from WSL: DNS, HTTPS, GitHub, Docker Hub.
set -uo pipefail

PASS=0
FAIL=0

ok()   { echo "  [OK]  $*"; ((PASS++)); }
fail() { echo "  [FAIL] $*"; ((FAIL++)); }

echo "=== DNS ==="
if host github.com &>/dev/null || nslookup github.com &>/dev/null; then
  ok "DNS resolves github.com"
else
  fail "DNS cannot resolve github.com"
fi

echo ""
echo "=== HTTPS reachability ==="
for url in \
  "https://github.com" \
  "https://api.github.com" \
  "https://registry-1.docker.io" \
  "https://deb.nodesource.com" \
  "https://astral.sh" \
  "https://releases.hashicorp.com"
do
  if curl -fsS --max-time 8 "$url" -o /dev/null; then
    ok "$url"
  else
    fail "$url"
  fi
done

echo ""
echo "=== Docker socket ==="
if docker info &>/dev/null; then
  ok "Docker daemon reachable"
else
  fail "Docker daemon not reachable — check Docker Desktop WSL integration"
fi

echo ""
if ((FAIL == 0)); then
  echo "All $PASS checks passed."
else
  echo "$PASS passed, $FAIL failed."
  exit 1
fi
