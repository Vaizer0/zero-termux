#!/data/data/com.termux/files/usr/bin/python
"""Zero-Termux: generate site/data/*.json from the repository.

Single source of truth for the website's command reference, module/tool
explorer, and package explorer. Regenerate after any change to:

  - zero/cli/commands/*.sh      (add/remove a command  -> commands.json)
  - zero/tools/<cat>/<tool>/    (add/remove a tool     -> modules.json)
  - packages/<name>/DEBIAN/control  (add/remove a pkg  -> packages.json)
  - assets/PACKAGES.md          (category assignment   -> packages.json)

Run:  python3 scripts/site/generate-data.py   (or `bash scripts/site/generate-data.sh`)
Output: site/data/{meta,commands,modules,packages,search}.json
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
        "args": [("target", "`zero`, `help` or `zero-termux` for the site; a module name (ai, lang, db, editor, dev, npm, shell, ui, auto) to anchor to its section")],
        "examples": ["zero open", "zero open ai", "zero open zero-termux"],
        "notes": "With no target it prints help. Requires Termux:API (`termux-open-url`); module targets open the homepage section, e.g. https://vaizer0.github.io/zero-termux/#ai.",
    },
    {
        "name": "init",
        "summary": "Configure an existing project with a scaffold.",
        "syntax": "zero init [template]",
        "args": [("template", "next | react | nest | express (run with no template to auto-detect from package.json)")],
        "examples": ["zero init next", "zero init react", "zero init nest", "zero init express"],
        "notes": "Run inside a project that already has package.json. Adds optional dependencies, folder structure, Prettier, and .env.example interactively; detects the package manager from lockfiles.",
    },
    {
        "name": "brain",
        "summary": "Second brain — save, search, link, and sync memories.",
        "syntax": "zero brain <subcommand> [args]",
        "args": [("subcommand", "init, save, search [query], ls/list [category], edit [slug], delete/rm, reset/destroy, relate, show/view <slug>, graph/map, skill/skills, sync")],
        "examples": ["zero brain init", "zero brain save", "zero brain search react", "zero brain ls dev", "zero brain graph", "zero brain sync"],
        "notes": "Memories are markdown files with tags, category, and relations. init optionally creates a private GitHub repo (zero-termux-brain) for sync.",
    },
    {
        "name": "env",
        "summary": "Manage user-scoped environment variables.",
        "syntax": "zero env <set|unset|ls>",
        "args": [("subcommand", "set (interactive), unset (interactive), ls | list")],
        "examples": ["zero env set", "zero env unset", "zero env ls", "zero env list"],
        "notes": "set and unset prompt for input interactively — they take no arguments. Variables are written as `export KEY=value` lines to ~/.zshrc (or ~/.bashrc if zsh is absent); source the rc file to apply.",
    },
    {
        "name": "pg",
        "summary": "PostgreSQL database manager.",
        "syntax": "zero pg <command> [db-name]",
        "args": [("command", "init, start, stop, restart, status, create <db>, drop <db>, list | ls, shell | psql")],
        "examples": ["zero pg init", "zero pg start", "zero pg status", "zero pg create mydb", "zero pg shell"],
        "notes": "Requires PostgreSQL (`zero install db --postgresql`). Manages the local Termux instance on localhost:5432.",
    },
    {
        "name": "voice",
        "summary": "Speech-to-agent — record voice, review in nvim, send to an AI agent.",
        "syntax": "zero voice <agent>",
        "args": [("agent", "opencode, qoder, claude-code, codex, gemini-cli, hermes-agent, kilocode-cli, kimi-code, mimocode, mistral-vibe, openclaude, pi, qwen-code, or text/`!` to print the prompt")],
        "examples": ["zero voice opencode", "zero voice qoder", "zero voice claude-code", "zero voice text"],
        "notes": "An agent argument is required — bare `zero voice` prints help. Requires Termux:API (pkg termux-api + app) and neovim (`zero install editor`). Captures speech, lets you fix the text in nvim, copies it to the clipboard, and runs the agent.",
    },
]


def strip_tags(s):
    return re.sub(r"<[^>]+>", "", s).replace("&amp;", "&").replace("&#39;", "'").strip()


def build_search(packages, modules, commands):
    """Site-wide search index (site/data/search.json) consumed by search.html."""
    index = []

    for c in commands:
        index.append({
            "kind": "command",
            "title": "zero " + c["name"],
            "url": "commands.html",
            "text": c["summary"],
            "command": "zero " + c["name"],
            "keywords": "command " + c["name"],
        })

    for m in modules:
        index.append({
            "kind": "module",
            "title": f"{m['name']} — {m['title']}",
            "url": f"modules.html#{m['name']}",
            "text": m["description"],
            "command": f"zero install {m['name']}",
            "keywords": "module category " + m["name"],
        })
        for t in m["tools"]:
            index.append({
                "kind": "tool",
                "title": t["name"],
                "url": f"modules.html#{m['name']}",
                "category": m["name"],
                "text": t["blurb"],
                "command": f"zero install {m['name']} --{t['name']}",
                "keywords": "tool module " + m["name"] + " " + t["name"],
            })

    for p in packages:
        index.append({
            "kind": "package",
            "title": p["name"],
            "url": "packages.html",
            "category": p["category"],
            "text": p["description"],
            "command": f"pkg install {p['name']}",
            "keywords": "apt package " + p["name"],
        })

    # documentation headings across the static pages
    pages = ["docs", "guides", "architecture", "security", "contributing", "about", "commands", "modules", "packages"]
    page_titles = {
        "docs": "Documentation", "guides": "Guides", "architecture": "Architecture",
        "security": "Security", "contributing": "Contributing", "about": "About",
        "commands": "Command reference", "modules": "Modules & tools", "packages": "APT packages",
    }
    for page in pages:
        path = os.path.join(ROOT, "site", page + ".html")
        try:
            content = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for m in re.finditer(r"<h([12])[^>]*id=\"([^\"]+)\"[^>]*>(.*?)</h\1>", content, re.S):
            heading = strip_tags(m.group(3))
            if heading:
                index.append({
                    "kind": "page",
                    "title": heading,
                    "url": f"{page}.html#{m.group(2)}",
                    "text": page_titles.get(page, page),
                    "keywords": "docs guide page " + page,
                })

    return index


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
    search = build_search(packages, modules, COMMANDS)
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
        ("search.json", search),
    ):
        with open(os.path.join(SITE_DATA, fname), "w", encoding="utf-8") as fh:
            json.dump(obj, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
    print(f"Wrote site/data/*.json: {len(packages)} packages, {tool_count} tools/"
          f"{len(modules)} categories, {len(COMMANDS)} commands, {len(search)} search entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())