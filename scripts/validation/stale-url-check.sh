#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: stale URL audit.
# Fails if dead upstream URLs (old website, Telegram, old GPG path, rebrand
# artifacts) appear anywhere except third-party github.com/termuxvoid/* clones.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

STALE_RE='termuxvoid\.github\.io|telegram\.me/nullxvoid|devcorex-web\.vercel\.app|DevCoreXOfficial/zero-termux|termuxvoid\.gpg|sources\.list\.d/termuxvoid|TermuxVoid/repo'

ALLOW_RE='github\.com/termuxvoid/|DevCoreXOfficial/nvchad-termux|rm \$PREFIX/etc/apt/sources\.list\.d/termuxvoid\.list|GPG key .termuxvoid\.gpg.'

mapfile -t FILES < <(find . -type f \
  -not -path './.git/*' \
  -not -path './debs/*' \
  -not -path './repo/*' \
  -not -path './_site/*' \
  -not -name 'branding-check.sh' \
  -not -name 'stale-url-check.sh' \
  -not -name 'version-pin-check.sh' \
  -not -name 'validate-packages.sh')

VIOLATIONS="$(rg -i --no-messages -e "$STALE_RE" "${FILES[@]}" 2>/dev/null | rg -iv -e "$ALLOW_RE" || true)"

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  echo "Stale URL check FAILED" >&2
  exit 1
fi
echo "Stale URL check OK"
