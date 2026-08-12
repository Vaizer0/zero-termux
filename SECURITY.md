# Security Policy

Zero-Termux provides two things: a modular CLI ecosystem (`zero`) that installs development tools on your device, and a signed APT repository of packages built from source. This policy states what each actually does, what we guarantee, and how to report problems.

**Model in one sentence: transparency, not trust.** You execute installer and package scripts on your own device. All of them are plain bash in this repository (`zero/tools/…`, `packages/…/DEBIAN/`); nothing ships as a mystery binary. Review before you install, especially anything you did not expect to run build steps.

---

## What runs on your device

### The `zero` CLI and its tools

- `zero install <module> [--tool …]` runs that module's installers. AI installs are intentionally large (1–2 h for a whole module) and install from **official registries (npm/pip/gem/cargo/go) or the tool's official GitHub releases** — never from Zero-Termux's own infrastructure.
- Tool installers may install into `$PREFIX` (bin symlinks, data under `$PREFIX/share`) and some modules (shell, ui) write user-level config under `$HOME` (e.g. `~/.zshrc` additions, `~/.termux`, `~/.config`). Read the tool's installer before running it if you care about what touches your config.
- `zero update <module>` re-resolves the latest version of your installed tools; `zero update zero` pulls this repository.
- `zero voice` records microphone audio for transcription — it runs only when you invoke it.

### APT packages

- Each package's `postinst` runs at install time on your device: it downloads the tool's source/release **from the tool's own official repository**, builds it, and links the resulting command into `$PREFIX/bin`. A package therefore executes third-party build tooling on your device; this is the intended design (Termux packages traditionally do the same).
- Packages may write data under `$PREFIX/share` or `$PREFIX/lib`; a minority (themes, fonts, shell/CLI config packs) intentionally write into `$HOME` areas such as `~/.termux` or `~/.config`, and a few install scripts reference `$PATH` or shell profiles. This is visible in the package's `DEBIAN/` scripts — check them before installing a package you do not trust.
- `postrm` removes what `postinst` created. Packages expose commands via symlinks rather than by mutating your environment.

---

## APT repository signing

- Every `build-repo` run builds the packages, runs `termux-apt-repo`, and GPG-signs the `Release` file (→ signed `InRelease`).
- The signing key: ed25519, `Zero-Termux Signing <zero-termux@users.noreply.github.com>`, fingerprint `DF2C7FCDABF96DF4298E953BB0C7EC7C1BB9C494`.
- The **public** key ships in the repository (`assets/zero-termux.gpg`) and is published at `https://vaizer0.github.io/zero-termux/zero-termux.gpg`.
- The **private** key exists only inside GitHub Actions secrets (`PRIVATE_GPG_KEY` + `GPG_PASSPHRASE`). It has never been committed and never will be; treat any other source of the private key as compromised.

## Supply chain

- Rolling tools resolve the **latest release from the official upstream** (registry or GitHub API) at install time. There is no pinned-by-default behavior and no silent fallback — installers fail with a clear error if the upstream API is unreachable.
- Pins are limited to build-critical/source-tag cases and are individually justified: each carries a `# Zero-Termux: justified pin — <reason>` comment plus a manifest entry, and the pin-logic regression check in CI fails on any new unapproved pin.
- All downloads use HTTPS and point at each tool's official source — never at this project's servers.
- CI validates every PR: shell syntax, package metadata, branding, pinned-version policy, and stale URLs. The Pages deployment serves the signed repository and the public key from the same pipeline that built them.

## What we do NOT claim

- We do **not** claim packages are "automatically safe just because they are in the repo." Installing a package executes its `postinst` on your device.
- We do **not** claim every tool avoids touching your config: theme/font/shell modules and a handful of packages intentionally do.
- Zero-Termux packages are for properly authorized use only. Offensive/security tools in the catalog must only be used against systems you own or are explicitly permitted to test.

## Responsible disclosure

- **Do not** open a public issue for an active vulnerability that puts other users at risk (for example, a malicious third-party URL or a key-handling flaw).
- **Do not** run security tooling from this catalog against systems you do not own or lack written permission to test. Misuse is entirely the user's responsibility.
- For everything else — a bug, a risky package behavior, a stale URL, a questionable installer — a normal issue is fine and welcome.

## Report a vulnerability

Open a [GitHub issue](https://github.com/Vaizer0/zero-termux/issues) prefixed `[SECURITY]`, or for sensitive reports use the maintainer contact listed on the repository.

Please include:

1. Package or tool name and installed version (e.g. `pkg show <name>` / `zero show <module> --<tool>`).
2. Exact reproduction steps (commands run, environment).
3. What the impact would be if exploited.
4. (Optional) a proposed fix.

We acknowledge reports within **3 business days** and aim for a fix or a documented mitigation within 14 days.

---

## Hardening tips for users

- Keep Termux itself updated: `pkg upgrade`.
- Review what you install: `less zero/tools/<cat>/<tool>/install.sh` and `less packages/<name>/DEBIAN/postinst`.
- Pin your own tool versions when a workflow depends on stability: `zero update` re-resolves latest, so re-run installers only when you intend to move forward.
- Verify the APT key fingerprint above (DF2C 7FCD ABF9 6DF4 298E 953B B0C7 EC7C 1BB9 C494) when you install the key manually.