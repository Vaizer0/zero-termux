# Zero-Termux

**Your Termux, zero setup friction.**

Zero-Termux merges two ecosystems into one project:

- **`zero/`** — a modular CLI framework: category-based tool installers with full install/update/reinstall/uninstall lifecycle.
- **`packages/`** — a signed APT repository: **228 Debian packages** served from GitHub Pages.

One installer gives you both. See [MIGRATION.md](MIGRATION.md) for the layout and [LICENSE](LICENSE) for licensing.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh)
```

The installer: verifies dependencies → sets up directories → clones the repo → links the `zero` command → configures the signed APT repository → saves configuration. See [MIGRATION.md](MIGRATION.md) for the layout.

> Works on Termux only. Requires `aarch64`/`arm64` (or amd64/i686) Android; no root, no systemd, no sudo.

## The `zero` CLI

```bash
zero install <category>     # install a whole category (ai, lang, db, editor, dev, npm, shell, ui, auto)
zero install <module>       # e.g. `zero install qwen-code`
zero list                   # list installed tool modules
zero show <module>          # module details
zero open <module>          # open docs/site for a module
zero update                 # pull latest repo + check tool updates
zero uninstall <module>     # remove a tool
zero reinstall <module>     # reinstall a tool
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

Every tool installer follows a uniform contract: `install_<tool>` / `uninstall_<tool>` / `update_<tool>` / `reinstall_<tool>` in `zero/tools/<category>/<tool>/install.sh`.

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
zero/                  CLI framework (bash, no runtime deps)
  bin/zero             entry point
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

- Maintainer: **Vaizer0**
- Third-party tools installed by these packages retain their own licenses.

## License

MIT. See [LICENSE](LICENSE).