#!/data/data/com.termux/files/usr/bin/bash
# Zero-Termux: build and sign the APT repository.
# Mirrors .github/workflows/build-repo.yml for local runs.
# Requires: dpkg-deb, gpg (with signing key imported), termux-apt-repo (pip3 install termux-apt-repo).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

SUITE="${1:-zero-termux}"
COMPONENT="${2:-main}"
DEBS_DIR="debs"
REPO_DIR="repo"

for tool in dpkg-deb gpg termux-apt-repo; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found" >&2; exit 1; }
done

mkdir -p "$DEBS_DIR" "$REPO_DIR"

# Normalize permissions: dpkg-deb rejects control dirs with 0700 perms
# (Termux copies may retain restrictive umasks). Only touch what dpkg-deb
# requires — never flatten data-file modes (keep exec bits as committed).
find packages -name DEBIAN -type d -exec chmod 755 {} +
chmod 755 packages/*/DEBIAN/preinst packages/*/DEBIAN/postinst packages/*/DEBIAN/postrm 2>/dev/null || true

count=0
for pkg_dir in packages/*/; do
  if [ -f "${pkg_dir}DEBIAN/control" ]; then
    echo "Building ${pkg_dir}"
    dpkg-deb -b -Zxz "${pkg_dir}" "$DEBS_DIR/"
    count=$((count + 1))
  fi
done
echo "Built $count packages"

# Remove stale debs for deleted packages
for deb in "$DEBS_DIR"/*.deb; do
  [ -e "$deb" ] || continue
  pkg_name=$(basename "$deb" | sed 's/_.*//')
  if [ ! -d "packages/${pkg_name}" ]; then
    echo "Removing stale deb: ${deb}"
    rm -f "$deb"
  fi
done
echo "Final debs: $(ls "$DEBS_DIR"/*.deb 2>/dev/null | wc -l)"

if ! gpg --list-secret-keys >/dev/null 2>&1; then
  echo "error: no secret GPG key imported; run the CI workflow or import a signing key" >&2
  exit 1
fi

termux-apt-repo "$DEBS_DIR" "$REPO_DIR" "$SUITE" "$COMPONENT" -s

gpg --verify "$REPO_DIR/dists/$SUITE/InRelease"
echo "Repository ready: $REPO_DIR (suite $SUITE/$COMPONENT)"
