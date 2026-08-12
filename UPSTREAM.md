# Upstreams & Provenance

Zero-Termux is a merge of two upstream projects, rebranded and modernized. All upstream attribution and third-party licenses are preserved.

## Upstreams

### Core-Termux
- **Repository:** https://github.com/DevCoreXOfficial/core-termux
- **License:** MIT — Copyright (c) 2026 DevCoreX
- **Contributed:** the `core/` CLI framework (the `core` command, `core/cli/`, `core/commands/`, `core/modules/`, `core/utils/`, `core/tools/` category installers), the unified installer structure, and their documentation.
- **Changes:** rebranded to Zero-Termux, configuration/data paths moved (`~/.local/share/zero-termux*`), URLs updated, tool versions modernized to rolling-latest, CLI help/banner updated, and site anchors re-targeted to the Zero-Termux landing page.

### TermuxVoid
- **Repository:** https://github.com/termuxvoid/repo
- **License:** BSD-3-Clause — Copyright (c) 2025, Termux Void Repo (full text in `LICENSES/BSD-3-Clause.txt`)
- **Contributed:** the `packages/` tree — 228 Debian package definitions and the APT repository build infrastructure (`terminux-apt-repo` recipe in `scripts/build/build-repo.sh`).
- **Changes:** rebranded to Zero-Termux; the `alienkrishn` package became `zero-termux`, the theme package became `zero-termux-theme`; the APT suite is `zero-termux` with a new signing key; many package installers were converted from fixed tool versions to rolling latest.
- **Maintainer attribution:** every package `control` file retains `Maintainer: Alienkrishn [Anon4You]`, the original maintainer. Keep it that way in new packages.

## Third-party projects referenced by packages

The following are genuine third-party projects that Zero-Termux packages install or reference; their URLs are intentionally preserved:

- https://github.com/termuxvoid/AntiSplit — APK splitting tool
- https://github.com/termuxvoid/apkgen-cli — APK generation CLI
- https://github.com/termuxvoid/flutter-termux — Flutter builds for Termux
- https://github.com/termuxvoid/android-sdk-termux — Android SDK for Termux
- https://github.com/termuxvoid/MorphShell — shell framework
- https://github.com/termuxvoid/Void-Fonts — terminal fonts
- https://github.com/termuxvoid/TermuxVoid-Theme — theme variant (`zero-termux-theme` is derived from it)
- https://github.com/DevCoreXOfficial/nvchad-termux — NVChad setup for Termux (referenced by the `editor` module)

Each upstream project's license governs that project; see each project's own repository for license text.

## Rebranding policy

- User-facing strings, docs, URLs, and the site say **Zero-Termux**.
- The `core` command, `core/` directory, and `CORE_*` internal names are retained for compatibility (documented in MIGRATION.md).
- Upstream names appear only where attribution/provenance requires them (this file, licenses, README credits, and third-party URLs listed above).