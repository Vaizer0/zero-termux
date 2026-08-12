# PostgreSQL

Advanced open-source relational database

**Package:** postgresql  
**Author:** DevCoreX  
**Repository:** https://github.com/Vaizer0/zero-termux  
**Official:** https://www.postgresql.org  
**Type:** Database (pkg)  
**License:** PostgreSQL License

## Description

PostgreSQL is a powerful, open-source object-relational database system with over 30 years of active development. It has a strong reputation for reliability, feature robustness, and performance. Zero-Termux includes a dedicated manager (`zero pg`) for starting, stopping, and managing PostgreSQL instances.

## Dependencies

- Installed via pkg
- Data directory managed by `zero pg`

## Install

```bash
zero install db --postgresql
```

## Uninstall

```bash
zero uninstall db --postgresql
```

## Update

```bash
zero update db --postgresql
```

## Notes

- Managed via `zero pg` commands (start, stop, restart, status, init, create, drop, list, shell)
- Logs: `~/.cache/zero-termux/postgresql.log`
- Automatic data directory detection
- Support for existing installations

