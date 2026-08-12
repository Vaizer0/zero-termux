#!/data/data/com.termux/files/usr/bin/env bash
# ============================================
# WebHost tool
# Author: Alienkrishn [Anon4You]
# Description: Serve local directory and expose via tunnel
# ============================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Global variables
SERVER_PID=""
TUNNEL_PIDS=()
TEMP_DIR="${TMPDIR:-/tmp}/webserver_$$"
LOG_FILE="$TEMP_DIR/server.log"
TUNNEL_LOG="$TEMP_DIR/tunnel.log"      # used only for single tunnel
WEB_PATH=""
PORT=""
SERVER_TYPE=""
TUNNEL_TYPES=()

# Cleanup function
cleanup() {
    printf "\n${YELLOW}${BOLD}Cleaning up...${RESET}\n"

    if [[ -n "$SERVER_PID" ]] && kill -0 $SERVER_PID 2>/dev/null; then
        kill $SERVER_PID 2>/dev/null
        printf "${DIM}✓ Stopped server process${RESET}\n"
    fi

    for pid in "${TUNNEL_PIDS[@]}"; do
        if kill -0 $pid 2>/dev/null; then
            kill $pid 2>/dev/null
            printf "${DIM}✓ Stopped tunnel process${RESET}\n"
        fi
    done

    pkill -f "php -S" 2>/dev/null
    pkill -f "python3 -m http.server" 2>/dev/null
    pkill -f "http-server" 2>/dev/null
    pkill -f "ssh -R" 2>/dev/null
    pkill -f "tmole" 2>/dev/null
    pkill -f "cloudflared tunnel" 2>/dev/null
    pkill -f "ngrok" 2>/dev/null

    rm -rf "$TEMP_DIR" 2>/dev/null
    printf "${GREEN}✓ Cleanup complete${RESET}\n"
    exit 0
}

trap cleanup SIGINT SIGTERM SIGTSTP

check_internet() {
    printf "${CYAN}🔍 Checking internet connectivity...${RESET}\n"
    if curl -s --max-time 5 https://www.google.com >/dev/null 2>&1; then
        printf "${GREEN}✓ Internet connected${RESET}\n\n"
    else
        printf "${RED}${BOLD}✗ No internet connection! Please check your network.${RESET}\n"
        exit 1
    fi
}

check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        printf "${RED}✗ Port $1 is already in use${RESET}\n"
        return 1
    fi
    return 0
}

# Banner
print_banner() {
    clear
    if command -v figlet >/dev/null 2>&1; then
        figlet -f slant "WebHost" 2>/dev/null
    else
        echo -e "${BOLD}${CYAN}=== WebHost ===${RESET}"
    fi
    echo -e "${GREEN}${BOLD}Author:${RESET} ${CYAN}Alienkrishn [Anon4You]${RESET}"
    echo -e "${GREEN}${BOLD}About:${RESET} ${CYAN}Easily serve any local Web${RESET}"
    echo -e "${CYAN}       To the internet using TunnelMole, Localhost.run, Cloudflared, or Ngrok.${RESET}"
    echo -e "${DIM}─────────────────────────────────────────────────${RESET}\n"
}

# Server implementations
start_php_server() {
    local port=$1
    local path=$2
    php -S 0.0.0.0:$port -t "$path" > "$LOG_FILE" 2>&1 &
    echo $!
}

start_python_server() {
    local port=$1
    local path=$2
    (
        cd "$path"
        python3 -m http.server $port
    ) > "$LOG_FILE" 2>&1 &
    echo $!
}

start_node_server() {
    local port=$1
    local path=$2
    http-server "$path" -p $port -a 0.0.0.0 > "$LOG_FILE" 2>&1 &
    echo $!
}

# Tunnel implementations (now accept a log file parameter)
start_tunnelmole() {
    local port=$1
    local logfile=$2
    tmole $port > "$logfile" 2>&1 &
    echo $!
}

start_localhostrun() {
    local port=$1
    local logfile=$2
    ssh -R 80:localhost:$port nokey@localhost.run > "$logfile" 2>&1 &
    echo $!
}

start_cloudflared() {
    local port=$1
    local logfile=$2
    cloudflared tunnel --url localhost:$port > "$logfile" 2>&1 &
    echo $!
}

start_ngrok() {
    local port=$1
    local logfile=$2
    ngrok http $port --log=stdout > "$logfile" 2>&1 &
    echo $!
}

# Extract tunnel URL from a specific log file
extract_tunnel_url_from_log() {
    local type=$1
    local logfile=$2
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        case $type in
            1) # TunnelMole
                url=$(grep -o 'https://[-0-9a-z]*\.tunnelmole.net' "$logfile" 2>/dev/null | head -1)
                ;;
            2) # Localhost.run
                url=$(grep -o 'https://[-0-9a-z]*\.lhr\.life' "$logfile" 2>/dev/null | head -1)
                ;;
            3) # Cloudflared
                url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' "$logfile" 2>/dev/null | head -1)
                ;;
            4) # Ngrok - using local API first, fallback to log
                api_response=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null)
                if [[ -n "$api_response" ]]; then
                    url=$(echo "$api_response" | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)
                    if [[ "$url" == *"ngrok"* ]]; then
                        echo "$url"
                        return 0
                    fi
                fi
                url=$(grep -Eo 'https://[-0-9a-z]*\.(ngrok\.io|ngrok-free\.app|ngrok\.dev)' "$logfile" 2>/dev/null | head -1)
                ;;
        esac

        if [[ -n "$url" ]]; then
            echo "$url"
            return 0
        fi

        sleep 1
        ((attempt++))
    done

    return 1
}

# Wrapper for single tunnel (uses default TUNNEL_LOG)
extract_tunnel_url() {
    extract_tunnel_url_from_log "$1" "$TUNNEL_LOG"
}

# Main script
main() {
    print_banner
    check_internet

    mkdir -p "$TEMP_DIR"

    printf "${CYAN}📁 Target path : ${RESET}"
    read -r web
    WEB_PATH="${web:-.}"

    if [ ! -d "$WEB_PATH" ]; then
        printf "${RED}✗ Directory not found!${RESET}\n"
        exit 1
    fi
    printf "${GREEN}✓ Using directory: $WEB_PATH${RESET}\n\n"

    printf "${CYAN}🔌 Local port (default: 8080): ${RESET}"
    read -r port
    PORT="${port:-8080}"

    if ! check_port $PORT; then
        exit 1
    fi
    printf "${GREEN}✓ Port $PORT is available${RESET}\n\n"

    echo -e "${BOLD}${MAGENTA}┌─────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${MAGENTA}│         SELECT SERVER TYPE              │${RESET}"
    echo -e "${BOLD}${MAGENTA}└─────────────────────────────────────────┘${RESET}"
    echo -e "${GREEN}1) PHP Server (php -S)${RESET}"
    echo -e "${GREEN}2) Python Server (python3 -m http.server)${RESET}"
    echo -e "${GREEN}3) Node.js Server (http-server)${RESET}"
    printf "${CYAN}👉 Enter choice [1-3]: ${RESET}"
    read -r server_choice

    case $server_choice in
        1)
            if ! command -v php >/dev/null 2>&1; then
                printf "${RED}✗ PHP is not installed!${RESET}\n"
                exit 1
            fi
            printf "${YELLOW}🚀 Starting PHP server...${RESET}\n"
            SERVER_PID=$(start_php_server $PORT "$WEB_PATH")
            SERVER_TYPE="PHP"
            ;;
        2)
            if ! command -v python3 >/dev/null 2>&1; then
                printf "${RED}✗ Python3 is not installed!${RESET}\n"
                exit 1
            fi
            printf "${YELLOW}🐍 Starting Python server...${RESET}\n"
            SERVER_PID=$(start_python_server $PORT "$WEB_PATH")
            SERVER_TYPE="Python"
            ;;
        3)
            if ! command -v http-server >/dev/null 2>&1; then
                printf "${RED}✗ http-server is not installed! Install with: npm install -g http-server${RESET}\n"
                exit 1
            fi
            printf "${YELLOW}📦 Starting Node.js server (http-server)...${RESET}\n"
            SERVER_PID=$(start_node_server $PORT "$WEB_PATH")
            SERVER_TYPE="Node.js (http-server)"
            ;;
        *)
            printf "${RED}✗ Invalid choice!${RESET}\n"
            exit 1
            ;;
    esac

    sleep 2

    if kill -0 $SERVER_PID 2>/dev/null; then
        printf "${GREEN}✓ ${SERVER_TYPE} server started successfully on port $PORT${RESET}\n"
        printf "${DIM}  ➜ Local access: http://localhost:$PORT${RESET}\n\n"
    else
        printf "${RED}✗ Failed to start server!${RESET}\n"
        exit 1
    fi

    echo -e "${BOLD}${MAGENTA}┌─────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${MAGENTA}│         SELECT TUNNEL SERVICE           │${RESET}"
    echo -e "${BOLD}${MAGENTA}└─────────────────────────────────────────┘${RESET}"
    echo -e "${GREEN}1) TunnelMole${RESET}"
    echo -e "${GREEN}2) Localhost.run${RESET}"
    echo -e "${GREEN}3) Cloudflared${RESET}"
    echo -e "${GREEN}4) Ngrok${RESET}"
    echo -e "${GREEN}5) All (run all tunnels)${RESET}"
    printf "${CYAN}👉 Enter choice [1-5]: ${RESET}"
    read -r tunnel_choice

    printf "${YELLOW}🔗 Starting tunnel(s)...${RESET}\n"

    if [[ "$tunnel_choice" == "5" ]]; then
        # All tunnels - use separate log files
        declare -A tunnel_logs
        declare -A tunnel_pids
        declare -A tunnel_names

        for tnum in 1 2 3 4; do
            # Determine tool and name
            case $tnum in
                1) tool="tmole"; name="TunnelMole" ;;
                2) tool="ssh";   name="Localhost.run" ;;
                3) tool="cloudflared"; name="Cloudflared" ;;
                4) tool="ngrok"; name="Ngrok" ;;
            esac
            # Check dependency
            if ! command -v $tool >/dev/null 2>&1; then
                printf "${RED}✗ $name not installed, skipping.${RESET}\n"
                continue
            fi
            # For ngrok, check authentication once
            if [[ $tnum -eq 4 ]] && ! ngrok config check >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  Ngrok authentication required!${RESET}"
                echo -e "${CYAN}Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken${RESET}"
                printf "${CYAN}👉 Enter your ngrok authtoken: ${RESET}"
                read -r AUTH_TOKEN
                if [[ -n "$AUTH_TOKEN" ]]; then
                    ngrok config add-authtoken "$AUTH_TOKEN"
                    echo -e "${GREEN}✓ Authtoken saved${RESET}"
                else
                    echo -e "${RED}✗ No token provided, skipping ngrok.${RESET}"
                    continue
                fi
            fi

            # Create unique log file
            logfile="$TEMP_DIR/tunnel_${name}.log"
            tunnel_logs["$name"]="$logfile"

            # Start tunnel with its own logfile
            case $tnum in
                1) pid=$(start_tunnelmole $PORT "$logfile") ;;
                2) pid=$(start_localhostrun $PORT "$logfile") ;;
                3) pid=$(start_cloudflared $PORT "$logfile") ;;
                4) pid=$(start_ngrok $PORT "$logfile") ;;
            esac
            if [[ -n "$pid" ]]; then
                tunnel_pids["$name"]=$pid
                tunnel_names["$name"]="$name"
                TUNNEL_PIDS+=("$pid")
                TUNNEL_TYPES+=("$name")
            fi
            sleep 1   # small delay to avoid resource contention
        done

        if [[ ${#tunnel_pids[@]} -eq 0 ]]; then
            printf "${RED}✗ No tunnels could be started. Exiting.${RESET}\n"
            cleanup
        fi

        printf "${YELLOW}⏳ Waiting for tunnels to establish...${RESET}\n"
        declare -A url_map
        for name in "${!tunnel_pids[@]}"; do
            case $name in
                "TunnelMole") tnum=1 ;;
                "Localhost.run") tnum=2 ;;
                "Cloudflared") tnum=3 ;;
                "Ngrok") tnum=4 ;;
            esac
            printf "${DIM}  Getting URL for $name...${RESET}\n"
            url=$(extract_tunnel_url_from_log $tnum "${tunnel_logs[$name]}")
            if [[ -n "$url" ]]; then
                url_map["$name"]="$url"
            else
                url_map["$name"]="${RED}Failed to get URL${RESET}"
            fi
        done

        printf "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════${RESET}\n"
        printf "${GREEN}✓ Tunnels established!${RESET}\n"
        printf "${CYAN}🔒 Local URL:  ${BOLD}http://localhost:$PORT${RESET}\n"
        printf "${CYAN}📁 Serving:    ${BOLD}$WEB_PATH${RESET}\n"
        printf "${CYAN}🚀 Server:     ${BOLD}${SERVER_TYPE}${RESET}\n"
        printf "${GREEN}${BOLD}──────────────────────────────────────────────────────────${RESET}\n"
        for name in "${TUNNEL_TYPES[@]}"; do
            printf "${CYAN}🌐 ${BOLD}${name}:${RESET} ${YELLOW}${url_map[$name]}${RESET}\n"
        done
        printf "${GREEN}${BOLD}══════════════════════════════════════════════════════════${RESET}\n\n"
        printf "${BLUE}💡 Share any of the Public URLs to access your local server!${RESET}\n"
        printf "${YELLOW}⚠️  Press ${BOLD}ENTER${RESET}${YELLOW} to stop all tunnels and exit...${RESET}\n"
        read -r
    else
        # Single tunnel - use original TUNNEL_LOG
        case $tunnel_choice in
            1)
                if ! command -v tmole >/dev/null 2>&1; then
                    printf "${RED}✗ TunnelMole not installed! Install with: npm install -g tunnelmole${RESET}\n"
                    cleanup
                fi
                pid=$(start_tunnelmole $PORT "$TUNNEL_LOG")
                TUNNEL_PIDS+=("$pid")
                TUNNEL_TYPES+=("TunnelMole")
                ;;
            2)
                if ! command -v ssh >/dev/null 2>&1; then
                    printf "${RED}✗ SSH client not found!${RESET}\n"
                    cleanup
                fi
                pid=$(start_localhostrun $PORT "$TUNNEL_LOG")
                TUNNEL_PIDS+=("$pid")
                TUNNEL_TYPES+=("Localhost.run")
                ;;
            3)
                if ! command -v cloudflared >/dev/null 2>&1; then
                    printf "${RED}✗ Cloudflared not installed! Get it from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation${RESET}\n"
                    cleanup
                fi
                pid=$(start_cloudflared $PORT "$TUNNEL_LOG")
                TUNNEL_PIDS+=("$pid")
                TUNNEL_TYPES+=("Cloudflared")
                ;;
            4)
                if ! command -v ngrok >/dev/null 2>&1; then
                    printf "${RED}✗ Ngrok not installed! Install with: apt install ngrok${RESET}\n"
                    cleanup
                fi
                if ! ngrok config check >/dev/null 2>&1; then
                    echo -e "${YELLOW}⚠️  Ngrok authentication required!${RESET}"
                    echo -e "${CYAN}Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken${RESET}"
                    printf "${CYAN}👉 Enter your ngrok authtoken: ${RESET}"
                    read -r AUTH_TOKEN
                    if [[ -n "$AUTH_TOKEN" ]]; then
                        ngrok config add-authtoken "$AUTH_TOKEN"
                        echo -e "${GREEN}✓ Authtoken saved${RESET}"
                    else
                        echo -e "${RED}✗ No token provided. Cannot start ngrok.${RESET}"
                        cleanup
                    fi
                fi
                pid=$(start_ngrok $PORT "$TUNNEL_LOG")
                TUNNEL_PIDS+=("$pid")
                TUNNEL_TYPES+=("Ngrok")
                ;;
            *)
                printf "${RED}✗ Invalid choice!${RESET}\n"
                cleanup
                ;;
        esac

        printf "${YELLOW}⏳ Waiting for tunnel to establish...${RESET}\n"
        TUNNEL_URL=$(extract_tunnel_url $tunnel_choice)

        if [ -n "$TUNNEL_URL" ]; then
            printf "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════${RESET}\n"
            printf "${GREEN}✓ Tunnel established!${RESET}\n"
            printf "${CYAN}🌐 Public URL: ${BOLD}${YELLOW}$TUNNEL_URL${RESET}\n"
            printf "${CYAN}🔒 Local URL:  ${BOLD}http://localhost:$PORT${RESET}\n"
            printf "${CYAN}📁 Serving:    ${BOLD}$WEB_PATH${RESET}\n"
            printf "${CYAN}🚀 Server:     ${BOLD}${SERVER_TYPE}${RESET}\n"
            printf "${CYAN}🔧 Tunnel:     ${BOLD}${TUNNEL_TYPES[0]}${RESET}\n"
            printf "${GREEN}${BOLD}══════════════════════════════════════════════════════════${RESET}\n\n"
            printf "${BLUE}💡 Share the Public URL with anyone to access your local server!${RESET}\n"
            printf "${YELLOW}⚠️  Press ${BOLD}ENTER${RESET}${YELLOW} to stop the server and exit...${RESET}\n"
            read -r
        else
            printf "${RED}✗ Failed to get tunnel URL after 30 seconds${RESET}\n"
            printf "${YELLOW}Check the log at: $TUNNEL_LOG${RESET}\n"
        fi
    fi

    cleanup
}

# Run main function
main
