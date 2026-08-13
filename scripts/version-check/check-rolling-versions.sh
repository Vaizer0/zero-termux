#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: rolling version drift reporter.
# For every tracked rolling package in versions.json, resolve the current
# upstream latest and report drift against the recorded version. Informational
# with exit 1 on any drift so the scheduled workflow surfaces a maintenance
# signal (bump DEBIAN/control Version and rebuild versions.json).
#
# Resolution mirrors what each package's postinst does at install time:
#   github-release / github-tag -> GitHub "latest release" (fall back to the
#                                  highest git tag for repos with no releases)
#   npm / pypi / gem / cargo     -> registry "latest"
#   go                           -> Go module proxy @latest
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Packages whose upstream never tags semver releases: the Go module proxy only
# serves moving pseudo-versions, so no fixed recorded version can ever match.
# Documented skip (version display only).
SKIP=(
  'mantra'   # github.com/Brosck/mantra — no tags, pseudo-version only
  'subjack'  # github.com/haccer/subjack — no tags, pseudo-version only
)

# --- helpers ---------------------------------------------------------------
# Extract a single quoted string value from a minified JSON document.
json_str() { grep -o '"'"$1"'"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4; }

# --- latest lookups per resolver -------------------------------------------
latest_github() {
  local t
  t="$(curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null | json_str tag_name)"
  if [ -z "$t" ]; then
    # No GitHub "releases": fall back to highest git tag (version-aware sort;
    # the /tags API is reverse-alphabetical, not chronological).
    t="$(git ls-remote --tags "https://github.com/$1.git" 2>/dev/null \
      | grep -v '\^{}' | sed -E 's#.*refs/tags/##' | sort -V | tail -1)"
  fi
  [ -n "$t" ] && printf '%s' "${t#v}"
}

latest_npm() {
  curl -fsSL --max-time 30 "https://registry.npmjs.org/$1/latest" 2>/dev/null | json_str version
}

latest_pypi() {
  curl -fsSL --max-time 30 "https://pypi.org/pypi/$1/json" 2>/dev/null | json_str version
}

latest_gem() {
  curl -fsSL --max-time 30 "https://rubygems.org/api/v1/gems/$1.json" 2>/dev/null | json_str version
}

latest_go() {
  # Extract the module path (first 3 segments + optional /vN) and escape
  # uppercase letters for the module proxy (A -> !a).
  local p="$1"
  local base rest first
  base="$(printf '%s' "$p" | cut -d/ -f1-3)"
  rest="$(printf '%s' "$p" | cut -d/ -f4-)"
  [ -n "$rest" ] && [ "$rest" != "$p" ] && {
    first="$(printf '%s' "$rest" | cut -d/ -f1)"
    case "$first" in v[0-9]*) base="$base/$first" ;; esac
  }
  local mod
  mod="$(printf '%s' "$base" | sed -E 's/([A-Z])/!\l\1/g')"
  curl -fsSL --max-time 30 "https://proxy.golang.org/$mod/@latest" 2>/dev/null \
    | json_str Version | sed 's/^v//'
}

latest_cargo() {
  curl -fsSL --max-time 30 -A "zero-termux maintenance" "https://crates.io/api/v1/crates/$1" 2>/dev/null | json_str max_stable_version
}

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
  latest=""
  case "$resolver" in
    github-release|github-tag) latest="$(latest_github "$source")" ;;
    npm)  latest="$(latest_npm "$source")" ;;
    pypi) latest="$(latest_pypi "$source")" ;;
    gem)  latest="$(latest_gem "$source")" ;;
    go)   latest="$(latest_go "$source")" ;;
    cargo) latest="$(latest_cargo "$source")" ;;
    *) echo "unknown resolver $resolver for $name"; drift=1; continue ;;
  esac
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
  echo "Drift detected — bump DEBIAN/control Version and rebuild versions.json (see scripts/version-check/)" >&2
  exit 1
fi
