#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: reusable latest-version resolution library.
#
# Shared by scripts/version-check/sync-versions.sh, the scheduled maintenance
# workflow, and any package installer that needs to resolve the latest stable
# upstream release at runtime.
#
# Every resolver:
#   - returns the version string on stdout (empty on failure),
#   - honours ZT_GH_TOKEN for GitHub API rate limits,
#   - retries transient failures with backoff,
#   - FAILS LOUDLY (never silently falls back to a hardcoded version).
#
# Resolvers provided:
#   resolve_github_latest <owner/repo>      -> latest release tag (v stripped)
#   resolve_github_tag_latest <owner/repo>  -> latest tag on any branch
#   resolve_github_asset  <owner/repo> <regex> <arch-hint>
#                                            -> download URL of matching asset
#   resolve_npm_latest    <package>          -> latest dist-tag version
#   resolve_pypi_latest   <package>          -> latest release version
#   resolve_gem_latest    <package>          -> latest version
#   resolve_cargo_latest  <crate>            -> max stable version
#   resolve_go_latest     <module path>      -> latest tagged pseudo-version
#
# Helpers:
#   vlog <msg>            -> stderr log line (ZT_VERBOSE=1)
#   vcurl <args...>       -> curl with retries/backoff + auth header
#   ver_sanitize <version> -> strip leading v, normalize for Debian Version:

set -u

CURL_BIN="${CURL_BIN:-curl}"
RETRIES="${ZT_RETRIES:-3}"
RETRY_DELAY="${ZT_RETRY_DELAY:-2}"
TIMEOUT="${ZT_HTTP_TIMEOUT:-30}"
GH_API="https://api.github.com"

vlog() { [ "${ZT_VERBOSE:-0}" = "1" ] && echo "[version-lib] $*" >&2; }

vcurl() {
  local attempt i out
  for i in $(seq 1 "$RETRIES"); do
    out="$("$CURL_BIN" -fsSL --max-time "$TIMEOUT" "${GH_AUTH[@]:-}" "$@" 2>/dev/null)" && { echo "$out"; return 0; }
    [ "$i" -lt "$RETRIES" ] && sleep "$((RETRY_DELAY * i))"
  done
  return 1
}

# Prefer a GitHub token when present (higher API rate limit).
GH_AUTH=()
if [ -n "${ZT_GH_TOKEN:-}" ]; then
  GH_AUTH=(-H "Authorization: Bearer $ZT_GH_TOKEN")
fi

ver_sanitize() {
  # Strip leading v/V, collapse + to ., drop trailing -dev/-git noise.
  printf '%s' "$1" | sed -E 's/^[vV]//; s/\+/-/g'
}

# --- GitHub: latest release tag -------------------------------------------
resolve_github_latest() {
  local repo="$1"
  local data
  data="$(vcurl "$GH_API/repos/$repo/releases/latest")" || { vlog "github latest failed: $repo"; return 1; }
  local tag
  tag="$(printf '%s' "$data" | grep -o '"tag_name"[^,]*' | head -1 | cut -d'"' -f4)"
  [ -n "$tag" ] || { vlog "no tag_name in response for $repo"; return 1; }
  ver_sanitize "$tag"
}

# --- GitHub: latest tag (projects that never cut "releases") ---------------
# Uses `git ls-remote --tags` (no API rate limit) and a version-aware sort,
# because the GitHub /tags API returns tags in reverse-ALPHABETICAL order,
# which does not match chronological/version order (e.g. v4.11.7 vs 6.4.142).
resolve_github_tag_latest() {
  local repo="$1"
  local tag
  tag="$(git ls-remote --tags "https://github.com/$repo.git" 2>/dev/null \
    | grep -v '\^{}' \
    | sed -E 's#.*refs/tags/##' \
    | sort -V \
    | tail -1)"
  [ -n "$tag" ] || { vlog "no tags for $repo"; return 1; }
  ver_sanitize "$tag"
}

# --- GitHub: architecture-aware asset selection ----------------------------
# Resolves the browser_download_url of the first release asset whose name
# matches <regex> AND (if given) an arch keyword for the current platform.
# Mapping: aarch64/arm64 -> arm64/aarch64, x86_64/amd64 -> x64/amd64/x86_64,
#          armv7l/arm   -> armv7/armhf, i686 -> i686.
resolve_github_asset() {
  local repo="$1" regex="$2" arch_hint="${3:-}"
  local data
  data="$(vcurl "$GH_API/repos/$repo/releases/latest")" || { vlog "github asset failed: $repo"; return 1; }

  local arch_key=""
  case "$(uname -m)" in
    aarch64|arm64) arch_key="(arm64|aarch64)" ;;
    x86_64|amd64)  arch_key="(x64|amd64|x86_64)" ;;
    armv7*|armhf|arm) arch_key="(armv7|armhf)" ;;
    i686)          arch_key="i686" ;;
    *) arch_key="(arm64|aarch64|x64|amd64|x86_64)" ;;
  esac

  local match
  if [ -n "$arch_hint" ]; then
    match="$(printf '%s' "$data" | grep -o '"browser_download_url": *"[^"]*"' | grep -E "$regex" | grep -E "$arch_key" | head -1 | cut -d'"' -f4)"
  else
    match="$(printf '%s' "$data" | grep -o '"browser_download_url": *"[^"]*"' | grep -E "$regex" | head -1 | cut -d'"' -f4)"
  fi
  [ -n "$match" ] || { vlog "no asset matching $regex ($arch_key) for $repo"; return 1; }
  echo "$match"
}

# --- npm -------------------------------------------------------------------
resolve_npm_latest() {
  local pkg="$1"
  local data
  data="$(vcurl "https://registry.npmjs.org/$pkg/latest")" || { vlog "npm failed: $pkg"; return 1; }
  local ver
  ver="$(printf '%s' "$data" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -n "$ver" ] || { vlog "no version for npm $pkg"; return 1; }
  ver_sanitize "$ver"
}

# --- PyPI ------------------------------------------------------------------
resolve_pypi_latest() {
  local pkg="$1"
  local data
  data="$(vcurl "https://pypi.org/pypi/$pkg/json")" || { vlog "pypi failed: $pkg"; return 1; }
  local ver
  ver="$(printf '%s' "$data" | grep -m1 -o '"version":[[:space:]]*"[^"]*"' | cut -d'"' -f4)"
  [ -n "$ver" ] || { vlog "no version for pypi $pkg"; return 1; }
  ver_sanitize "$ver"
}

# --- RubyGems ----------------------------------------------------------------
resolve_gem_latest() {
  local gem="$1"
  local data
  data="$(vcurl "https://rubygems.org/api/v1/gems/$gem.json")" || { vlog "gem failed: $gem"; return 1; }
  local ver
  ver="$(printf '%s' "$data" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -n "$ver" ] || { vlog "no version for gem $gem"; return 1; }
  ver_sanitize "$ver"
}

# --- crates.io ---------------------------------------------------------------
resolve_cargo_latest() {
  local crate="$1"
  local data
  data="$(vcurl "https://crates.io/api/v1/crates/$crate")" || { vlog "cargo failed: $crate"; return 1; }
  local ver
  ver="$(printf '%s' "$data" | grep -o '"newest_version":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -n "$ver" ] || { vlog "no version for crate $crate"; return 1; }
  ver_sanitize "$ver"
}

# --- Go modules (proxy.golang.org @latest) -----------------------------------
resolve_go_latest() {
  local mod="$1"
  # module path is case-encoded by the proxy; keep it as the source of truth.
  local data
  data="$(vcurl "https://proxy.golang.org/$mod/@latest")" || { vlog "go proxy failed: $mod"; return 1; }
  local ver
  ver="$(printf '%s' "$data" | grep -o '"Version":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -n "$ver" ] || { vlog "no version for go $mod"; return 1; }
  ver_sanitize "$ver"
}

# Dispatch by resolver name. Usage: resolve_version <resolver> <upstream>
resolve_version() {
  local resolver="$1" upstream="$2"
  case "$resolver" in
    github-release) resolve_github_latest "$upstream" ;;
    github-tag)     resolve_github_tag_latest "$upstream" ;;
    npm)            resolve_npm_latest "$upstream" ;;
    pypi)           resolve_pypi_latest "$upstream" ;;
    gem)            resolve_gem_latest "$upstream" ;;
    cargo)          resolve_cargo_latest "$upstream" ;;
    go)             resolve_go_latest "$upstream" ;;
    *) vlog "unknown resolver: $resolver"; return 1 ;;
  esac
}
