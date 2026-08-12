# Zero-Termux

**Your Termux, zero setup friction.**

Zero-Termux merges two ecosystems into one project:

- **`core/`** — a modular CLI framework (upstream: Core-Termux): category-based tool installers with full install/update/reinstall/uninstall lifecycle.
- **`packages/`** — a signed APT repository (upstream: TermuxVoid): **228 Debian packages** served from GitHub Pages.

One installer gives you both. See [UPSTREAM.md](UPSTREAM.md) for provenance and licenses.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh)
```

The installer: verifies dependencies → sets up directories (with one-time migration from legacy Core-Termux installs, see [MIGRATION.md](MIGRATION.md)) → clones the repo → links the `core` command → configures the signed APT repository → saves configuration.

> Works on Termux only. Requires `aarch64`/`arm64` (or amd64/i686) Android; no root, no systemd, no sudo.

## The `core` CLI

```bash
core install <category>     # install a whole category (ai, lang, db, editor, dev, npm, shell, ui, auto)
core install <module>       # e.g. `core install qwen-code`
core list                   # list installed tool modules
core show <module>          # module details
core open <module>          # open docs/site for a module
core update                 # pull latest repo + check tool updates
core uninstall <module>     # remove a tool
core reinstall <module>     # reinstall a tool
```

Categories:

| Category | Tools | What it installs |
|---|---|---|
| `ai` | 37 | qwen-code, opencode, claude-code, gemini-cli, ollama, … |
| `lang` | 9 | Go, Rust, Node, Python toolchains |
| `db` | 6 | PostgreSQL, MariaDB, Redis, MongoDB, SQLite |
| `editor` | 3 | Neovim-based setups (nvchad, lazyvim, …) |
| `dev` | 23 | bat, curl, cloudflared, everyday dev utilities |
| `npm` | 12 | Node CLI tools (turbopack, 9router, …) |
| `shell` | 11 | ZSH + plugins and prompt |
| `ui` | 5 | Termux UI tooling, themes, widgets |
| `auto` | 2 | n8n workflow automation |

Every tool installer follows a uniform contract: `install_<tool>` / `uninstall_<tool>` / `update_<tool>` / `reinstall_<tool>` in `core/tools/<category>/<tool>/install.sh`.

## The APT repository

228 packages, signed, served from GitHub Pages. Already configured by the installer. Manually:

```bash
echo "deb [trusted=yes arch=all] https://vaizer0.github.io/zero-termux/repo zero-termux main" \
  > $PREFIX/etc/apt/sources.list.d/zero-termux.list
curl -fsSL https://vaizer0.github.io/zero-termux/zero-termux.gpg \
  -o $PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg
apt update

pkg search zaproxy
pkg install zaproxy
```

The full catalog is in [assets/PACKAGES.md](assets/PACKAGES.md).

## Version policy

- **Rolling tools → latest.** Registry installs use `@latest`; GitHub-release binaries resolve the newest release at install time via the GitHub API.
- **Build-critical / source-tag pins → kept and justified**, each with a `# Zero-Termux: justified pin — <reason>` comment.
- The Debian `Version:` field is the *package* revision, separate from the installed tool version.

A weekly maintenance workflow reports drift between pinned and latest upstream versions; the test workflow fails on new unapproved pins.

## Repository layout

```
core/                  CLI framework (bash, no runtime deps)
  bin/core             entry point
  cli/                 command implementations
  modules/             shared logic (AI, shell, env)
  tools/<cat>/<tool>/  per-tool installers
packages/<name>/       Debian package definitions (DEBIAN/control + lifecycle scripts)
scripts/
  build/build-repo.sh            dpkg-deb + termux-apt-repo + GPG signing
  validation/                    CI validation (packages, branding, pins, stale URLs)
  version-check/                 rolling-version drift reporter
  maintenance/                   scheduled checks entrypoint
site/                  landing page (deployed to GitHub Pages)
assets/                PACKAGES.md catalog, zero-termux.gpg (public key)
.github/workflows/     CI/CD (build-repo, test, pages, maintenance)
install.sh             unified installer
```

## CI/CD

| Workflow | Triggers | Does |
|---|---|---|
| `test` | push (main + feature/**), PR | `bash -n` everywhere + 4 validation checks + landing-page checks |
| `build-repo` | push main, dispatch | builds + signs 228 packages, deploys Pages (site + repo) |
| `pages` | push main (site/**), dispatch | deploys site only, preserving `/repo` |
| `maintenance` | weekly cron, dispatch | runs scheduled checks + version drift report |

## Security

- The APT repository is signed; the private key exists **only** in GitHub Actions secrets.
- Packages never modify `$PATH`/`$HOME`/`$PREFIX`, never touch your config, and uninstall cleanly (they use symlinks into `$PREFIX/bin`).
- See [SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

- **Core-Termux** (MIT, © 2026 DevCoreX) — CLI framework: https://github.com/DevCoreXOfficial/core-termux
- **TermuxVoid** (BSD-3-Clause, © 2025 Termux Void Repo) — packages: https://github.com/termuxvoid/repo
- package maintainer: **Alienkrishn [Anon4You]**
- third-party tool projects retain their own licenses — full list in [UPSTREAM.md](UPSTREAM.md)

## License

MIT (CLI framework + Zero-Termux contributions) + BSD-3-Clause (packages, upstream TermuxVoid). See [LICENSE](LICENSE) and [LICENSES/BSD-3-Clause.txt](LICENSES/BSD-3-Clause.txt).