# Migrating to Zero-Termux

Zero-Termux is the successor project that merges its upstream CLI framework and package repository under one name. This page documents the current layout — no legacy migration is required, since Zero-Termux has always installed into its own `zero-termux` paths.

## What the installer creates

| Item | Path / value |
|---|---|
| Repository clone | `~/.local/share/zero-termux` |
| Tool data | `~/.local/share/zero-termux-data` |
| Cache | `~/.cache/zero-termux` |
| Config | `~/.config/zero-termux` |
| CLI command | `zero` (`$PREFIX/bin/zero` → `zero-termux/zero/bin/zero`) |
| APT source | `$PREFIX/etc/apt/sources.list.d/zero-termux.list` |
| Signing key | `$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg` |

## The `zero` command

`zero` is the CLI entry point. The repository tree mirrors its structure:

```
zero/
  bin/zero           entry point (symlinked as $PREFIX/bin/zero)
  cli/               command implementations
  modules/           shared logic
  tools/<cat>/<tool>/  per-tool installers
```

Usage:

```bash
zero install <category>    # e.g. zero install ai
zero install <module>      # e.g. zero install ai --opencode
zero list                  # list tools per category
zero show <module>         # module details
zero open <module>         # open docs/site
zero update                # pull latest repo + check tool updates
zero uninstall <module>
zero reinstall <module>
```

## The APT repository

Zero-Termux adds its own signed repository:

```
deb [trusted=yes arch=all] https://vaizer0.github.io/zero-termux/repo zero-termux main
```

with the signing key at `$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg`. Zero-Termux only manages its own files; any third-party sources are not touched.

## Reinstalling / switching

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh)
zero --version        # confirm the command resolves
ls ~/.local/share/zero-termux
```

No cleanup of past upstream installs is needed for new users; if you previously experimented with the upstream project, reinstalling with this installer places everything under the `zero-termux` paths above.