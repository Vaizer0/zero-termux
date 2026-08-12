#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: validate package metadata and maintainer scripts.
# Fails on: missing control fields, duplicate Package names, non-executable
# maintainer scripts, or bash syntax errors in bash maintainer scripts.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail=0

# Single awk pass over every control file: required fields + duplicates.
awk '
  FNR == 1 {
    if (prev_file != "") check(prev_file)
    prev_file = FILENAME
    delete fields
    pkg_name = ""
  }
  /^[A-Za-z][A-Za-z-]*:/ {
    f = $0
    sub(/:.*$/, "", f)
    fields[f] = 1
    if (f == "Package") { pkg_name = $2; sub(/\r$/, "", pkg_name) }
  }
  END {
    if (prev_file != "") check(prev_file)
    if (fail) exit 1
  }
  function check(base,   arr, i, n) {
    sub(/^packages\//, "", base)
    sub(/\/DEBIAN\/control$/, "", base)
    if (pkg_name == "") { print "VIOLATION: " base ": control missing Package:"; fail = 1 }
    n = split("Package Version Architecture Maintainer Description", arr, " ")
    for (i = 1; i <= n; i++) if (!(arr[i] in fields)) { print "VIOLATION: " base ": control missing " arr[i] ":"; fail = 1 }
    if (pkg_name in seen) { print "VIOLATION: duplicate Package \"" pkg_name "\" (" seen[pkg_name] " and " base ")"; fail = 1 }
    seen[pkg_name] = base
  }
' packages/*/DEBIAN/control
[ $? -ne 0 ] && fail=1

# Maintainer scripts: executable bit + bash syntax
mapfile -t SCRIPTS < <(find packages \( -path '*/DEBIAN/preinst' -o -path '*/DEBIAN/postinst' -o -path '*/DEBIAN/prerm' -o -path '*/DEBIAN/postrm' \) | sort)
for f in "${SCRIPTS[@]}"; do
  if [ ! -x "$f" ]; then
    echo "VIOLATION: $f is not executable"
    fail=1
  fi
  IFS= read -r first < "$f" || true
  case "$first" in
    *bash*)
      bash -n "$f" 2>/dev/null || { echo "VIOLATION: bash -n failed on $f"; fail=1; }
      ;;
  esac
done

echo "Validated $(find packages -mindepth 3 -maxdepth 3 -name control -path '*/DEBIAN/control' | wc -l) packages"
[ "$fail" -eq 0 ] || { echo "Package validation FAILED" >&2; exit 1; }
echo "Package validation OK"
