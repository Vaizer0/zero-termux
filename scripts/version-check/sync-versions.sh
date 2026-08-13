#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: sync recorded versions to current upstream latest.
# For every tracked rolling package in versions.json, resolve the upstream
# latest (scripts/lib/version.sh) and, when it differs, bump the package's
# DEBIAN/control Version to the canonical upstream version, then rebuild
# versions.json. Exit 1 if any package could not be resolved or produced a
# non-Debian version (so a partially-synced state is never committed blindly).
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source scripts/lib/version.sh

ver_norm() { printf '%s' "$1" | sed -E 's/^[^0-9]*//; s/[-_]/./g'; }
debian_ok() { case "$1" in ''|*[!0-9a-zA-Z.+~-]*) return 1 ;; [0-9]*) return 0 ;; *) return 1 ;; esac; }

# Mirrors the checker's documented skips (pseudo-version-only Go modules).
SKIP=( 'mantra' 'subjack' )

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

changed=0
fail=0
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
  [ -n "$latest" ] || { echo "UNRESOLVED $name ($resolver $source)" >&2; fail=1; continue; }
  new="$(ver_norm "$latest")"
  if ! debian_ok "$new"; then
    echo "INVALID VERSION $name: $new" >&2
    fail=1
    continue
  fi
  if [ "$(ver_norm "$recorded")" = "$new" ]; then
    echo "ok    $name ($recorded)"
    continue
  fi
  ctrl="packages/$name/DEBIAN/control"
  if [ ! -f "$ctrl" ]; then
    echo "NO CONTROL $name" >&2
    fail=1
    continue
  fi
  sed -i -E "0,/^Version:.*/s/^Version:.*/Version: $new/" "$ctrl"
  echo "bump  $name: $recorded -> $new"
  changed=$((changed + 1))
done

python3 scripts/version-check/build-manifest.py

if [ "$fail" -ne 0 ]; then
  echo "sync completed with errors ($fail)" >&2
  exit 1
fi
echo "sync ok: $changed package(s) updated"
