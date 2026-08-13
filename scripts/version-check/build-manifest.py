#!/data/data/com.termux/files/usr/bin/python
"""Zero-Termux: build the central package version manifest.

Reads:
  - scripts/version-check/packages.tsv   (curated: name | resolver | upstream | mechanism)
  - packages/*/DEBIAN/control            (Debian Version: for seeding)

Writes:
  - scripts/version-check/package-manifest.json  (policy/resolver/upstream per package)
  - scripts/version-check/versions.json          (recorded upstream versions for tracked packages)

Classification rules:
  - resolver in {github-release,github-tag,npm,pypi,gem,cargo,go}  -> policy=rolling, tracked
  - resolver == github-clone                                       -> policy=rolling-build (git HEAD)
  - resolver == none, mechanism in {rolling-download,passive}      -> policy=pinned (documented)
  - resolver == none, mechanism == static-data                     -> policy=static (bundled payload)
  - explicit overrides (CURATED) below take precedence.

Run: python3 scripts/version-check/build-manifest.py
"""

import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
TSV = os.path.join(ROOT, "scripts", "version-check", "packages.tsv")
OUT_MANIFEST = os.path.join(ROOT, "scripts", "version-check", "package-manifest.json")
OUT_VERSIONS = os.path.join(ROOT, "scripts", "version-check", "versions.json")
TODAY = "2026-08-13"

# Curated overrides: name -> partial manifest fields (deep-merged).
# These encode decisions that cannot be inferred from the resolver alone.
CURATED = {
    # PortSwigger / rootfs / equinox sources have no machine-readable latest
    # endpoint: version is bumped manually. Documented justified pins.
    "burpsuite":       {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "2026.1.2", "reason": "PortSwigger has no machine-readable latest endpoint; updated manually."}},
    "burpsuite-pro":   {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "2026.1.5", "reason": "PortSwigger has no machine-readable latest endpoint; updated manually."}},
    "andrax":          {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "5-2", "reason": "GitLab rootfs build tag; no stable API to auto-resolve."}},
    "nethunter-cli":   {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "2025.4", "reason": "kali.download current rootfs; version rolled manually."}},
    "ngrok":           {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "3.39.1", "reason": "bin.equinox.io stable channel; no public version API."}},
    "setoolkit":       {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "8.0.3+git20241021-0kali1", "reason": "Installed via nh apt from NetHunter repo."}},
    "theharvester":    {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "4.10.1", "reason": "Installed via nh apt from NetHunter repo."}},
    # Static data payloads whose bundled script carries its own VERSION banner
    # (display only, not an upstream dependency).
    "fuckyou":         {"policy": "static", "resolver": None, "upstream": None},
    "infect":          {"policy": "static", "resolver": None, "upstream": None},
    "shellcrypt":      {"policy": "static", "resolver": None, "upstream": None},
    "enctool":         {"policy": "static", "resolver": None, "upstream": None},
    "the-theif":       {"policy": "static", "resolver": None, "upstream": None},
    # Reproducible pinned Python deps (spider report).
    "spider":          {"policy": "pinned", "resolver": None, "upstream": None,
                        "pin": {"version": "2.0", "reason": "requirements.txt pinned for reproducible report tooling."}},
    # Static scripts with third-party runtime deps installed by the postinst.
    "webhost":         {"policy": "static", "resolver": None, "upstream": None, "tracked": False},
    "pip-basic-depends": {"policy": "static", "resolver": None, "upstream": None},
    "termux-ai":       {"policy": "static", "resolver": None, "upstream": None},
    # wordlists: pulls a static release asset (rockyou.txt); no version to track.
    "wordlists":       {"policy": "static", "resolver": None, "upstream": None, "tracked": False},
    # OpenCode: glibc build for aarch64 from GitHub releases (upstream npm
    # package is opencode-ai; the Debian wrapper ships the glibc binary).
    "opencode":        {"policy": "rolling", "resolver": "github-release",
                        "upstream": "anomalyco/opencode", "arch": "aarch64",
                        "install": "github releases (glibc binary wrapper)"},
    # Packages whose github-tag postinst was previously hardcoded; the
    # installer now resolves dynamically (rolling, tracked).
    "bettercap":       {"policy": "rolling", "tracked": True},
    "dalfox":          {"policy": "rolling", "tracked": True},
    "gowitness":       {"policy": "rolling", "tracked": True},
    "gitleaks":        {"policy": "rolling", "tracked": True},
    "ffuf":            {"policy": "rolling", "tracked": True},
    "fscan":           {"policy": "rolling", "tracked": True},
    "trufflehog":      {"policy": "rolling", "tracked": True},
    "metabigor":       {"policy": "rolling", "tracked": True},
    "openbullet2":     {"policy": "rolling", "tracked": True},
    "jsql":            {"policy": "rolling", "tracked": True},
    "hashcat":         {"policy": "rolling", "tracked": True},
    "beef":            {"policy": "rolling", "tracked": True},
    "hermes-agent":    {"policy": "rolling", "tracked": True},
    # Metasploit tracks a rolling dev line (6.4.x-dev) and the repo's git tags
    # are not ordered by version/date (tags API is reverse-alphabetical and
    # shows only 4.x-era tags). Cannot be auto-resolved safely.
    "metasploit-framework": {"policy": "pinned", "resolver": None, "upstream": None, "tracked": False,
                             "pin": {"version": "6.4.142-dev",
                                     "reason": "Upstream tags are not version-ordered (only 4.x-era git tags); follows a rolling 6.4.x-dev line. Bumped manually."}},
}

ROLLING_RESOLVERS = {"github-release", "github-tag", "npm", "pypi", "gem", "cargo", "go"}


def load_tsv():
    rows = {}
    for line in open(TSV, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 4:
            continue
        name, resolver, upstream, mechanism = (parts + [""] * 4)[:4]
        resolver = resolver.strip()
        upstream = upstream.strip()
        rows[name] = {"resolver": None if resolver in ("", "none") else resolver,
                      "upstream": None if upstream in ("", "none") else upstream,
                      "mechanism": mechanism.strip()}
    return rows


def control_version(name):
    ctrl = os.path.join(ROOT, "packages", name, "DEBIAN", "control")
    try:
        for line in open(ctrl, encoding="utf-8", errors="replace"):
            if line.startswith("Version:"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return ""


def debian_upstream_part(version):
    """Return the part before the Debian revision (last hyphen)."""
    return version.split("-")[0] if "-" in version else version


def main():
    rows = load_tsv()
    if not rows:
        print("error: no rows loaded from", TSV, file=sys.stderr)
        return 1

    manifest = {"schema": "zero-termux-package-manifest/1",
                "generated": TODAY,
                "packages": {}}
    versions = {"schema": "zero-termux-recorded-versions/1",
                "generated": TODAY,
                "packages": {}}

    for name in sorted(rows):
        r = rows[name]
        resolver = r["resolver"]
        upstream = r["upstream"]
        mechanism = r["mechanism"]
        ctrl_ver = control_version(name)

        entry = {"policy": None, "resolver": resolver, "upstream": upstream,
                 "tracked": False, "arch": None, "install": "", "pin": None}

        if resolver in ROLLING_RESOLVERS:
            entry["policy"] = "rolling"
            entry["tracked"] = True
        elif resolver == "github-clone":
            entry["policy"] = "rolling-build"
        elif resolver is None:
            if mechanism == "static-data":
                entry["policy"] = "static"
            elif mechanism in ("rolling-download", "passive"):
                entry["policy"] = "pinned"
                if not entry.get("pin"):
                    entry["pin"] = {"version": ctrl_ver or None,
                                    "reason": "Non-resolvable source; version updated manually."}
            else:
                entry["policy"] = "static"

        # apply curated overrides
        if name in CURATED:
            for k, v in CURATED[name].items():
                entry[k] = v

        # install description
        if entry["policy"] == "rolling":
            entry["install"] = f"{resolver} latest ({upstream})"
        elif entry["policy"] == "rolling-build":
            entry["install"] = f"git clone {upstream} + build (HEAD)"
        elif entry["policy"] == "static":
            entry["install"] = "bundled data payload"
        elif entry["policy"] == "pinned":
            entry["install"] = "pinned (see pin.reason)"

        manifest["packages"][name] = entry

        # seed recorded versions for tracked rolling packages from control
        if entry["policy"] == "rolling" and entry["tracked"] and resolver in ROLLING_RESOLVERS and upstream:
            versions["packages"][name] = {
                "upstream": debian_upstream_part(ctrl_ver) if ctrl_ver else None,
                "resolver": resolver,
                "source": upstream,
            }

    os.makedirs(os.path.dirname(OUT_MANIFEST), exist_ok=True)
    with open(OUT_MANIFEST, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    with open(OUT_VERSIONS, "w", encoding="utf-8") as fh:
        json.dump(versions, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    from collections import Counter
    pol = Counter(v["policy"] for v in manifest["packages"].values())
    print(f"Wrote package-manifest.json: {len(manifest['packages'])} packages")
    print("  policies:", dict(pol))
    print(f"Wrote versions.json: {len(versions['packages'])} tracked rolling packages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
