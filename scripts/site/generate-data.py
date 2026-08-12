#!/data/data/com.termux/files/usr/bin/python
"""Zero-Termux: generate site/data/*.json from the repository.

Single source of truth for the website's command reference, module/tool
explorer, and package explorer. Regenerate after any change to:

  - zero/cli/commands/*.sh      (add/remove a command  -> commands.json)
  - zero/tools/<cat>/<tool>/    (add/remove a tool     -> modules.json)
  - packages/<name>/DEBIAN/control  (add/remove a pkg  -> packages.json)
  - assets/PACKAGES.md          (category assignment   -> packages.json)

Run:  python3 scripts/site/generate-data.py   (or `bash scripts/site/generate-data.sh`)
Output: site/data/{meta,commands,modules,packages}.json
"""

import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SITE_DATA = os.path.join(ROOT, "site", "data")

REPO = "https://github.com/Vaizer0/zero-termux"
SITE = "https://vaizer0.github.io/zero-termux"
INSTALL_URL = "https://raw.githubusercontent.com/Vaizer0/zero-termux/main/install.sh"
APT_SUITE = "zero-termux"
APT_URL = "https://vaizer0.github.io/zero-termux/repo"


def load_controls():
    """Parse every packages/<name>/DEBIAN/control into {name: fields}."""
    pkgs = {}
    for control in sorted(glob_dir("packages/*/DEBIAN/control")):
        pkg = {}
        desc_lines = []
        for line in open(control, encoding="utf-8", errors="replace"):
            if line.startswith(" ") or line.startswith("\t"):
                if "Description" in pkg and desc_lines:
                    desc_lines.append(line.strip())
                continue
            if ":" in line:
                key, _, val = line.partition(":")
                key = key.strip()
                val = val.strip()
                if key == "Description":
                    desc_lines = [val] if val else []
                else:
                    pkg[key] = val
        name = pkg.get("Package", os.path.basename(os.path.dirname(os.path.dirname(control))))
        pkg["name"] = name
        pkg["description"] = " ".join(d for d in desc_lines if d).strip()
        pkgs[name] = pkg
    return pkgs


def load_categories():
    """Map package name -> category from assets/PACKAGES.md section tables."""
    cats = {}
    current = "Miscellaneous"
    try:
        for line in open(os.path.join(ROOT, "assets", "PACKAGES.md"), encoding="utf-8", errors="replace"):
            m = re.match(r"^###\s+(.+)$", line.strip())
            if m:
                current = m.group(1).strip()
                continue
            m = re.match(r"^\|\s*\[([^\]]+)\]\([^)]+\)\s*\|", line.strip())
            if m:
                cats[m.group(1).strip()] = current
    except OSError:
        pass
    return cats


def glob_dir(pattern):
    import glob
    return sorted(glob.glob(os.path.join(ROOT, pattern)))


def blurb(tool_md):
    """First meaningful sentence of a tool README, as a short blurb."""
    try:
        for line in open(tool_md, encoding="utf-8", errors="replace"):
            s = line.strip()
            if not s or s.startswith("#") or s.startswith("<!--"):
                continue
            s = re.sub(r"[`*_#\[\]<>]", "", s)
            s = re.sub(r"\s+", " ", s)
            return s[:160] + ("…" if len(s) > 160 else "")
    except OSError:
        pass
    return ""


CATEGORY_INFO = [
    ("ai", "AI tools", "Agentic and LLM coding tools: opencode, qwen-code, claude-code, gemini-cli, ollama, and more."),
    ("lang", "Language toolchains", "Node.js, Bun, Python, Perl, PHP, Rust, C/C++, Go."),
    ("db", "Databases", "PostgreSQL, MariaDB, MongoDB, SQLite, Redis."),
    ("editor", "Code editor", "Neovim-based setups (nvchad) with plugins."),
    ("dev", "Development utilities", "Everyday CLI tools: gh, fzf, jq, bat, tmux, curl, wget, and more."),
    ("npm", "Node.js global modules", "Vercel, live-server, ncu, ngrok, typescript, prettier, and more."),
    ("shell", "ZSH shell", "ZSH + Oh My Zsh, powerlevel10k, and plugins."),
    ("ui", "Termux UI", "Fonts, cursor, extra keys, welcome banner."),
    ("auto", "Automation", "n8n workflow automation."),
]


def build_modules():
    cats = []
    for cat, title, desc in CATEGORY_INFO:
        tools = []
        tool_dir = os.path.join(ROOT, "zero", "tools", cat)
        if not os.path.isdir(tool_dir):
            continue
        for name in sorted(os.listdir(tool_dir)):
            d = os.path.join(tool_dir, name)
            if not os.path.isdir(d):
                continue
            tools.append({
                "name": name,
                "category": cat,
                "blurb": blurb(os.path.join(d, "README.md")) or "See installer for details.",
                "docs": f"{REPO}/tree/main/zero/tools/{cat}/{name}",
                "install": f"zero install {cat} --{name}",
            })
        cats.append({
            "name": cat,
            "title": title,
            "description": desc,
            "tools": tools,
            "count": len(tools),
            "install": f"zero install {cat}",
        })
    return cats


COMMANDS = [
    {
        "name": "--version",
        "summary": "Show the installed Zero-Termux version.",
        "syntax": "zero --version",
        "args": [],
        "examples": ["zero --version"],
        "notes": "Prints the framework version (ZERO_VERSION).",
    },
    {
        "name": "install",
        "summary": "Install a module (whole category) or specific tools.",
        "syntax": "zero install <target> [--tool1 --tool2 …]",
        "args": [("target", "module: ai, lang, db, editor, dev, npm, shell, ui, auto"),
                ("--tool", "one or more tools of that module, e.g. --qwen-code --ollama")],
        "examples": ["zero install ai", "zero install ai --qwen-code --ollama", "zero install db --postgresql"],
        "notes": "With no --tool flags, the whole category is installed. AI installs are large and slow (1–2 h).",
    },
    {
        "name": "update",
        "summary": "Update the framework or installed modules/tools.",
        "syntax": "zero update <target> [--tool1 --tool2 …]",
        "args": [("target", "module, or `zero` to update only the framework (git pull)")],
        "examples": ["zero update zero", "zero update ai", "zero update npm --ncu"],
        "notes": "Lang updates map to `pkg upgrade`; other modules update their tools' per-tool update hooks.",
    },
    {
        "name": "uninstall",
        "summary": "Remove a module or specific tools.",
        "syntax": "zero uninstall <target> [--tool1 --tool2 …]",
        "args": [("target", "module to remove")],
        "examples": ["zero uninstall npm", "zero uninstall ai --ollama"],
        "notes": "Runs each tool's uninstall hook.",
    },
    {
        "name": "reinstall",
        "summary": "Uninstall then reinstall a module or tools.",
        "syntax": "zero reinstall <target> [--tool1 --tool2 …]",
        "args": [("target", "module to reinstall")],
        "examples": ["zero reinstall editor"],
        "notes": "Useful for recovering a broken tool installation.",
    },
    {
        "name": "list",
        "summary": "List the tools available in a module.",
        "syntax": "zero list <target>",
        "args": [("target", "module to list (bare `zero list` shows targets)")],
        "examples": ["zero list ai", "zero list dev"],
        "notes": "Shows each tool with its installed state where detectable.",
    },
    {
        "name": "show",
        "summary": "Show help/documentation for a specific tool.",
        "syntax": "zero show <module> --<tool>",
        "args": [("module", "module of the tool"), ("--tool", "tool name")],
        "examples": ["zero show ai --opencode", "zero show dev --gh"],
        "notes": "",
    },
    {
        "name": "open",
        "summary": "Open Zero-Termux documentation in the browser.",
        "syntax": "zero open <target>",
        "args": [("target", "site anchor: zero, help, zero-termux, or a module (ai, lang, …)")],
        "examples": ["zero open", "zero open ai"],
        "notes": "Opens the GitHub Pages site; module targets anchor to the homepage sections.",
    },
    {
        "name": "init",
        "summary": "Configure an existing project.",
        "syntax": "zero init <template>",
        "args": [("template", "project template, e.g. next, react")],
        "examples": ["zero init next"],
        "notes": "Run inside the project directory.",
    },
    {
        "name": "brain",
        "summary": "Second brain — save, search, and manage memories.",
        "syntax": "zero brain <subcommand>",
        "args": [("subcommand", "init, save, search (and dashboard views)")],
        "examples": ["zero brain init", "zero brain save", "zero brain search"],
        "notes": "Stores memories locally (and optionally a GitHub repo on init).",
    },
    {
        "name": "env",
        "summary": "Manage user-scoped environment variables.",
        "syntax": "zero env <set|unset|ls> [-key value]",
        "args": [("subcommand", "set, unset, ls")],
        "examples": ["zero env set KEY value", "zero env unset KEY", "zero env ls"],
        "notes": "Variables are stored per-user and loaded into the shell session.",
    },
    {
        "name": "pg",
        "summary": "PostgreSQL database manager.",
        "syntax": "zero pg <command>",
        "args": [("command", "start, stop, restart (and related server commands)")],
        "examples": ["zero pg start"],
        "notes": "Manages the local Termux PostgreSQL instance.",
    },
    {
        "name": "voice",
        "summary": "Speech-to-agent — record voice, review in nvim, send to an AI agent.",
        "syntax": "zero voice [agent]",
        "args": [("agent", "opencode | claude-code (default opencode)")],
        "examples": ["zero voice", "zero voice claude-code"],
        "notes": "Requires a microphone and a terminal audio solution on Termux.",
    },
]


def main():
    pkgs = load_controls()
    cats = load_categories()
    packages = []
    for name in sorted(pkgs):
        p = pkgs[name]
        packages.append({
            "name": name,
            "version": p.get("Version", ""),
            "description": p.get("description", ""),
            "homepage": p.get("Homepage", REPO),
            "category": cats.get(name, "Miscellaneous"),
            "install": f"pkg install {name}",
        })

    modules = build_modules()
    tool_count = sum(c["count"] for c in modules)
    meta = {
        "version": "1.0.0",
        "repo": REPO,
        "site": SITE,
        "install_url": INSTALL_URL,
        "apt_suite": APT_SUITE,
        "apt_url": APT_URL,
        "package_count": len(packages),
        "tool_count": tool_count,
        "category_count": len(modules),
        "command_count": len(COMMANDS),
    }

    os.makedirs(SITE_DATA, exist_ok=True)
    for fname, obj in (
        ("meta.json", meta),
        ("commands.json", COMMANDS),
        ("modules.json", modules),
        ("packages.json", packages),
    ):
        with open(os.path.join(SITE_DATA, fname), "w", encoding="utf-8") as fh:
            json.dump(obj, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
    print(f"Wrote site/data/*.json: {len(packages)} packages, {tool_count} tools/"
          f"{len(modules)} categories, {len(COMMANDS)} commands")
    return 0


if __name__ == "__main__":
    sys.exit(main())