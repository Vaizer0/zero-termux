#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: branding regression check.
# Fails if old-brand references (TermuxVoid, Core-Termux, devcorex, stale URLs)
# appear anywhere outside the explicit allowlist:
#   - provenance: Maintainer fields, Alienkrishn / Anon4You attribution, license notices
#   - third-party dependencies: github.com/termuxvoid/* repos (incl. api.github.com
#     release lookups), TermuxVoid-Theme, DevCoreXOfficial/nvchad-termux,
#     `**Author:** DevCoreX` tool attributions
#   - legacy-path migration references in install.sh / MIGRATION.md
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TOKENS='TermuxVoid|Core-Termux|CORE-TERMUX|core-termux|devcorex|termuxvoid\.github\.io|telegram\.me/nullxvoid|termuxvoid\.gpg'

ALLOW_RE='termuxvoid/|TermuxVoid-Theme|Void-Fonts|Maintainer:|Alienkrishn|Anon4You|DevCoreX|Termux Void Repo|TermuxVoid lineage|s/TermuxVoid/|upstream:? (Core-Termux|TermuxVoid)|upstream TermuxVoid|derived from the TermuxVoid repository|### (Core-Termux|TermuxVoid)|termuxvoid\.(list|gpg)|APT suite .termuxvoid.'

mapfile -t FILES < <(find . -type f \
  -not -path './.git/*' \
  -not -path './debs/*' \
  -not -path './repo/*' \
  -not -path './_site/*' \
  -not -path './node_modules/*' \
  -not -name '*.deb' \
  -not -name 'branding-check.sh' \
  -not -name 'stale-url-check.sh' \
  -not -name 'version-pin-check.sh' \
  -not -name 'validate-packages.sh')

VIOLATIONS="$(rg -i --no-messages -e "$TOKENS" "${FILES[@]}" 2>/dev/null | rg -iv -e "$ALLOW_RE" || true)"

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  echo "Branding check FAILED" >&2
  exit 1
fi
echo "Branding check OK"
