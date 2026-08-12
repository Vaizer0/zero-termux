# Contributing to Zero-Termux

Thank you for contributing. Zero-Termux is two ecosystems in one repository:

- **`zero/`** — a modular **bash CLI framework** whose per-tool installers install, update, reinstall, and uninstall tools on a Termux device.
- **`packages/`** — a **signed APT repository** of Debian package definitions built from source on the device.

Everything is plain bash, shell scripts, Markdown, and a bit of JSON — no build toolchain required to contribute.

> [!IMPORTANT]
> **Termux-only project.** Scripts use the Termux shebang `#!/data/data/com.termux/files/usr/bin/bash`, paths like `$PREFIX` (`/data/data/com.termux/files/usr`), `$HOME`, and `$TMPDIR`, and never assume root, systemd, or `sudo`.

---

## Repository layout

```
zero/
  bin/zero                    CLI entry point (symlink-resolving, loads env)
  cli/commands/<cmd>.sh       one file per command; exports <cmd>_main
  modules/<cat>.sh            per-category install/update/uninstall/reinstall logic
  tools/<category>/<tool>/    per-tool installer (install.sh) + README.md
  utils/                      bootstrap (import), env (ZERO_* vars), colors, log, version
packages/<name>/              Debian package definitions
scripts/
  build/build-repo.sh         dpkg-deb + termux-apt-repo + GPG signing (+ perms guard)
  validation/                 CI validators (see "Validation")
  version-check/              rolling-version drift reporter
  maintenance/                scheduled-checks entrypoint
  site/generate-data.py       regenerates site/data/*.json (also .sh wrapper)
site/                         website (see "Website changes")
assets/                       PACKAGES.md catalog + zero-termux.gpg (public key)
.github/workflows/            build-repo.yml, test.yml, pages.yml, maintenance.yml
install.sh                    unified 7-step installer
```

## Development environment

- A Termux installation (aarch64/arm64 preferred; amd64/i686 also supported).
- `git`, `bash` (Termux's), `python3` (only for the site-data generator), `gh` (optional, for PRs).
- To test installer scripts without touching your main setup, override the target prefix:

  ```bash
  PREFIX="$HOME/zt-test/prefix" \
  XDG_DATA_HOME="$HOME/zt-test/data" \
  XDG_CONFIG_HOME="$HOME/zt-test/config" \
  XDG_CACHE_HOME="$HOME/zt-test/cache" \
  bash install.sh -s
  ```

  The installer creates `$PREFIX/bin/zero` itself, so an empty prefix works.

---

## The tool contract

Every tool lives in `zero/tools/<category>/<tool>/` with:

```
zero/tools/<cat>/<tool>/
├── install.sh    # the whole lifecycle for this tool
└── README.md     # what/why/how — becomes the tool's documentation
```

`install.sh` exports four functions with the exact names `install_<tool>`, `update_<tool>`, `reinstall_<tool>`, `uninstall_<tool>`, and a `_<tool>_dependencies` helper:

```bash
#!/data/data/com.termux/files/usr/bin/bash
import "@/utils/log"
import "@/utils/version"

_qwen_code_dependencies() { … }        # apt/pip/npm deps, installed first

install_qwen_code() { … }              # install + verify the binary runs
update_qwen_code()  { … }              # re-resolve latest and update
reinstall_qwen_code() { uninstall_qwen_code && install_qwen_code; }
uninstall_qwen_code() { … }            # clean removal
```

Rules:

- **Install = verify.** The installer's final step confirms the command exists; fail loudly (`return 1` / `exit 1`) otherwise.
- **Update = re-resolve latest.** Rolling tools must not be pinned (see Version policy).
- **Uninstall removes only what the tool created.**
- Modules are dispatchers: a tool is reachable through `zero install <cat> --<tool>` only if the category module (`zero/modules/<cat>.sh`) or the category's `all.sh` maps the name to `install_<tool>`.
- Keep scripts spawn-minimal: validate inputs in bash, avoid launching a process per check.

## Adding a tool: step by step

1. `mkdir zero/tools/<cat>/<tool>/` and write `install.sh` implementing the four functions.
2. Wire it into the category dispatch (`zero/modules/<cat>.sh`, or `zero/tools/<cat>/all.sh` if the category uses one).
3. Write `README.md` — one paragraph on what it is, the install command, and any prerequisites.
4. Test: `zero install <cat> --<tool>`, `zero show <cat> --<tool>`, `zero update <cat> --<tool>`, `zero reinstall <cat> --<tool>`, `zero uninstall <cat> --<tool>`.
5. Regenerate site data: `python3 scripts/site/generate-data.py` (updates `site/data/modules.json`).
6. Run the validation suite below.

---

## Version policy (rolling, with justified pins)

- **Rolling user-facing tools → latest.** Registry installs use `@latest` / `-U` / bare `pip install`; GitHub-release binaries resolve the newest release at install time via `api.github.com/repos/<owner>/<repo>/releases/latest` and **fail with a clear error if the API is unreachable** (no stale fallback).
- **Build-critical / source-tag pins → kept, justified.** A pin is only legitimate when the tool must be built from a specific source tag (or the build genuinely needs a fixed version). Mark it with a comment directly above the pin:

  ```bash
  # Zero-Termux: justified pin — hermes-agent control=pkg version, script
  # resolves binary release independently (rolling).
  ```

- **Register new justified pins.** Add the pin to the manifest in `scripts/validation/version-pin-check.sh` (and, for machine-resolvable ones, to `scripts/version-check/check-rolling-versions.sh`). `test.yml` fails on any unapproved pin.
- **The Debian `Version:` field is the *package* revision**, independent of the installed tool's version.

---

## Package development

Each package is an unpacked Debian directory:

```
packages/<name>/
└── DEBIAN/
    ├── control     # metadata
    ├── preinst     # optional cheap pre-flight checks
    ├── postinst    # build/install/link (the real work)
    └── postrm      # uninstall cleanup
```

### control

Required fields: `Package`, `Version`, `Architecture` (`all`), `Maintainer`, `Depends`, `Section`, `Priority`, `Homepage`, `Description`. Keep `Maintainer: Vaizer0`. List every runtime dependency under `Depends`.

### postinst

- **One job:** build the tool from source and expose it on `$PATH` (prefer a **symlink into `$PREFIX/bin`** over a wrapper).
- Do not modify environment variables. You *may* install data under `$PREFIX/share/<pkg>` or `$PREFIX/lib/<pkg>`; tools whose nature requires it (themes, fonts, shell configs) may write into `$HOME` areas such as `~/.termux` or `~/.config` — document that in the Description, and make `postrm` remove exactly what `postinst` created.
- Final step verifies the command works; `exit 1` otherwise.
- Keep the GitHub API-based "latest release" pattern for binaries; no stale fallbacks.

### postrm

Remove what `postinst` created — nothing more, nothing from the user's own files beyond what the package itself added. Registry installs uninstall all versions (e.g. `gem uninstall <tool> -a -x --force`).

### Adding a package: step by step

1. `mkdir -p packages/<name>/DEBIAN` and create `control` + `postinst` (+ `postrm`).
2. Build and install locally: `dpkg-deb -b packages/<name>` then `pkg install ./<name>_<ver>_all.deb`.
3. Verify: command on `$PATH` and runs; `$PATH` unchanged; `pkg remove` leaves no trace.
4. Add the package to `assets/PACKAGES.md` under the right category.
5. Regenerate site data: `python3 scripts/site/generate-data.py` (updates `site/data/packages.json`).

> [!NOTE]
> Repo perms: keep `DEBIAN/` dirs and maintainer scripts executable (`chmod 755`). `scripts/build/build-repo.sh` normalizes only the DEBIAN dirs — never blanket-`chmod 644` a package tree (it destroys data-file exec bits).

---

## Validation

| Check | Script | Fails on |
|---|---|---|
| Packages | `scripts/validation/validate-packages.sh` | missing control fields, duplicate names, non-executable scripts, `bash -n` errors |
| Branding | `scripts/validation/branding-check.sh` | old-brand references outside the allowlist |
| Version pins | `scripts/validation/version-pin-check.sh` | version pins without a justified manifest entry |
| Stale URLs | `scripts/validation/stale-url-check.sh` | dead upstream URLs (old site, telegram, old GPG path) |
| Docs/site | `scripts/validation/doc-links-check.sh` | broken internal links, stale counts, non-project URLs in docs, wrong install URL |

Run everything locally before pushing:

```bash
bash -n install.sh
find zero scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
for s in scripts/validation/*.sh; do bash "$s"; done
python3 scripts/site/generate-data.py
```

If you changed the APT side, also run a full local build:

```bash
bash scripts/build/build-repo.sh zero-termux main   # needs gpg + termux-apt-repo
```

---

## CI/CD

| Workflow | Triggers | Does |
|---|---|---|
| `test` | push (main, `feature/**`), PR | `bash -n` everywhere, all validation scripts, landing-page checks |
| `build-repo` | push main, dispatch | builds + signs 228 packages, assembles `_site` (site + repo + key), deploys to `gh-pages` |
| `pages` | push main (site/**), dispatch | deploys site + key only, `keep_files: true` preserves `/repo` |
| `maintenance` | weekly cron (Mon 03:00 UTC), dispatch | runs scheduled checks + rolling-version drift report |

Both Pages workflows share the `zero-termux-pages` concurrency group so site and repo deploys never collide. The private signing key lives **only** in repository secrets (`PRIVATE_GPG_KEY`, `GPG_PASSPHRASE`); never commit key material — the public key in `assets/zero-termux.gpg` is the only key file in the repo.

## Pull requests

1. Branch from `main`: `git checkout -b <scope>/<summary> main`.
2. Make focused commits (one logical change each), e.g. `feat(tools): add <tool>`, `docs: regenerate site data`.
3. Keep `main` pristine; feature work lives on clearly named branches.
4. Registry/run the checks above; resolve failures **in the same PR**.
5. Title the PR with the change type; reference the tool/package names involved.
6. Do not weaken validation to get CI green — fix the root cause.

## Documentation and website changes

- **README / CONTRIBUTING / SECURITY / guides:** prose changes are welcome; every claim about a command, tool, or package must match the code (the code wins on conflict).
- **Site data is generated, not hand-edited.** `site/data/*.json` comes from `scripts/site/generate-data.py`:
  - commands ← `zero/cli/commands/*.sh` (static table, verified against the dispatch)
  - modules ← `zero/tools/*/`
  - packages ← `packages/*/DEBIAN/control` + category mapping from `assets/PACKAGES.md`
  - After adding/removing a tool or package, regenerate: `python3 scripts/site/generate-data.py` and commit the JSON.
- **Site pages** live in `site/` (shared `assets/styles.css` + `assets/app.js`, data-driven explorers). Content-based pages (guides, architecture, security) may mirror the Markdown docs — keep them consistent with the repo docs.
- Documentation may only reference this project's own URLs — `https://github.com/Vaizer0/zero-termux` and `https://vaizer0.github.io/zero-termux` — plus each tool's genuine third-party homepages. Do not reference other account paths in project docs (the branding check enforces this).

## Security considerations

- This project installs third-party tools **on the user's device**, many of which run build steps at install time. Never hide what a script does; prefer transparent, readable installers.
- Downloads and clones must point at each tool's **official source repository**, never at this project's infrastructure.
- Handle secrets in CI via GitHub secrets; never commit keys, tokens, or passphrases.
- Report vulnerabilities privately per [SECURITY.md](SECURITY.md) — do not open a public issue for an active vulnerability.

## Commit expectations

- Message style: `type(scope): summary` where type ∈ `feat | fix | docs | ci | test | chore | refactor`.
- Body states *why*, not just *what*.
- Do not commit build artifacts (`debs/`, `repo/`, `_site/`) or private key material — they are gitignored.
- Regenerated `site/data/*.json` changes belong in the same commit as the source change that caused them.