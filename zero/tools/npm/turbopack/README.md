# Turbopack Toolchain for Termux

Run Next.js with Turbopack on Termux (Android aarch64).

## Install

```bash
zero install npm --turbopack
```

Installs:
- **Node.js** linux-arm64 (glibc) — v22.14.0
- **node-glibc** — run any script with the glibc Node
- **next-turbopack** — Next.js dev/build with Turbopack

## Usage

```bash
cd my-next-app
next-turbopack dev     # Start dev server with Turbopack
next-turbopack build   # Production build with Turbopack
```

## How it works

Official Node.js linux-arm64 binaries are compiled against glibc. Android/Termux
uses bionic libc. The toolchain:
1. Downloads Node.js linux-arm64 official binary
2. Strips debug symbols (prevents patchelf from corrupting large ELFs)
3. Patches the ELF interpreter to use Termux's glibc loader
4. Installs CLI wrappers that resolve missing native bindings (SWC,
   lightningcss, etc.) for the linux-arm64 platform

## Init a new project

```bash
zero init next
```

Adds `pnpm.supportedArchitectures` for multi-platform native bindings, installs
common dependencies, and sets up a modular folder structure.

## Uninstall

```bash
zero uninstall npm --turbopack
```
