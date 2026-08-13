#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: rolling version drift reporter.
# For every tracked rolling package in versions.json, resolve the current
# upstream latest and report drift against the recorded version. Informational
# with exit 1 on any drift so the scheduled workflow surfaces a maintenance
# signal (run scripts/version-check/sync-versions.sh, then rebuild versions.json).
#
# Resolution uses scripts/lib/version.sh (mirrors each package's postinst).
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source scripts/lib/version.sh

# Canonicalize a version for comparison: drop leading tag prefixes (v, bun-v,
# Ghidra_, ...) and map '-'/'_' to '.' so the recorded version survives the
# Debian upstream/revision hyphen split and still matches the raw upstream tag.
ver_norm() { printf '%s' "$1" | sed -E 's/^[^0-9]*//; s/[-_]/./g'; }

# Packages whose upstream never tags semver releases: the Go module proxy only
# serves moving pseudo-versions, so no fixed recorded version can ever match.
# Documented skip (version display only).
SKIP=(
  'mantra'   # github.com/Brosck/mantra — no tags, pseudo-version only
  'subjack'  # github.com/haccer/subjack — no tags, pseudo-version only
)

# --- iterate versions.json -------------------------------------------------
[ -f scripts/version-check/versions.json ] || {
  echo "versions.json missing — run: python3 scripts/version-check/build-manifest.py" >&2
  exit 1
}

mapfile -t NAMES < <(python3 -c "
import json,sys
v=json.load(open('scripts/version-check/versions.json'))
for n,p in sorted(v['packages'].items()):
    print('%s\t%s\t%s' % (n, p.get('resolver',''), p.get('source','')))
")

printf '%-24s %-18s %-18s %s\n' "package" "recorded" "latest" "status"
printf '%s\n' "----------------------------------------------------------------"
drift=0
for row in "${NAMES[@]:-}"; do
  [ -z "$row" ] && continue
  IFS=$'\t' read -r name resolver source <<<"$row"
  case " ${SKIP[*]:-} " in
    *" $name "*) continue ;;
  esac
  recorded="$(python3 -c "
import json,sys
v=json.load(open('scripts/version-check/versions.json'))
sys.stdout.write(v['packages'].get('$name',{}).get('upstream',''))
")"
  latest="$(resolve_version "$resolver" "$source" 2>/dev/null)" || latest=""
  latest="$(ver_norm "$latest")"
  recorded="$(ver_norm "$recorded")"
  if [ -z "$latest" ]; then
    status="UNRESOLVED"
    drift=1
  elif [ "$latest" = "$recorded" ]; then
    status="ok"
  else
    status="DRIFT"
    drift=1
  fi
  printf '%-24s %-18s %-18s %s\n' "$name" "$recorded" "${latest:-?}" "$status"
done

if [ "$drift" -eq 0 ]; then
  echo "No drift detected"
else
  echo "Drift detected — run scripts/version-check/sync-versions.sh" >&2
  exit 1
fi
