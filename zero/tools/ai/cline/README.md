# Cline CLI

The open source coding agent in your IDE and terminal.

**Website:** https://cline.bot  
**Repository:** https://github.com/cline/cline  
**License:** Apache-2.0

## Description

Autonomous coding agent as an SDK, IDE extension, or CLI assistant. Run Cline in your terminal. Interactive chat or fully headless for CI/CD and scripting. Terminal UI, headless mode, shell commands, and CLI-specific flows.

## Installation

```bash
zero install ai --cline
```

## Usage

```bash
cline --help
```

## Commands

| Command             | Description                              |
|---------------------|------------------------------------------|
| `zero install ai --cline`   | Install Cline CLI                        |
| `zero uninstall ai --cline` | Uninstall Cline CLI                      |
| `zero update ai --cline`    | Update Cline CLI to latest version       |
| `zero reinstall ai --cline` | Reinstall Cline CLI                      |
| `zero show ai --cline`      | Show this help                           |

## Installation Methods

### glibc + proot (recommended)
Downloads the prebuilt ARM64 binary from npm registry, patches its ELF interpreter to the Termux glibc loader, and runs it under proot with `/lib` and `/bin` bound. The `/bin` bind is required because Cline's `run_commands` hardcodes `spawn('/bin/bash', ['-c', cmd])` and Termux has no `/bin/bash` natively.

### Proot-distro (alternative)
Installs inside an Ubuntu container using proot-distro for maximum compatibility.
