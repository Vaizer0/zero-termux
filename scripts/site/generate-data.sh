#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: regenerate site/data/*.json from the repository.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
exec python3 scripts/site/generate-data.py