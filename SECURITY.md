# Security Policy

Zero-Termux maintains an APT repository of ~228 packages plus a modular CLI tool ecosystem. This policy covers both.

## Transparency, Not Trust

Every package is built from source at install time on your device, from pinned or latest upstream tags, and its install/uninstall behavior is visible in `packages/<name>/DEBIAN/`. Nothing is hidden.

## What Zero-Termux Packages **Never** Do

- No package modifies `$PATH`, `$HOME`, `$PREFIX`, or any Termux env var.
- No package touches your existing Termux config.
- We use **symlinks** instead of env mutations — uninstall leaves zero trace.

## Security Properties

- **APT signing.** The repository is signed with a dedicated Zero-Termux GPG key. Releases ship the public key as `assets/zero-termux.gpg`; the private key lives only in GitHub Actions secrets (`PRIVATE_GPG_KEY`, `GPG_PASSPHRASE`) and is never committed.
- **Supply chain.** Rolling tools resolve latest versions from the official registry (npm/pip/gem/cargo/go) or the upstream project's GitHub release at install time. Pinned versions are limited to source-tag builds and are documented with justification comments.
- **Upstream provenance.** Package maintainer attribution and third-party repository URLs are preserved; see `UPSTREAM.md`.

## Responsible Disclosure

- **Do not** open a public issue for an active vulnerability.
- **Do not** test against systems you do not own or lack written permission to test. These tools are for educational and authorized security research only; misuse is your own responsibility.

## Report a Vulnerability

Open a [GitHub Issue](https://github.com/Vaizer0/zero-termux/issues) with the prefix `[SECURITY]`, or for sensitive reports email the maintainer contact listed on the repository. Include:

- Package/tool name and installed version
- Reproduction steps
- Impact assessment

We aim to acknowledge reports within 3 business days.
