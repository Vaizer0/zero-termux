# Command Code

The coding agent that learns your coding taste.

**Package:** command-code  
**Author:** DevCoreX  
**Repository:** https://github.com/Vaizer0/zero-termux  
**Official:** https://github.com/CommandCodeAI/command-code
**Type:** AI coding assistant (npm local package with wrapper)  
**License:** MIT

## Description

The first frontier coding agent that both builds software and continuously learns your coding taste. Ships full-stack projects, features, fixes bugs, writes tests, and refactors, all while learning how you write code.

## Why Local Install?

On Termux, the global `npm install -g command-code` creates a binary named `cmd` which conflicts with the existing Termux `cmd` binary. Zero-Termux solves this by:

1. Installing `command-code` locally in `~/.local/share/zero-termux-data/command-code/`
2. Creating a wrapper script at `$PREFIX/bin/command-code`
3. Adding an alias `cmdc` via symlink

## Dependencies

- Node.js LTS (nodejs-lts)
- npm
- git
- ripgrep

## Install

```bash
zero install ai --command-code
```

## Uninstall

```bash
zero uninstall ai --command-code
```

## Update

```bash
zero update ai --command-code
```

## Commands

| Command | Description |
|---------|-------------|
| `command-code` | Run Command Code |
| `cmdc` | Alias for command-code |

## Notes

- Installed as a local npm package (avoids `cmd` binary conflict)
- Wrapper script created at `$PREFIX/bin/command-code`
- Alias `cmdc` created via symlink
- Data directory: `~/.local/share/zero-termux-data/command-code/`
- Requires Node.js LTS (installed automatically if missing)
