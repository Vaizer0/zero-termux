#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: version-pin regression check.
# Fails if any pinned version appears outside the justified-pin manifest.
# Rolling tools must use @latest / -U / dynamic GitHub API resolution instead.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Justified pins (each has a `# Zero-Termux: justified pin` comment in source):
#   packages/*/DEBIAN/postinst  — source-build tags, jar assets, dependency compat
#   core/tools/**/install.sh    — Node LTS, Go minimum floors
#   packages data payloads      — offline fallback / reproducibility
JUST_RE='VERSION="2\.41\.7"|VERSION="3\.2\.0"|TAG="v2\.2\.1"|--branch v2\.1\.3|TAG="v8\.30\.1"|TAG="3\.1\.1"|7\.1\.2|VERSION="2\.1\.0"|TAG="6\.4\.142"|VERSION="2\.0\.1"|TAG="v3\.96\.0"|v0\.6\.0\.0|urllib3<2\.0|version=2026\.1\.2&type=jar|version=2026\.1\.5&type=jar|VERSION="2026\.7\.20"|jsql-injection-v0\.114|bootstrap-2025\.10\.19-r1|telethon==1\.28\.5|prettytable==3\.9\.0|colorama==0\.4\.6|pyrogram==2\.0\.106|tgcrypto==1\.2\.4|python-dotenv==1\.0\.0|NODE_VERSION="22\.14\.0"|go_required="1\.25\.10"'

# Pin patterns: registry pins, literal release URLs, literal version assignments, git tag clones
PIN_RE='@[0-9][0-9.]*|==[0-9][0-9.]*| -v [0-9]+\.[0-9]+|--version [0-9]+\.[0-9]+|releases/download/[^" ]*[0-9][0-9.]*|tags/v[0-9][0-9.]*|VERSION="[0-9]|TAG="[vV]?[0-9]|--branch v?[0-9]'

# Dynamic forms are fine: API resolution, @latest, variable-interpolated URLs,
# version-reporting commands, the core CLI's own version
OK_RE='api\.github\.com|@latest|\$\{?[A-Za-z_]+\}?|\$[A-Za-z_]+|CORE_VERSION=|-v \$\(gem|gem list'

mapfile -t FILES < <(find packages core -type f \
  \( -path '*/DEBIAN/*' -o -name 'install.sh' -o -name '*.sh' -o -name '*.py' -o -name 'requirements.txt' -o -name '*.toml' \) \
  -not -path '*/data/*' 2>/dev/null)

# data payloads with known pins
FILES+=(packages/termux-penv/data/data/com.termux/files/usr/share/termux-penv/termux-pacman32.sh)
FILES+=(packages/termux-penv/data/data/com.termux/files/usr/share/termux-penv/termux-pacman64.sh)
FILES+=(packages/spider/data/data/com.termux/files/usr/lib/spider/report/requirements.txt)

VIOLATIONS="$(rg -nN --no-messages -e "$PIN_RE" "${FILES[@]}" 2>/dev/null \
  | rg -v -e "$OK_RE" \
  | rg -v -e "$JUST_RE" || true)"

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  echo "Version-pin check FAILED (add new justified pins to scripts/validation/version-pin-check.sh with a source comment)" >&2
  exit 1
fi
echo "Version-pin check OK"
