#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import argparse
import subprocess
import platform
import time
import random
import sys
from urllib.parse import urlparse, quote_plus, urlencode
from datetime import datetime

import requests
from bs4 import BeautifulSoup
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
from rich import box
from rich.panel import Panel
from rich.text import Text
from pyfiglet import Figlet

console = Console()

ANSI_RESET = "\033[0m"
ANSI_BOLD = "\033[1m"
ANSI_CYAN = "\033[36m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_BLUE = "\033[34m"
ANSI_MAGENTA = "\033[35m"
ANSI_RED = "\033[31m"

class ColoredVersionAction(argparse.Action):
    def __init__(self, option_strings, dest, default=None, required=False, help=None, version=None):
        super().__init__(option_strings, dest, nargs=0, default=default, required=required, help=help)
        self.version = version

    def __call__(self, parser, namespace, values, option_string=None):
        console.print(f"[bold green]Link Wizard {self.version}[/bold green]")
        parser.exit()

class ColorHelpFormatter(argparse.HelpFormatter):
    def _format_usage(self, usage, actions, groups, prefix):
        if prefix is None:
            prefix = "usage: "
        formatted_usage = super()._format_usage(usage, actions, groups, prefix)
        formatted_usage = formatted_usage.replace(prefix, f"{ANSI_BOLD}{ANSI_GREEN}{prefix}{ANSI_RESET}")
        if "linkwizard" in formatted_usage:
            formatted_usage = formatted_usage.replace("linkwizard", f"{ANSI_CYAN}linkwizard{ANSI_RESET}")
        return formatted_usage

    def _format_action_invocation(self, action):
        inv = super()._format_action_invocation(action)
        if action.option_strings:
            for opt in action.option_strings:
                inv = inv.replace(opt, f"{ANSI_CYAN}{opt}{ANSI_RESET}")
            if action.metavar:
                inv = inv.replace(action.metavar, f"{ANSI_YELLOW}{action.metavar}{ANSI_RESET}")
        return inv

    def _format_action(self, action):
        parts = super()._format_action(action).split('\n')
        if not parts:
            return ""
        first_line = parts[0]
        if '  ' in first_line:
            idx = first_line.find('  ')
            help_text = first_line[idx:]
            colored_help = f"{ANSI_BLUE}{help_text}{ANSI_RESET}"
            first_line = first_line[:idx] + colored_help
        parts[0] = first_line
        return '\n'.join(parts)

    def _format_text(self, text):
        return f"{ANSI_MAGENTA}{text}{ANSI_RESET}"

    def format_help(self):
        help_text = super().format_help()
        header = f"{ANSI_BOLD}{ANSI_GREEN}Link Wizard Help{ANSI_RESET}\n\n"
        return header + help_text

def show_banner():
    f = Figlet(font='slant')
    banner = f.renderText('Link Wizard')
    console.print(f"[bold green]{banner}[/bold green]")
    console.print("[dim]A powerful profile link finder for Termux[/dim]")
    console.print("[dim]Install via Termux Void repository: [bold green]pkg install linkwizard[/bold green][/dim]")

    about = Panel.fit(
        Text("Searches DuckDuckGo for the term (optionally exact match),\n"
             "then filters results to domains listed in domains.txt\n"
             "and common profile paths. Extracts profile links and\n"
             "generates a stylish HTML report.\n\n"
             "If no results appear, the server may be rate‑limiting.\n"
             "Wait a few seconds and try again. You can also use a VPN.\n"
             "Domain list can be managed with 'linkwizard domains ...'",
             style="dim"),
        title="[bold cyan]About[/bold cyan]",
        border_style="cyan",
        padding=(0, 1)
    )
    console.print(about)

def load_domains(domains_file):
    try:
        with open(domains_file, 'r', encoding='utf-8') as f:
            return {line.strip().lower() for line in f if line.strip() and not line.startswith('#')}
    except FileNotFoundError:
        return set()

def save_domains(domains_file, domains):
    with open(domains_file, 'w', encoding='utf-8') as f:
        for domain in sorted(domains):
            f.write(domain + '\n')

def add_domain(domains_file, domain):
    domains = load_domains(domains_file)
    if domain.lower() in domains:
        console.print(f"[yellow]Domain '{domain}' already exists.[/yellow]")
        return False
    domains.add(domain.lower())
    save_domains(domains_file, domains)
    console.print(f"[green]Domain '{domain}' added.[/green]")
    return True

def remove_domain(domains_file, domain):
    domains = load_domains(domains_file)
    if domain.lower() not in domains:
        console.print(f"[yellow]Domain '{domain}' not found.[/yellow]")
        return False
    domains.remove(domain.lower())
    save_domains(domains_file, domains)
    console.print(f"[green]Domain '{domain}' removed.[/green]")
    return True

def list_domains(domains_file):
    domains = load_domains(domains_file)
    if not domains:
        console.print("[yellow]No domains found. Add some with 'linkwizard domains add domain.com'[/yellow]")
        return
    table = Table(title="Profile Domains", box=box.ROUNDED, show_lines=False)
    table.add_column("Domain", style="cyan")
    for domain in sorted(domains):
        table.add_row(domain)
    console.print(table)

def is_profile_link(url: str, domains: set) -> bool:
    parsed = urlparse(url)
    domain = parsed.netloc.lower()
    if domain.startswith("www."):
        domain = domain[4:]
    if domain in domains:
        return True
    path = parsed.path.lower()
    if any(path.startswith(f"/{p}") for p in ["user", "u/", "profile", "users", "member", "@", "~"]):
        return True
    return False

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15"
]

def search_duckduckgo(query: str, max_results: int = 50, max_pages: int = 5, exact: bool = False, verbose: bool = False) -> list:
    session = requests.Session()
    session.headers.update({"User-Agent": random.choice(USER_AGENTS)})
    
    if exact:
        search_query = f'"{query}"'
    else:
        search_query = query
    encoded_query = quote_plus(search_query)
    base_url = "https://html.duckduckgo.com/html/"
    
    all_urls = set()
    start = 0
    page = 0

    while page < max_pages and len(all_urls) < max_results:
        params = {"q": encoded_query, "s": start}
        
        if verbose:
            console.print(f"[dim]Requesting: {base_url}?{urlencode(params)}[/dim]")
        
        if page > 0:
            time.sleep(random.uniform(1.5, 3))
        
        try:
            resp = session.get(base_url, params=params, timeout=15)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "html.parser")
            
            links = soup.find_all("a", class_="result__a")
            if not links:
                links = soup.find_all("a", href=True)
            
            new_found = 0
            for link in links:
                href = link.get("href")
                if href and href.startswith("http"):
                    if href not in all_urls:
                        all_urls.add(href)
                        new_found += 1
                        if len(all_urls) >= max_results:
                            break
            
            if verbose:
                console.print(f"[dim]Page {page+1}: found {new_found} new results (total {len(all_urls)})[/dim]")
            
            if not links or new_found == 0:
                break
            
            start += 30
            page += 1
            
        except requests.exceptions.RequestException as e:
            console.print(f"[red]Request failed on page {page+1}: {e}[/red]")
            break
        except Exception as e:
            console.print(f"[red]Unexpected error on page {page+1}: {e}[/red]")
            break
    
    return list(all_urls)[:max_results]

def generate_html_report(term: str, urls: list, template_file: str) -> str:
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            template = f.read()
    except FileNotFoundError:
        console.print(f"[red]Template file '{template_file}' not found. Using default template.[/red]")
        template = """<!DOCTYPE html><html><head><title>Profile Links</title></head><body><h1>{term}</h1><ul>{cards}</ul></body></html>"""
    
    cards_html = ""
    for url in urls:
        domain = urlparse(url).netloc
        if domain.startswith("www."):
            domain = domain[4:]
        cards_html += f"""
        <a href="{url}" target="_blank" rel="noopener noreferrer" class="card">
            <div class="card-content">
                <div class="card-domain">{domain}</div>
                <div class="card-url">{url}</div>
            </div>
        </a>
        """
    
    html = template.replace("{term}", term) \
                   .replace("{count}", str(len(urls))) \
                   .replace("{timestamp}", datetime.now().strftime("%Y-%m-%d %H:%M:%S")) \
                   .replace("{cards}", cards_html)
    return html

def open_html_file(filepath: str):
    system = platform.system()
    try:
        if system == "Windows":
            os.startfile(filepath)
        elif system == "Darwin":
            subprocess.run(["open", filepath])
        else:
            if os.path.exists("/data/data/com.termux/files/usr/bin/termux-open"):
                subprocess.run(["termux-open", filepath])
            else:
                subprocess.run(["xdg-open", filepath])
        console.print(f"[green]Opened {filepath} in your default browser.[/green]")
    except Exception as e:
        console.print(f"[red]Failed to open file: {e}[/red]")

def search_command(term, args):
    domains = load_domains(args.domains)
    if not domains:
        console.print("[yellow]No domains loaded – will only use path patterns.[/yellow]")

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TimeElapsedColumn(),
        console=console
    ) as progress:
        task = progress.add_task("[green]Querying DuckDuckGo...", total=1)
        urls = search_duckduckgo(
            term,
            max_results=args.max,
            max_pages=args.pages,
            exact=args.exact,
            verbose=args.verbose
        )
        progress.update(task, completed=1, description="[green]Done")

    if not urls:
        console.print("\n[yellow]⚠️ No search results returned. This might be due to:[/yellow]")
        console.print("  • DuckDuckGo temporarily blocking this IP")
        console.print("  • Network issues")
        console.print("  • The term is too common or not found")
        console.print("[dim]Try again later or use a VPN.[/dim]")
        return

    profile_urls = [url for url in urls if is_profile_link(url, domains)]
    console.print(f"\n[green]✅ Found {len(profile_urls)} profile links (out of {len(urls)} total results)[/green]")

    if profile_urls:
        table = Table(title="Profile Links", box=box.SIMPLE, show_lines=False)
        table.add_column("URL", style="dim")
        for url in profile_urls:
            table.add_row(url)
        console.print(table)

        output_file = args.output if args.output else "profile_links.html"

        html_content = generate_html_report(term, profile_urls, args.template)
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(html_content)
        console.print(f"[green]📄 HTML report saved to {output_file}[/green]")
        if not args.no_open:
            open_html_file(output_file)
    else:
        console.print("\n[yellow]⚠️ No profile links found in the search results.[/yellow]")

def handle_domains_command():
    parser = ColoredArgumentParser(prog="linkwizard domains", description="Manage profile domains",
                                   formatter_class=ColorHelpFormatter)
    subparsers = parser.add_subparsers(dest="domains_action", required=True)

    add_parser = subparsers.add_parser("add", help="Add a domain")
    add_parser.add_argument("domain", help="Domain to add (e.g., example.com)")
    add_parser.add_argument("--domains-file", default="domains.txt", help="Domains file to modify")

    remove_parser = subparsers.add_parser("remove", help="Remove a domain")
    remove_parser.add_argument("domain", help="Domain to remove")
    remove_parser.add_argument("--domains-file", default="domains.txt", help="Domains file to modify")

    list_parser = subparsers.add_parser("list", help="List all domains")
    list_parser.add_argument("--domains-file", default="domains.txt", help="Domains file to read")

    args = parser.parse_args(sys.argv[2:])

    if args.domains_action == "add":
        add_domain(args.domains_file, args.domain)
    elif args.domains_action == "remove":
        remove_domain(args.domains_file, args.domain)
    elif args.domains_action == "list":
        list_domains(args.domains_file)

class ColoredArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        console.print(f"\n[bold red]Error:[/bold red] {message}")
        console.print("[dim]Use -h or --help for usage information.[/dim]\n")
        self.exit(2)

def main():
    os.system("clear")
    show_banner()

    if len(sys.argv) > 1 and sys.argv[1] == "domains":
        handle_domains_command()
        return

    parser = ColoredArgumentParser(
        description="Search DuckDuckGo for a term and extract profile links.",
        usage="linkwizard <term> [options]",
        formatter_class=ColorHelpFormatter
    )
    parser.add_argument("term", help="The search term (e.g., a username, company name)")
    parser.add_argument("--max", type=int, default=50, help="Maximum number of search results to fetch (overall)")
    parser.add_argument("--pages", type=int, default=3, help="Maximum number of result pages to fetch (each page ~30 results)")
    parser.add_argument("--exact", action="store_true", help="Search for exact phrase (wrap term in quotes)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed progress and URLs")
    parser.add_argument("--domains", default="domains.txt", help="File with list of profile domains (one per line)")
    parser.add_argument("--template", default="template.html", help="HTML template file with placeholders")
    parser.add_argument("--output", "-o", default="", help="Output HTML file name (default: profile_links.html)")
    parser.add_argument("--no-open", action="store_true", help="Do not automatically open the HTML report")
    parser.add_argument("--version", action=ColoredVersionAction, version="1.0",
                        help="Show version and exit")

    args = parser.parse_args()
    search_command(args.term, args)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[bold red]Interrupted by user.[/bold red]")
