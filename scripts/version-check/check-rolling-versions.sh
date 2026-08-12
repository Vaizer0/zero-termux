#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: rolling version drift reporter.
# For every justified pin with a machine-readable latest source, resolve the
# current latest and report drift. Informational with exit 1 on any drift so
# the scheduled workflow surfaces a maintenance signal.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Table: name|resolver|target|pinned
# resolvers: github (tag_name), npm, pypi, gem, cargo, go (latest tagged)
MANIFEST=(
  'bettercap|github|bettercap/bettercap|2.41.7'
  'dalfox|github|hahwul/dalfox|3.2.0'
  'ffuf|github|ffuf/ffuf|v2.2.1'
  'fscan|github|shadow1ng/fscan|v2.1.3'
  'gitleaks|github|gitleaks/gitleaks|v8.30.1'
  'gowitness|github|sensepost/gowitness|3.1.1'
  'hashcat|github|hashcat/hashcat|7.1.2'
  'metabigor|github|j3ssie/metabigor|2.1.0'
  'metasploit-framework|github|rapid7/metasploit-framework|6.4.142'
  'openbullet2|github|OpenBullet2/OpenBullet2|2.0.1'
  'trufflehog|github|trufflesecurity/trufflehog|v3.96.0'
  'beef|github|beefproject/beef|v0.6.0.0'
  'hermes-agent|github|NousResearch/hermes-agent|2026.7.20'
  'jsql|github|ron190/jsql-injection|0.114'
  # Skipped (documented): burpsuite/burpsuite-pro (portswigger.net has no
  # machine-readable latest endpoint), ddos urllib3<2.0 (dependency compat),
  # turbopack Node LTS 22.14.0 (LTS floor), gentle-ai Go 1.25.10 (minimum
  # floor), termux-penv bootstrap fallback (offline fallback), spider
  # requirements.txt (reproducibility).
)

latest_github() {
  curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4
}
latest_npm() {
  curl -fsSL --max-time 30 "https://registry.npmjs.org/$1/latest" 2>/dev/null | grep '"version"' | head -1 | cut -d'"' -f4
}
latest_pypi() {
  curl -fsSL --max-time 30 "https://pypi.org/pypi/$1/json" 2>/dev/null | grep -m1 '"version"' | cut -d'"' -f4
}
latest_gem() {
  curl -fsSL --max-time 30 "https://rubygems.org/api/v1/gems/$1.json" 2>/dev/null | grep '"version"' | head -1 | cut -d'"' -f4
}

printf '%-22s %-16s %-16s %s\n' "package" "pinned" "latest" "status"
printf '%s\n' "----------------------------------------------------------------"
drift=0
for row in "${MANIFEST[@]}"; do
  IFS='|' read -r name resolver target pinned <<<"$row"
  latest=""
  case "$resolver" in
    github) latest="$(latest_github "$target")" ;;
    npm)    latest="$(latest_npm "$target")" ;;
    pypi)   latest="$(latest_pypi "$target")" ;;
    gem)    latest="$(latest_gem "$target")" ;;
    *) echo "unknown resolver $resolver for $name"; drift=1; continue ;;
  esac
  if [ -z "$latest" ]; then
    status="UNRESOLVED"
    drift=1
  elif [ "$latest" = "$pinned" ]; then
    status="ok"
  else
    status="DRIFT"
    drift=1
  fi
  printf '%-22s %-16s %-16s %s\n' "$name" "$pinned" "${latest:-?}" "$status"
done

if [ "$drift" -eq 0 ]; then
  echo "No drift detected"
else
  echo "Drift detected — review pinned versions above (see scripts/version-check/check-rolling-versions.sh)" >&2
  exit 1
fi
