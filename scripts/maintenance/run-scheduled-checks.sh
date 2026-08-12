#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: scheduled maintenance checks (weekly).
# Runs the full static validation suite plus the rolling-version drift report.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail=0

for check in \
  scripts/validation/validate-packages.sh \
  scripts/validation/branding-check.sh \
  scripts/validation/version-pin-check.sh \
  scripts/validation/stale-url-check.sh; do
  echo "=== $check ==="
  bash "$check" || fail=1
done

echo "=== scripts/version-check/check-rolling-versions.sh ==="
bash scripts/version-check/check-rolling-versions.sh || fail=1

if [ "$fail" -eq 0 ]; then
  echo "All maintenance checks OK"
else
  echo "Maintenance checks reported issues" >&2
  exit 1
fi
