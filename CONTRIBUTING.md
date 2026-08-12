# Contributing to Zero-Termux

Thank you for your interest in contributing. Zero-Termux merges two ecosystems:
- **`core/`** — the modular CLI framework: module installers under `core/tools/<category>/<tool>/install.sh` with the `install_/uninstall_/update_/reinstall_<tool>` contract.
- **`packages/`** — the APT repository: Debian package dirs under `packages/<name>/` with `DEBIAN/control` and lifecycle scripts.

PRs may be closed without review if they break the rules below.

## Prerequisites

1. **Debian package layout.** Each package in `packages/<name>/` is an unpacked Debian package directory. It must contain a `DEBIAN/` directory with a `control` file and lifecycle scripts (`preinst`, `postinst`, `postrm`). See the [Debian Policy](https://www.debian.org/doc/debian-policy/) if needed.
2. **Termux paths and environment.** These are used throughout the scripts:
   - `$PREFIX` → `/data/data/com.termux/files/usr` — root of the installed environment
   - `$HOME` → `/data/data/com.termux/files/home` — user home
   - `$TMPDIR` → where temporary files go; use it for scratch files
   - `$PREFIX/bin` → where user commands live
   - `$PREFIX/share/<pkg>` → where a package's data lives
   - Scripts use the Termux shebang: `#!/data/data/com.termux/files/usr/bin/bash`

## Package structure

```
packages/<name>/
└── DEBIAN/
    ├── control     # metadata
    ├── preinst     # pre-install checks (optional)
    ├── postinst    # build/install/link (required)
    └── postrm      # uninstall cleanup (required)
```

### control

Required fields:

`Package`, `Version`, `Architecture` (use `all`), `Maintainer`, `Depends`, `Section`, `Priority`, `Homepage`, `Description`. List every runtime dependency under `Depends`; apt installs them for you.

Keep the `Maintainer: Alienkrishn [Anon4You]` field untouched — it records provenance of the original TermuxVoid packages.

### preinst

Runs before the package is unpacked. Use it for cheap guard checks (e.g. architecture). Keep it minimal or omit it.

### postinst

Runs after installation. This is where the real work happens: download, build, install, link. **Rules to follow:**

- **Keep it simple.** One job: install the tool and expose it on `$PATH`.
- **Never** modify `$PATH`, `$HOME`, `$PREFIX`, or any other environment variable.
- **Never** touch the user's existing Termux config or dotfiles.
- Expose commands via **symlinks into `$PREFIX/bin`**. Prefer a `ln -s` over a wrapper script.
- Its final job is to verify the command exists; `exit 1` on any failure.
- **Never pin rolling tool versions** — see the version policy below.

### postrm

Runs on uninstall. Remove whatever `postinst` created — nothing more, nothing in the user's own files. If the tool was installed without a version pin, uninstall all versions (e.g. `gem uninstall <gem> -a -x --force`).

## Version policy (rolling vs pinned)

- **Rolling user-facing tools → latest.** Registry installs use `@latest` / `-U` / no `-v`; GitHub-release binaries resolve the latest release at install time via `api.github.com/repos/<owner>/<repo>/releases/latest` (never a stale fallback — fail with a clear error if the API is unreachable).
- **Build-critical / source-tag pins → keep**, with a `# Zero-Termux: justified pin — <reason>` comment directly above the pin.
- The Debian control `Version:` is the *package* revision and is separate from the installed tool version.
- New justified pins must be added to the manifest in `scripts/validation/version-pin-check.sh`; the pin regression CI fails otherwise.

## Test before submitting

Install, run, and remove the package on a Termux device (real Termux or emulator). At minimum:

```bash
pkg update
dpkg-deb -b packages/<name>
pkg install ./<name>_<version>_all.deb

# 1. Command is on PATH and runs
tool --version

# 2. Nothing env-related was modified
echo "$PATH"      # unchanged after install

# 3. Uninstall leaves no trace
pkg remove <name>
test ! -e "$PREFIX/bin/tool"
```

## CI checks

The `test` workflow runs on every PR. Keep it green:

- `bash -n` on all shell scripts
- `scripts/validation/validate-packages.sh` — control fields, duplicate names, executable maintainer scripts
- `scripts/validation/branding-check.sh` — no upstream-brand regression (allowlist covers provenance + third-party deps)
- `scripts/validation/version-pin-check.sh` — no unapproved pins
- `scripts/validation/stale-url-check.sh` — no dead upstream URLs

## PR checklist

- [ ] Correct Debian layout (`packages/<name>/DEBIAN/control` plus scripts).
- [ ] All runtime dependencies declared under `Depends`.
- [ ] `postinst` keeps to one job, uses symlinks, and does **not** change any environment variable or path.
- [ ] Rolling tools unpinned; any justified pin has its comment and manifest entry.
- [ ] `postrm` removes only what the package created.
- [ ] Installed, ran, and uninstalled successfully during testing.
- [ ] Added to `assets/PACKAGES.md` under the correct category.

If unsure about any step, ask before opening the PR rather than guessing.
