#!/data/data/com.termux/files/usr/bin/bash

BANNER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BANNER_FILE="$(cd "$BANNER_SCRIPT_DIR/../.." && pwd)/assets/banner/zero-termux.txt"
BANNER_VERSION="$(grep "^ZERO_VERSION=" "$BANNER_SCRIPT_DIR/env.sh" 2>/dev/null | cut -d'"' -f2)"

# ── Colors (self-contained for shell startup sourcing) ─────
DGREEN="\033[0;32m"
NC="\033[0m"
GRAY="\033[0;90m"
D_CYAN="\033[0;36m"

# ── Reusable tip function (matches log.sh style) ───────────
log_tip() {
	echo -e " ${D_CYAN}● Tip${NC} $*"
}

if [[ -f "$BANNER_FILE" ]]; then
	cat "$BANNER_FILE"
fi

if [[ -n "$BANNER_VERSION" ]]; then
	printf "\n"
	printf " ${GRAY}Zero-Termux ${NC}Community${NC}\n"
	printf "     ${NC}Welcome to${GRAY} Zero-Termux ${DGREEN}v%s${NC}\n" "$BANNER_VERSION"
	printf "        ${NC}Run ${DGREEN}zero${NC} to get started${NC}\n"
fi

# ── Random Tip ──────────────────────────────────────────────

ZERO_TIPS=(
	# ── Framework ─────────────────────────────────────────────
	"Keep Zero-Termux updated: ${D_CYAN}zero update zero${NC}"
	"Check your version: ${D_CYAN}zero --version${NC}"
	"Enable debug logs: ${D_CYAN}export ZERO_DEBUG=1${NC}"
	"Shell remembers your last directory — open Termux where you left off"
	"Open framework docs: ${D_CYAN}zero open zero${NC}"
	"Visit Zero-Termux website: ${D_CYAN}zero open zero${NC}"

	# ── Install / Update / Uninstall ─────────────────────────
	"Install everything at once: ${D_CYAN}zero install lang db dev npm${NC}"
	"Install only what you need: ${D_CYAN}zero install ai --opencode --ollama${NC}"
	"See what's installed: ${D_CYAN}zero list ai${NC} or ${D_CYAN}zero list dev${NC}"
	"Read tool docs: ${D_CYAN}zero show ai --opencode${NC}"
	"Update a specific tool: ${D_CYAN}zero update ai --opencode${NC}"
	"Update all AI tools: ${D_CYAN}zero update ai${NC}"
	"Update all databases: ${D_CYAN}zero update db${NC}"
	"Update ZSH plugins: ${D_CYAN}zero update shell${NC}"
	"Reinstall from scratch: ${D_CYAN}zero reinstall shell${NC}"
	"Reinstall specific tools: ${D_CYAN}zero reinstall ai --opencode --ollama${NC}"
	"Remove a module: ${D_CYAN}zero uninstall npm${NC}"
	"Remove specific tool: ${D_CYAN}zero uninstall ai --ollama${NC}"
	"Open tool docs in browser: ${D_CYAN}zero open ai${NC}"

	# ── Languages ────────────────────────────────────────────
	"Install all languages: ${D_CYAN}zero install lang${NC}"
	"Install Python: ${D_CYAN}zero install lang --python${NC}"
	"Install Rust: ${D_CYAN}zero install lang --rust${NC}"
	"Install Go: ${D_CYAN}zero install lang --golang${NC}"
	"Install Bun: ${D_CYAN}zero install lang --bun${NC}"
	"Install PHP: ${D_CYAN}zero install lang --php${NC}"
	"Install Perl: ${D_CYAN}zero install lang --perl${NC}"
	"Install C/C++: ${D_CYAN}zero install lang --clang${NC}"
	"Install Node.js LTS: ${D_CYAN}zero install lang --nodejs${NC}"

	# ── Databases ────────────────────────────────────────────
	"Install all databases: ${D_CYAN}zero install db${NC}"
	"Start PostgreSQL: ${D_CYAN}zero pg init${NC} then ${D_CYAN}zero pg start${NC}"
	"Open psql shell: ${D_CYAN}zero pg shell${NC}"
	"Create a database: ${D_CYAN}zero pg create mydb${NC}"
	"Check PG status: ${D_CYAN}zero pg status${NC}"
	"List all databases: ${D_CYAN}zero pg list${NC}"
	"Stop PostgreSQL: ${D_CYAN}zero pg stop${NC}"
	"Restart PostgreSQL: ${D_CYAN}zero pg restart${NC}"
	"Drop a database safely: ${D_CYAN}zero pg drop mydb${NC} (with confirmation)"
	"Install MariaDB: ${D_CYAN}zero install db --mariadb${NC}"
	"Install SQLite: ${D_CYAN}zero install db --sqlite${NC}"
	"Install MongoDB: ${D_CYAN}zero install db --mongodb${NC}"

	# ── AI Agents ────────────────────────────────────────────
	"Install all AI agents: ${D_CYAN}zero install ai${NC}"
	"Run Ollama locally on your phone: ${D_CYAN}zero install ai --ollama${NC}"
	"Install OpenCode: ${D_CYAN}zero install ai --opencode${NC}"
	"Install Qoder: ${D_CYAN}zero install ai --qoder${NC}"
	"Install Claude Code: ${D_CYAN}zero install ai --claude-code${NC}"
	"Install Codex CLI: ${D_CYAN}zero install ai --codex${NC}"
	"Install Gemini CLI: ${D_CYAN}zero install ai --gemini-cli${NC}"
	"Install MiMo Code: ${D_CYAN}zero install ai --mimocode${NC}"
	"Install Mistral Vibe: ${D_CYAN}zero install ai --mistral-vibe${NC}"
	"Install OpenClaude: ${D_CYAN}zero install ai --openclaude${NC}"
	"Install Pi agent: ${D_CYAN}zero install ai --pi${NC}"
	"Install Qwen Code: ${D_CYAN}zero install ai --qwen-code${NC}"
	"Install Hermes Agent: ${D_CYAN}zero install ai --hermes-agent${NC}"
	"Install Kimi Code: ${D_CYAN}zero install ai --kimi-code${NC}"
	"Install Gentle AI: ${D_CYAN}zero install ai --gentle-ai${NC}"
	"Install Engram memory: ${D_CYAN}zero install ai --engram${NC}"
	"Install CodeGraph: ${D_CYAN}zero install ai --codegraph${NC}"
	"Install GGA code review: ${D_CYAN}zero install ai --gga${NC}"
	"Install MiniMax CLI: ${D_CYAN}zero install ai --minimax-cli${NC}"
	"Install Command Code: ${D_CYAN}zero install ai --command-code${NC}"
	"Install Freebuff: ${D_CYAN}zero install ai --freebuff${NC}"
	"Install Kimchi: ${D_CYAN}zero install ai --kimchi${NC}"
	"Install Kilo Code CLI: ${D_CYAN}zero install ai --kilocode-cli${NC}"
	"Install KeelCode: ${D_CYAN}zero install ai --keelcode${NC}"
	"Install Context7: ${D_CYAN}zero install ai --ctx7${NC}"
	"Install OpenSpec: ${D_CYAN}zero install ai --openspec${NC}"
	"Install Cline CLI: ${D_CYAN}zero install ai --cline${NC}"
	"Install AMP Code CLI: ${D_CYAN}zero install ai --ampcode${NC}"
	"Install Cursor CLI: ${D_CYAN}zero install ai --cursor-cli${NC}"
	"Install Oh-My-Pi: ${D_CYAN}zero install ai --oh-my-pi${NC}"
	"Install SuperCode CLI: ${D_CYAN}zero install ai --supercode${NC}"
	"Install Droid Factory: ${D_CYAN}zero install ai --droid-factory${NC}"

	# ── Editor ───────────────────────────────────────────────
	"Install Neovim + NvChad: ${D_CYAN}zero install editor${NC}"
	"Install just Neovim: ${D_CYAN}zero install editor --neovim${NC}"
	"Install NvChad config: ${D_CYAN}zero install editor --nvchad${NC}"

	# ── Dev Tools ────────────────────────────────────────────
	"Fuzzy search commands: ${D_CYAN}zero install dev --fzf${NC}"
	"Modern ls with icons: ${D_CYAN}zero install dev --lsd${NC}"
	"Syntax-highlighted cat: ${D_CYAN}zero install dev --bat${NC}"
	"GitHub CLI for PRs and issues: ${D_CYAN}zero install dev --gh${NC}"
	"Share your terminal instantly: ${D_CYAN}zero install dev --tmate${NC}"
	"Run Docker without root: ${D_CYAN}zero install dev --udocker${NC}"
	"Browse files in the terminal: ${D_CYAN}zero install dev --superfile${NC}"
	"Translate text from terminal: ${D_CYAN}zero install dev --translate${NC}"
	"Convert HTML to text: ${D_CYAN}zero install dev --html2text${NC}"
	"Format shell scripts: ${D_CYAN}zero install dev --shfmt${NC}"
	"Process JSON from CLI: ${D_CYAN}zero install dev --jq${NC}"
	"Image manipulation: ${D_CYAN}zero install dev --imagemagick${NC}"
	"Arbitrary precision calculator: ${D_CYAN}zero install dev --bc${NC}"
	"Recursive directory listing: ${D_CYAN}zero install dev --tree${NC}"
	"Build automation: ${D_CYAN}zero install dev --make${NC}"
	"Chroot alternative: ${D_CYAN}zero install dev --proot${NC}"
	"Cloudflare Tunnel: ${D_CYAN}zero install dev --cloudflared${NC}"

	# ── NPM Packages ─────────────────────────────────────────
	"Tunnel localhost to the web: ${D_CYAN}zero install npm --ngrok${NC}"
	"Deploy to Vercel from terminal: ${D_CYAN}zero install npm --vercel${NC}"
	"Format code with Prettier: ${D_CYAN}zero install npm --prettier${NC}"
	"TypeScript compiler: ${D_CYAN}zero install npm --typescript${NC}"
	"Live reload dev server: ${D_CYAN}zero install npm --live-server${NC}"
	"Expose localhost via tunnel: ${D_CYAN}zero install npm --localtunnel${NC}"
	"Markdown preview server: ${D_CYAN}zero install npm --markserv${NC}"
	"PostgreSQL query formatter: ${D_CYAN}zero install npm --psqlformat${NC}"
	"Find outdated npm packages: ${D_CYAN}zero install npm --ncu${NC}"
	"NestJS CLI: ${D_CYAN}zero install npm --nestjs${NC}"

	# ── Shell ────────────────────────────────────────────────
	"Install ZSH + plugins: ${D_CYAN}zero install shell${NC}"
	"Install Powerlevel10k theme: ${D_CYAN}zero install shell --powerlevel10k${NC}"
	"Get fuzzy tab completion: ${D_CYAN}zero install shell --fzf-tab${NC}"
	"Smart command suggestions: ${D_CYAN}zero install shell --you-should-use${NC}"
	"Auto-close brackets: ${D_CYAN}zero install shell --zsh-autopair${NC}"
	"Deferred plugin loading: ${D_CYAN}zero install shell --zsh-defer${NC}"
	"Smart autocompletion: ${D_CYAN}zero install shell --zsh-autosuggestions${NC}"
	"Syntax highlighting: ${D_CYAN}zero install shell --zsh-syntax-highlighting${NC}"
	"History substring search: ${D_CYAN}zero install shell --history-substring${NC}"
	"Additional completions: ${D_CYAN}zero install shell --zsh-completions${NC}"
	"Better npm completion: ${D_CYAN}zero install shell --better-npm${NC}"

	# ── UI ───────────────────────────────────────────────────
	"Customize Termux UI: ${D_CYAN}zero install ui${NC}"
	"Install Meslo Nerd Font: ${D_CYAN}zero install ui --font${NC}"
	"Configure cursor color: ${D_CYAN}zero install ui --cursor${NC}"
	"Setup extra keys bar: ${D_CYAN}zero install ui --extra-keys${NC}"
	"Install Zero banner: ${D_CYAN}zero install ui --banner${NC}"

	# ── Automation ───────────────────────────────────────────
	"Run n8n automation: ${D_CYAN}zero install auto --n8n${NC}"
	"Install automation tools: ${D_CYAN}zero install auto${NC}"

	# ── Environment ──────────────────────────────────────────
	"Set API keys safely: ${D_CYAN}zero env set${NC} — input is hidden with ●●●"
	"List your env vars: ${D_CYAN}zero env ls${NC}"
	"Remove an env var: ${D_CYAN}zero env unset${NC}"

	# ── Brain ────────────────────────────────────────────────
	"Set up your second brain: ${D_CYAN}zero brain init${NC}"
	"Save memories: ${D_CYAN}zero brain save${NC}"
	"Search your brain: ${D_CYAN}zero brain search react${NC}"
	"List memories by category: ${D_CYAN}zero brain ls frontend${NC}"
	"Edit a memory directly: ${D_CYAN}zero brain edit slug-name${NC}"
	"Delete a memory: ${D_CYAN}zero brain delete${NC}"
	"View a memory: ${D_CYAN}zero brain show slug-name${NC}"
	"Visualize connections: ${D_CYAN}zero brain graph${NC}"
	"Create AI skill from memories: ${D_CYAN}zero brain skill${NC}"
	"Link memories together: ${D_CYAN}zero brain relate${NC}"
	"Sync brain to GitHub: ${D_CYAN}zero brain sync${NC}"
	"Reset your brain entirely: ${D_CYAN}zero brain reset${NC}"

	# ── Voice ────────────────────────────────────────────────
	"Voice-to-AI: ${D_CYAN}zero voice opencode${NC} — speak, edit, launch agent"
	"Quick voice output: ${D_CYAN}zero voice text${NC} — capture speech to stdout"
	"Use ${D_CYAN}zero voice !${NC} as a shortcut for ${D_CYAN}zero voice text${NC}"

	# ── Project Init ─────────────────────────────────────────
	"Init a Next.js project: ${D_CYAN}cd my-app && zero init next${NC}"
	"Init a React+Vite project: ${D_CYAN}cd my-app && zero init react${NC}"
	"Init an Express API: ${D_CYAN}cd api && zero init express${NC}"
	"Init a NestJS project: ${D_CYAN}cd backend && zero init nest${NC}"
)

_tip_index_file="${XDG_CACHE_HOME:-$HOME/.cache}/zero-termux/.last_tip_index"

if [[ ${#ZERO_TIPS[@]} -gt 0 ]]; then
	last_index=-1
	if [[ -f "$_tip_index_file" ]]; then
		last_index=$(cat "$_tip_index_file" 2>/dev/null || echo "-1")
	fi

	new_index=$last_index
	while [[ "$new_index" == "$last_index" ]]; do
		new_index=$(( RANDOM % ${#ZERO_TIPS[@]} ))
	done

	echo "$new_index" >"$_tip_index_file"

	_tip="${ZERO_TIPS[$new_index]:-}"
	if [[ -n "$_tip" ]]; then
		echo
		log_tip "$_tip"
	fi
fi
