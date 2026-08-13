# ◈ Zero-Termux

**Your Termux, zero setup friction.**

Zero-Termux is a modular development environment for [Termux](https://termux.dev): a single `zero` CLI — 13 commands — that installs, updates, and removes toolchains, plus a **signed APT repository** of 228 packages served from GitHub Pages. One installer, one ecosystem, no root.

<p align="center">
  <a href="https://github.com/Vaizer0/zero-termux"><img alt="GitHub" src="https://img.shields.io/badge/repo-Vaizer0%2Fzero--termux-1f6feb?style=flat-square&logo=github"></a>
  <img alt="CLI version" src="https://img.shields.io/badge/CLI%20v-1.0.0-1f6feb?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-3fb950?style=flat-square">
  <img alt="Packages" src="https://img.shields.io/badge/packages-228-3fb950?style=flat-square">
  <img alt="Modules" src="https://img.shields.io/badge/tools-99-3fb950?style=flat-square">
  <img alt="APT suite" src="https://img.shields.io/badge/APT%20suite-zero--termux-8957e5?style=flat-square">
  <img alt="Signing key" src="https://img.shields.io/badge/signed-GPG-8957e5?style=flat-square">
  <img alt="Docs" src="https://img.shields.io/badge/docs-vaizer0.github.io%2Fzero--termux-1f6feb?style=flat-square&logo=gitbook">
</p>

---

## Quick navigation

| Area | Link |
|---|---|
| Website & live docs | [vaizer0.github.io/zero-termux](https://vaizer0.github.io/zero-termux) |
| Site search | [search](https://vaizer0.github.io/zero-termux/search/) |
| Command reference | [commands](/docs#commands) • [website](https://vaizer0.github.io/zero-termux/commands/) |
| Modules & tools | [modules](/docs#modules) • [explorer](https://vaizer0.github.io/zero-termux/modules/) |
| APT package catalog | [assets/PACKAGES.md](assets/PACKAGES.md) • [explorer](https://vaizer0.github.io/zero-termux/packages/) |
| Migration from earlier setups | [MIGRATION.md](MIGRATION.md) |
| Guiding documents | [CONTRIBUTING.md](CONTRIBUTING.md) • [SECURITY.md](SECURITY.md) |

---

## What is Zero-Termux?

Two ecosystems, one installer:

- **`zero`** — a modular **bash CLI framework** (zero runtime dependencies) that knows how to install, update, reinstall, and uninstall 99 tools across 9 modules: AI coding agents, language toolchains, databases, editors, dev utilities, npm globals, ZSH shell, Termux UI, and automation.
- **`packages/`** — a **signed APT repository** of **228 Debian packages**, built from source on your device at install time and distributed over GitHub Pages.

> [!NOTE]
> Termux-only. No root, no systemd, no sudo. Everything lives under `$HOME` and `$PREFIX`.

## Why Zero-Termux?

- **One command to rule them all** — `zero install ai --qwen-code` instead of ten different tutorials.
- **Uniform lifecycle** — every tool has the same four verbs: install / update / reinstall / uninstall.
- **Rolling versions, latest tools** — registry installs use `@latest`; GitHub-release binaries resolve the newest release at install time.
- **Signed APT repository** — 228 packages with a GPG-signed `InRelease`, served from the same Pages deploy as the site.
- **Visible code** — every installer and package lifecycle script is plain bash in this repository. Nothing ships as a mystery binary.

## Features

| Feature | Where |
|---|---|
| 99 tools across 9 modules | `zero/tools/<category>/<tool>/` |
| Install / update / reinstall / uninstall for every tool | `zero install|update|reinstall|uninstall <module> [--tool …]` |
| Second brain (save/search memories) | `zero brain` |
| Project scaffolding | `zero init <template>` |
| PostgreSQL manager | `zero pg` |
| Speech-to-agent | `zero voice <agent>` |
| Environment variable manager | `zero env set/unset/ls` |
| 228-package signed APT repo | `pkg install <tool>` |
| Weekly rolling-version drift report | `.github/workflows/maintenance.yml` |
| CI: build, sign, validate, deploy | `.github/workflows/*.yml` |

---

## Quick install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh)
```

The installer does seven things:

1. Verifies and installs dependencies (`tput`, `git`, `glow`, `gh`, `rg`, `jq`, `bat`, `curl`).
2. Creates the Zero-Termux directories.
3. Clones the repository (or updates it on re-runs / detects a dev checkout).
4. Symlinks the `zero` command into `$PREFIX/bin/zero`.
5. Configures the **signed APT repository** (sources list + GPG key) and runs `apt update`.
6. Saves the configuration (`zero_data`, `zero_cache`, `zero_config`, `zero_source`, `zero_tool_data`).
7. Prints a summary with next steps.

### Verify the installation

```bash
zero --version        # → 1.0.0
zero list ai          # shows AI tools and their installed state
zero open zero        # opens the documentation site
```

### First commands

```bash
zero install dev --gh --fzf --jq   # a few day-to-day utilities
zero install ai --qwen-code        # one AI tool (or the whole module: zero install ai)
zero install shell                 # ZSH + Oh My Zsh + prompt + plugins
pkg install zaproxy                # an example APT package
```

### Update / uninstall

```bash
zero update zero        # update the Zero-Termux framework itself (git pull)
zero update ai          # update all installed tools in a module
zero uninstall ai --ollama   # remove a single tool
zero reinstall editor   # uninstall + reinstall a module
pkg remove zaproxy      # remove an APT package
```

---

## Command reference

| Command | Purpose |
|---|---|
| [`zero install`](#install) | Install a module or specific tools |
| [`zero update`](#update) | Update the framework or a module |
| [`zero uninstall`](#uninstall) | Remove a module or specific tools |
| [`zero reinstall`](#reinstall) | Uninstall then reinstall |
| [`zero list`](#list) | List a module's tools |
| [`zero show`](#show) | Show help for one tool |
| [`zero open`](#open) | Open docs in the browser |
| [`zero init`](#init) | Configure an existing project |
| [`zero brain`](#brain) | Second brain (memories) |
| [`zero env`](#env) | Manage env variables |
| [`zero pg`](#pg) | PostgreSQL manager |
| [`zero voice`](#voice) | Speech-to-agent |
| [`zero --version`](#--version) | Show version |

<details>
<summary><b>install</b> — install a module or specific tools</summary>

```
zero install <target> [--tool1 --tool2 …]
```

- `<target>` is a module: `ai`, `lang`, `db`, `editor`, `dev`, `npm`, `shell`, `ui`, `auto`.
- With **no `--tool` flags**, the whole category is installed.
- With flags, only the named tools are installed.

```bash
zero install ai                        # all AI tools (large — can take 1–2 h)
zero install ai --qwen-code --ollama   # just those two
zero install db --postgresql --sqlite
```
</details>

<details>
<summary><b>update</b> — update the framework or a module</summary>

```
zero update <target> [--tool1 --tool2 …]
```

- `zero update zero` updates only the framework (git pull).
- `zero update <module>` runs each tool's update hook; `lang` maps to `pkg upgrade`.

```bash
zero update zero
zero update ai
zero update npm --ncu
```
</details>

<details>
<summary><b>uninstall</b> — remove a module or specific tools</summary>

```
zero uninstall <target> [--tool1 --tool2 …]
```

```bash
zero uninstall npm
zero uninstall ai --ollama
```
</details>

<details>
<summary><b>reinstall</b> — uninstall + install again</summary>

```
zero reinstall <target> [--tool1 --tool2 …]
```

Useful after a broken install.

```bash
zero reinstall editor
```
</details>

<details>
<summary><b>list</b> — list a module's tools</summary>

```
zero list <target>       # bare `zero list` shows the available targets
```

```bash
zero list ai
zero list dev
```
</details>

<details>
<summary><b>show</b> — show help for one tool</summary>

```
zero show <module> --<tool>
```

```bash
zero show ai --opencode
zero show dev --gh
```
</details>

<details>
<summary><b>open</b> — open documentation in the browser</summary>

```
zero open <target>       # zero | help | zero-termux, or a module anchor
```

```bash
zero open          # → https://vaizer0.github.io/zero-termux/
zero open ai       # → …/#ai
```
</details>

<details>
<summary><b>init</b> — configure an existing project</summary>

```
zero init <template>     # run inside the project directory
```

```bash
zero init next
zero init react
```
</details>

<details>
<summary><b>brain</b> — second brain</summary>

```
zero brain <subcommand>   # init | save | search
```

Stores memories locally (optionally backed by a GitHub repo on `init`).

```bash
zero brain init
zero brain save
zero brain search
```
</details>

<details>
<summary><b>env</b> — manage environment variables</summary>

```
zero env set KEY value | zero env unset KEY | zero env ls
```

```bash
zero env set OPENAI_API_KEY sk-…
zero env ls
```
</details>

<details>
<summary><b>pg</b> — PostgreSQL manager</summary>

```
zero pg <command>   # start | stop | restart | …
```

```bash
zero pg start
```
</details>

<details>
<summary><b>voice</b> — speech-to-agent</summary>

```
zero voice [agent]   # opencode (default) | claude-code
```

Captures your voice, lets you review the transcript in nvim, copies it, and launches the agent.

```bash
zero voice
zero voice claude-code
```
</details>

<details>
<summary><b>--version</b> — show version</summary>

```bash
zero --version    # → 1.0.0
```
</details>

---

## Modules and tools

9 modules, **99 tools**. `zero list <module>` shows the live list; the website has a searchable [module explorer](https://vaizer0.github.io/zero-termux/modules/).

| Module | Tools | What it installs |
|---|---:|---|
| [`ai`](https://vaizer0.github.io/zero-termux/#ai) | 36 | Agentic/LLM coding tools: qwen-code, opencode, claude-code, gemini-cli, ollama, … |
| [`lang`](https://vaizer0.github.io/zero-termux/#lang) | 8 | Node.js, Bun, Python, Perl, PHP, Rust, C/C++, Go |
| [`db`](https://vaizer0.github.io/zero-termux/#db) | 5 | PostgreSQL, MariaDB, MongoDB, SQLite, Redis |
| [`editor`](https://vaizer0.github.io/zero-termux/#editor) | 2 | Neovim-based setup (nvchad) |
| [`dev`](https://vaizer0.github.io/zero-termux/#dev) | 22 | gh, fzf, jq, bat, tmux, curl, wget, openssh, … |
| [`npm`](https://vaizer0.github.io/zero-termux/#npm) | 11 | Vercel, live-server, ncu, ngrok, typescript, prettier, … |
| [`shell`](https://vaizer0.github.io/zero-termux/#shell) | 10 | ZSH + Oh My Zsh, powerlevel10k, plugins |
| [`ui`](https://vaizer0.github.io/zero-termux/#ui) | 4 | Fonts, cursor, extra-keys, welcome banner |
| [`auto`](https://vaizer0.github.io/zero-termux/#auto) | 1 | n8n workflow automation |

<details>
<summary><b>ai</b> — AI tools (36)</summary>

Install any with `zero install ai --<tool>`.

`ampcode`, `antigravity-cli`, `cactus`, `cactus-needle`, `claude-code`, `cline`, `codegraph`, `codex`, `command-code`, `ctx7`, `cursor-cli`, `droid-factory`, `engram`, `freebuff`, `gemini-cli`, `gentle-ai`, `gga`, `goose`, `hermes-agent`, `keelcode`, `kilocode-cli`, `kimchi`, `kimi-code`, `mimocode`, `minimax-cli`, `mistral-vibe`, `oh-my-pi`, `ollama`, `openclaude`, `openclaw`, `opencode`, `openspec`, `pi`, `qoder`, `qwen-code`, `supercode`.

Full details: `zero list ai`, `zero show ai --<tool>`.

> [!CAUTION]
> Full-module AI installs are large and slow (1–2 h): install individual tools unless you want everything.
</details>

<details>
<summary><b>lang</b> — language toolchains (8)</summary>

`nodejs`, `bun`, `python`, `perl`, `php`, `rust`, `clang`, `golang`.
</details>

<details>
<summary><b>db</b> — databases (5)</summary>

`postgresql`, `mariadb`, `mongodb`, `sqlite`, `redis`.
</details>

<details>
<summary><b>editor</b> — code editor (2)</summary>

`neovim`, `nvchad`.
</details>

<details>
<summary><b>dev</b> — development utilities (22)</summary>

`bat`, `bc`, `cloudflared`, `curl`, `fzf`, `gh`, `html2text`, `imagemagick`, `jq`, `lsd`, `make`, `ncurses`, `openssh`, `proot`, `shfmt`, `superfile`, `tmate`, `tmux`, `translate`, `tree`, `udocker`, `wget`.
</details>

<details>
<summary><b>npm</b> — Node.js global modules (11)</summary>

`vercel`, `live-server`, `localtunnel`, `markserv`, `ncu`, `nestjs`, `ngrok`, `prettier`, `psqlformat`, `turbopack`, `typescript`.
</details>

<details>
<summary><b>shell</b> — ZSH (10)</summary>

`better-npm`, `fzf-tab`, `history-substring`, `powerlevel10k`, `you-should-use`, `zsh-autopair`, `zsh-autosuggestions`, `zsh-completions`, `zsh-defer`, `zsh-syntax-highlighting`.
</details>

<details>
<summary><b>ui</b> — Termux UI (4)</summary>

`font`, `cursor`, `extra-keys`, `banner`.
</details>

<details>
<summary><b>auto</b> — automation (1)</summary>

`n8n`.
</details>

> Every tool follows the same contract: `install_<tool>` / `update_<tool>` / `reinstall_<tool>` / `uninstall_<tool>` in `zero/tools/<category>/<tool>/install.sh`.

---

## APT repository

**228 packages**, signed, published to GitHub Pages. The installer configures this for you; manual setup:

```bash
echo "deb [trusted=yes arch=all] https://vaizer0.github.io/zero-termux/repo zero-termux main" \
  > "$PREFIX/etc/apt/sources.list.d/zero-termux.list"

curl -fsSL https://vaizer0.github.io/zero-termux/zero-termux.gpg \
  -o "$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg"

apt update
```

| Action | Command |
|---|---|
| Search | `pkg search <name>` |
| Install | `pkg install <name>` |
| Update lists | `apt update` (or `pkg update`) |
| Remove | `pkg remove <name>` |
| Browse catalog | [assets/PACKAGES.md](assets/PACKAGES.md) • [live explorer](https://vaizer0.github.io/zero-termux/packages/) |

### Verify the signing key

```bash
gpg --show-keys "$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg"
# Fingerprint: DF2C 7FCD ABF9 6DF4 298E 953B B0C7 EC7C 1BB9 C494
```

> [!NOTE]
> The source is added with `trusted=yes` because the key is also shipped separately for verification; the repository `InRelease` is signed with the key above on every build.

---

## Version policy

- **Rolling user-facing tools → latest.** Registry installs use `@latest` / `-U`; GitHub-release binaries resolve `…/releases/latest` at install time via the GitHub API (no stale fallback — they fail with a clear error if the API is unreachable).
- **Build-critical / source-tag pins → kept and justified**, each with a `# Zero-Termux: justified pin — <reason>` comment and an entry in the pin manifest.
- **The Debian `Version:` field is the *package* revision** — separate from the installed tool version.
- A weekly maintenance workflow (`maintenance.yml`, Mondays 03:00 UTC) reports drift between justified pins and latest upstream; `test.yml` fails on any new unapproved pin.

---

## Architecture

```mermaid
flowchart LR
    U[User on Termux] -->|bash install.sh| I[Installer]
    I --> C[zero CLI<br/>bash, no runtime deps]
    I --> A[APT repo configured<br/>suite: zero-termux]
    C -->|zero install ai| M[Module installers<br/>zero/tools/&lt;cat&gt;/&lt;tool&gt;/]
    A -->|pkg install| P[Debian packages<br/>packages/&lt;name&gt;/]
    M --> T[Latest tool releases<br/>npm / pip / GitHub API]
    P --> S[Build from source on device]
    CI[GitHub Actions] -->|build-repo.yml| B[dpkg-deb + termux-apt-repo + gpg sign]
    B -->|peaceiris/actions-gh-pages| G[GitHub Pages<br/>site + /repo + key]
    G --> PGP[GPG key<br/>DF2C7FCD…]
```

## Directory layout

```
zero/                          CLI framework (bash, no runtime deps)
  bin/zero                     entry point (resolves symlinks, loads env)
  cli/commands/<cmd>.sh        one file per command (install, list, show, …)
  modules/<cat>.sh             per-category install/update/uninstall logic
  tools/<category>/<tool>/     per-tool installers (+ README.md docs)
  utils/                       bootstrap, env, colors, logging, version helpers
packages/<name>/               Debian package definitions (DEBIAN/control + lifecycle scripts)
scripts/
  build/build-repo.sh          dpkg-deb + termux-apt-repo + gpg signing
  validation/                  CI validators (packages, branding, pins, stale URLs, docs)
  version-check/               rolling-version drift reporter
  maintenance/                 scheduled-checks entrypoint
  site/                        site data generator (scripts/site/generate-data.py)
site/                          website (multi-page, data-driven)
  data/*.json                  generated: meta, commands, modules, packages
assets/                        PACKAGES.md catalog + zero-termux.gpg (public key)
.github/workflows/             CI/CD: build-repo, test, pages, maintenance
install.sh                     unified installer (7 steps)
```

## Common workflows

| Goal | Commands |
|---|---|
| Fresh install | `bash <(curl -fsSL https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh)` |
| Install AI tooling | `zero install ai --qwen-code --ollama` |
| Install dev essentials | `zero install dev --gh --fzf --jq --bat` |
| Everything updated | `zero update zero && zero update ai && pkg upgrade` |
| Recover a broken tool | `zero reinstall <module> --<tool>` |
| APT package | `pkg install <name>` |

## Updating Zero-Termux

- **Framework:** `zero update zero` (or re-run the installer — it detects an existing install and pulls).
- **Modules:** `zero update <module> [--tool …]`.
- **APT:** `apt update && pkg upgrade`.

## Migration

Moving from an earlier single-purpose Termux setup? See [MIGRATION.md](MIGRATION.md) — it documents the layout Zero-Termux uses (`$HOME/.local/share/zero-termux`, `$PREFIX/bin/zero`, config under `~/.config/zero-termux`) and how to keep your existing configs intact.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `curl: command not found` | Install it first: `pkg install curl` |
| `zero: command not found` | `ls -l $PREFIX/bin/zero`; re-run the installer |
| `apt update` fails on our repo | Verify connectivity; the repo is served from GitHub Pages (`vaizer0.github.io`) |
| `zero install ai` is slow | Expected — whole-module AI installs take 1–2 h. Install per-tool instead |
| Tool version looks stale | Rolling tools resolve latest at install time; `zero update <module>` re-resolves |
| GPG verify fails | Re-download the key: `curl -fsSL https://vaizer0.github.io/zero-termux/zero-termux.gpg` |

## Security

- The APT repository is **GPG-signed on every build**; the private key exists **only** in GitHub Actions secrets (`PRIVATE_GPG_KEY`, `GPG_PASSPHRASE`); the public key ships as `assets/zero-termux.gpg` and at `…/zero-termux/zero-termux.gpg`.
- Packages and CLI tools **build/install from source on your device** and may write under `$PREFIX` (bin symlinks, share data) and — for themes/fonts/shell modules — into `$HOME` (e.g. `~/.termux`, `~/.config`). Review the lifecycle scripts before installing anything you do not trust.
- Rolling tools fetch the latest release from the **official upstream** (npm/pip/GitHub) at install time; pinned versions are source-tag builds only, documented in the pin manifest.
- Full model, claims, and responsible-disclosure policy: [SECURITY.md](SECURITY.md).

## Contributing

Packages, module installers, docs, and site content are all welcome. Start at [CONTRIBUTING.md](CONTRIBUTING.md) — it covers the tool contract, version policy, validation suite, local testing, and the PR process.

## License

MIT. See [LICENSE](LICENSE). Tools installed through Zero-Termux are governed by their own licenses.

## Links

- Website: <https://vaizer0.github.io/zero-termux>
- Repository: <https://github.com/Vaizer0/zero-termux>
- Package catalog: [assets/PACKAGES.md](assets/PACKAGES.md)
- Issues: <https://github.com/Vaizer0/zero-termux/issues>