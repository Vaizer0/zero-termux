# Migrating to Zero-Termux

Zero-Termux supersedes the upstream Core-Termux layout. This page covers what changed and how existing installs migrate.

## What changed

| Old (Core-Termux / TermuxVoid) | New (Zero-Termux) |
|---|---|
| `~/.local/share/core-termux` (repo) | `~/.local/share/zero-termux` |
| `~/.local/share/core-termux-data` (tool data) | `~/.local/share/zero-termux-data` |
| `~/.cache/core-termux` | `~/.cache/zero-termux` |
| `~/.config/core-termux` | `~/.config/zero-termux` |
| APT suite `termuxvoid` | APT suite `zero-termux` |
| GPG key `termuxvoid.gpg` | GPG key `zero-termux.gpg` |
| Symlink `$PREFIX/bin/core` → old repo | `$PREFIX/bin/core` → `~/.local/share/zero-termux/core/bin/core` |

## The `core` command doesn't change

The CLI entry point is still the `core` command, and the `core/` tree retains its internal names. `core open <module>`, `core install <category>`, and the tool installers work exactly as before — they just resolve to the zero-termux paths above.

## Automatic migration

The new installer performs a **one-time migration** (step 2) if it detects legacy directories:

1. If `~/.local/share/zero-termux` does not exist but `~/.local/share/core-termux` does, the old repo directory is moved to the new path.
2. The same move applies to the data, cache, and config directories, if present.
3. Only then does the installer clone the new repository (skipped when the target already exists) and re-link `core`.

Already-installed tools and modules keep their data — the move preserves the directories in place. The legacy path is only migrated once; after that, installs are purely Zero-Termux.

## The APT repository

TermuxVoid's own `termuxvoid.list` source is **not touched** by the migration (it is third-party config). Zero-Termux adds its own source:

```
deb [trusted=yes arch=all] https://vaizer0.github.io/zero-termux/repo zero-termux main
```

with the signing key at `$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg`.

To switch repositories explicitly (optional):

```bash
pkg remove alienkrishn termuxvoid-theme   # old packages, if installed
rm $PREFIX/etc/apt/sources.list.d/termuxvoid.list  # only if you want to drop the old source
pkg update
pkg install zero-termux zero-termux-theme # new counterparts, if desired
```

(For a fresh install none of this is needed — the installer does it all.)

## Uninstalling legacy installs

```bash
core --help                 # confirm it points at zero-termux
ls ~/.local/share/zero-termux
pkg list-installed | grep -i termux
```

If you previously installed via the old Core-Termux installer and the migration step ran, you are done: nothing else to clean up.