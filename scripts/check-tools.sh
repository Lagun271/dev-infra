#!/usr/bin/env bash
# Print version of each expected tool. Pass/fail summary at the end.
set -uo pipefail

PASS=0
FAIL=0

check() {
  local name="$1"
  shift
  if version=$("$@" 2>&1 | head -1); then
    printf "  %-20s %s\n" "$name" "$version"
    ((PASS++))
  else
    printf "  %-20s MISSING\n" "$name"
    ((FAIL++))
  fi
}

echo "=== WSL host tools ==="
check git        git --version
check gh         gh --version
check gcloud     gcloud --version
check docker     docker --version
check curl       curl --version
check jq         jq --version

echo ""
echo "=== Container / dev tools (run inside devcontainer) ==="
check node       node --version
check npm        npm --version
check python3    python3 --version
check uv         uv --version
check dotnet     dotnet --version
check terraform  terraform --version
check make       make --version

echo ""
if ((FAIL == 0)); then
  echo "All $PASS tools present."
else
  echo "$PASS present, $FAIL missing."
  exit 1
fi
