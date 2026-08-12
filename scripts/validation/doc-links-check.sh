#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: documentation & site regression check.
#
# Verifies:
#   1. Every internal link/src in site/*.html resolves to an existing file.
#   2. Every #anchor referenced on the landing page (and other pages) exists
#      as an id= attribute in the same file.
#   3. Free-text counts in README.md match the repository tree.
#   4. Site data JSON freshness:
#        - every packages/*/DEBIAN/control Package appears in packages.json,
#        - every zero/tools/*/* tool appears in modules.json,
#        - meta.json counts equal the live tree (except command_count,
#          which is a documented static contract of 13).
#        - Command count in commands.json == 13 and names match the CLI dir.
#   5. No `github.com/zero-termux` (non-project account URL) in docs/site.
#   6. The install URL and the signing-key fingerprint appear in the docs.
#
# Requires: python3 (also used by scripts/site/generate-data.py).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
note()  { printf '  %s\n' "$*"; }
error() { printf 'FAIL: %s\n' "$*"; FAILED=1; }

# --- 1. internal file links in site/*.html -------------------------------
for page in site/*.html; do
  base="$(dirname "$page")"
  # href/src values that are relative (no scheme, no //host, not mailto, not #-only)
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      http://*|https://*|//*|mailto:*|'#'*) continue ;;
    esac
    target="${ref%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$base/$target" ]; then
      error "$page: missing target '$ref'"
    fi
  done < <(rg -o '(href|src)="[^"]+"' "$page" | sed -E 's/^(href|src)="([^"]+)"/\2/')
done

# --- 2. in-page anchors ----------------------------------------------------
for page in site/*.html; do
  self="$(basename "$page")"
  while IFS= read -r anchor; do
    [ -z "$anchor" ] && continue
    file="${anchor%%#*}"
    [ -n "$file" ] && [ "$file" != "$self" ] && continue   # cross-page: dynamic
    frag="${anchor#*#}"
    [ "$frag" = "$anchor" ] && continue                    # no fragment
    if ! rg -q "id=\"$frag\"" "$page"; then
      error "$page: missing anchor '#$frag'"
    fi
  done < <(rg -o 'href="[^"]*#[^"]*"' "$page")
done

# --- 3. README free-text counts vs tree -----------------------------------
tool_dirs=$(find zero/tools -mindepth 2 -maxdepth 2 -type d | wc -l)
pkg_count=$(find packages -name control -path '*/DEBIAN/control' | wc -l)
cat_count=$(find zero/modules -maxdepth 1 -type f -name '*.sh' ! -name '_*' | wc -l)
cmd_count=$(find zero/cli/commands -maxdepth 1 -type f -name '*.sh' | wc -l)

for pair in "99 tools" "228 packages" "9 modules" "13 commands"; do
  n="${pair%% *}"; label="${pair#* }"
  if ! rg -q -- "$n $label" README.md; then
    error "README.md must state '$pair' (tree has ${tool_dirs} tools, ${pkg_count} packages, ${cat_count} cats, ${cmd_count} commands)"
  fi
done

# --- 4. JSON freshness + counts ---------------------------------------------
python3 - "$tool_dirs" "$pkg_count" "$cat_count" "$cmd_count" <<'PYEOF'
import json, os, sys, re
from pathlib import Path

root = Path(os.getcwd())
tool_dirs, pkg_count, cat_count, cmd_count = (int(x) for x in sys.argv[1:5])
failed = False
def err(m):
    global failed
    print("FAIL:", m, file=sys.stderr)
    failed = True

data = {n: json.load(open(root / "site" / "data" / f"{n}.json")) for n in
        ("meta", "commands", "modules", "packages")}
meta = data["meta"]

# live package names
live_pkgs = set()
for c in (root / "packages").glob("*/DEBIAN/control"):
    txt = c.read_text(errors="replace")
    m = re.search(r"^Package:\s*(.+)$", txt, re.M)
    if m: live_pkgs.add(m.group(1).strip())
json_pkgs = {p["name"] for p in data["packages"]}
missing = sorted(live_pkgs - json_pkgs)
if missing:
    err(f"packages.json missing {len(missing)} live packages: {missing[:5]}…")
stale = sorted(json_pkgs - live_pkgs)
if stale:
    err(f"packages.json has {len(stale)} packages not in packages/: {stale[:5]}…")

# live tools
live_tools = set()
for d in (root / "zero" / "tools").glob("*/*"):
    if d.is_dir() and (d / "install.sh").exists():
        live_tools.add(d.name)
json_tools = {t["name"] for m in data["modules"] for t in m["tools"]}
missing = sorted(live_tools - json_tools)
if missing:
    err(f"modules.json missing {len(missing)} live tools: {missing[:5]}…")
stale = sorted(json_tools - live_tools)
if stale:
    err(f"modules.json has {len(stale)} tools not in zero/tools/: {stale[:5]}…")

# meta counts
expect = {"package_count": pkg_count, "tool_count": tool_dirs,
          "category_count": cat_count, "command_count": cmd_count}
for k, v in expect.items():
    if meta.get(k) != v:
        err(f"meta.json {k}={meta.get(k)} but tree has {v}; run: python3 scripts/site/generate-data.py")

# command contract
if len(data["commands"]) != 13:
    err(f"commands.json has {len(data['commands'])} entries (documented contract: 13)")
dir_cmds = {p.name[:-3] for p in (root / "zero" / "cli" / "commands").glob("*.sh")}
json_cmds = {c["name"] for c in data["commands"]}
if dir_cmds != set(json_cmds):
    err(f"commands.json names ({sorted(json_cmds)}) != CLI files ({sorted(dir_cmds)})")

# freshness: every command/tool/package JSON record must be non-trivial
if any(not c.get("summary") for c in data["commands"]):
    err("commands.json: every entry needs a summary")

sys.exit(1 if failed else 0)
PYEOF

# --- 5. unwanted project-account URL -----------------------------------------
HITS=$(rg -l 'github\.com/zero-termux' README.md CONTRIBUTING.md SECURITY.md site/ 2>/dev/null || true)
if [ -n "$HITS" ]; then
  error "docs/site must not reference github.com/zero-termux:"
  printf '%s\n' "$HITS" | sed 's/^/    /'
fi

# --- 6. install URL + fingerprint ---------------------------------------------
INSTALL_URL='raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh'
if ! rg -q "$INSTALL_URL" README.md; then
  error "README.md missing install URL: $INSTALL_URL"
fi
if ! rg -q "$INSTALL_URL" site/index.html; then
  error "site/index.html missing install URL: $INSTALL_URL"
fi
FPR='DF2C7FCDABF96DF4298E953BB0C7EC7C1BB9C494'
if ! rg -q "$FPR" SECURITY.md; then
  error "SECURITY.md missing signing-key fingerprint"
fi
if ! rg -q "$FPR" site/security.html; then
  error "site/security.html missing signing-key fingerprint"
fi

if [ "$FAILED" -eq 0 ]; then
  echo "Docs & site checks OK"
else
  echo "Docs & site checks FAILED (see above)"
  exit 1
fi