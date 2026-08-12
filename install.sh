#!/data/data/com.termux/files/usr/bin/bash

set -e

readonly P_BORDER='\e[38;5;33m'
readonly P_PRIMARY='\e[38;5;39m'
readonly P_DIM='\e[38;5;244m'
readonly P_OK='\e[38;5;42m'
readonly P_FAIL='\e[1;31m'
readonly P_HL='\e[38;5;213m'
readonly P_NC='\e[0m'

REPO="https://github.com/Vaizer0/zero-termux"
BRANCH="main"
REPO_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zero-termux"
TOOL_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zero-termux-data"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zero-termux"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zero-termux"

# Zero-Termux APT repository
APT_SUITE="zero-termux"
APT_URL="https://vaizer0.github.io/zero-termux/repo"
APT_LIST="$PREFIX/etc/apt/sources.list.d/zero-termux.list"
GPG_KEY="$PREFIX/etc/apt/trusted.gpg.d/zero-termux.gpg"
GPG_URL="https://vaizer0.github.io/zero-termux/zero-termux.gpg"

TOTAL_STEPS=7
CURRENT_STEP=0

SILENT_MODE=false
while getopts "s" opt; do
  case "$opt" in
    s) SILENT_MODE=true ;;
    *) echo "Usage: $0 [-s]" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------

_cols() {
  if command -v tput &>/dev/null; then
    tput cols
  else
    echo 80
  fi
}

progress_bar() {
  local current=$1
  local total=$2
  local width=${3:-40}
  local percentage=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))

  printf -v bar "%*s" "$filled" ""
  bar="${bar// /█}"
  printf -v space "%*s" "$empty" ""
  space="${space// /░}"

  printf "\r  ${P_BORDER}│${P_NC}${P_OK}%s${P_NC}${P_DIM}%s${P_NC}${P_BORDER}│${P_NC} ${P_PRIMARY}%3d%%${P_NC}" "${bar}" "${space}" "$percentage"
}

log_step() {
  local step="$1"
  local desc="$2"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf "\r%*s\r" "$(_cols)" ""
  echo -e "\n  ${P_BORDER}◆${P_NC}  ${P_PRIMARY}${CURRENT_STEP}/${TOTAL_STEPS}${P_NC}  ${desc}"
}

log_ok() {
  echo -e "  ${P_OK}✔${P_NC}  $1"
}

log_fail() {
  echo -e "  ${P_FAIL}✖${P_NC}  $1" >&2
}

log_info() {
  echo -e "  ${P_BORDER}→${P_NC}  $1"
}

separator() {
  local cols=$(_cols)
  local line=$(printf "%${cols}s")
  echo -e "${P_DIM}${line// /─}${P_NC}"
}

banner() {
  echo
  echo -e "  ${P_BORDER}┌────────────────────────────────────┐${P_NC}"
  echo -e "  ${P_BORDER}│${P_NC}        ${P_PRIMARY}  ◈ ZERO-TERMUX ◈${P_NC}          ${P_BORDER}│${P_NC}"
  echo -e "  ${P_BORDER}│${P_NC} ${P_DIM}Modular Dev Environment for Termux${P_NC} ${P_BORDER}│${P_NC}"
  echo -e "  ${P_BORDER}└────────────────────────────────────┘${P_NC}"
  echo
}

# ---------------------------------------------------------------
# Step 1 — dependencies
# ---------------------------------------------------------------

bootstrap_dependencies() {
  local needed_tput=0
  local needed_git=0
  local needed_glow=0
  local needed_gh=0
  local needed_rg=0
  local needed_jq=0
  local needed_bat=0
  local needed_curl=0

  command -v tput &>/dev/null || needed_tput=1
  command -v git &>/dev/null || needed_git=1
  command -v glow &>/dev/null || needed_glow=1
  command -v gh &>/dev/null || needed_gh=1
  command -v rg &>/dev/null || needed_rg=1
  command -v jq &>/dev/null || needed_jq=1
  command -v bat &>/dev/null || needed_bat=1
  command -v curl &>/dev/null || needed_curl=1

  if [[ $needed_tput -eq 1 || $needed_git -eq 1 || $needed_glow -eq 1 || $needed_gh -eq 1 || $needed_rg -eq 1 || $needed_jq -eq 1 || $needed_bat -eq 1 || $needed_curl -eq 1 ]]; then
    banner
  fi

  if [[ $needed_tput -eq 1 ]]; then
    log_info "Installing ncurses-utils..."
    yes | pkg install ncurses-utils &>/dev/null
    log_ok "ncurses-utils installed"
    echo
  fi

  if [[ $needed_git -eq 1 ]]; then
    log_info "Installing git..."
    progress_bar 0 10
    yes | pkg install git &>/dev/null
    progress_bar 10 10
    echo
    log_ok "git installed"
  fi

  if [[ $needed_glow -eq 1 ]]; then
    log_info "Installing glow..."
    progress_bar 0 10
    yes | pkg install glow &>/dev/null
    progress_bar 10 10
    echo
    log_ok "glow installed"
  fi

  if [[ $needed_gh -eq 1 ]]; then
    log_info "Installing gh (GitHub CLI)..."
    progress_bar 0 10
    yes | pkg install gh &>/dev/null
    progress_bar 10 10
    echo
    log_ok "gh installed"
  fi

  if [[ $needed_rg -eq 1 ]]; then
    log_info "Installing ripgrep..."
    progress_bar 0 10
    yes | pkg install ripgrep &>/dev/null
    progress_bar 10 10
    echo
    log_ok "ripgrep installed"
  fi

  if [[ $needed_jq -eq 1 ]]; then
    log_info "Installing jq..."
    progress_bar 0 10
    yes | pkg install jq &>/dev/null
    progress_bar 10 10
    echo
    log_ok "jq installed"
  fi

  if [[ $needed_bat -eq 1 ]]; then
    log_info "Installing bat..."
    progress_bar 0 10
    yes | pkg install bat &>/dev/null
    progress_bar 10 10
    echo
    log_ok "bat installed"
  fi

  if [[ $needed_curl -eq 1 ]]; then
    log_info "Installing curl..."
    progress_bar 0 10
    yes | pkg install curl &>/dev/null
    progress_bar 10 10
    echo
    log_ok "curl installed"
  fi

  if [[ $needed_tput -eq 1 || $needed_git -eq 1 || $needed_glow -eq 1 || $needed_gh -eq 1 || $needed_rg -eq 1 || $needed_jq -eq 1 || $needed_bat -eq 1 || $needed_curl -eq 1 ]]; then
    echo
    clear
  fi
}

install_dependencies() {
  log_step 1 "Verifying dependencies"
  bootstrap_dependencies
  log_ok "All dependencies present"
}

# ---------------------------------------------------------------
# Step 2 — directories
# ---------------------------------------------------------------

setup_directories() {
  log_step 2 "Setting up directories"

  mkdir -p "$REPO_DIR" "$TOOL_DATA_DIR" "$CACHE_DIR" "$CONFIG_DIR"

  log_info "Repo    $REPO_DIR"
  log_info "Data    $TOOL_DATA_DIR"
  log_info "Cache   $CACHE_DIR"
  log_info "Config  $CONFIG_DIR"
  log_ok "Directories created"
}

# ---------------------------------------------------------------
# Step 3 — clone repository
# ---------------------------------------------------------------

clone_repo() {
  log_step 3 "Cloning repository"

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local is_dev_install=0

  if [[ -d "$script_dir/.git" ]] && [[ "$script_dir" != "$REPO_DIR" ]]; then
    is_dev_install=1
  fi

  if [[ $is_dev_install -eq 1 ]]; then
    REPO_DIR="$script_dir"
    log_info "Developer installation detected"
    log_ok "Using local repository"
  elif [[ -d "$REPO_DIR/.git" ]]; then
    progress_bar 3 10
    git -C "$REPO_DIR" pull origin "$BRANCH" &>/dev/null
    progress_bar 10 10
    echo
    log_ok "Repository updated"
  else
    if [[ -d "$REPO_DIR" ]]; then
      rm -rf "$REPO_DIR"
    fi
    progress_bar 0 10
    git clone --depth=1 -b "$BRANCH" "$REPO" "$REPO_DIR" &>/dev/null &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      for i in $(seq 0 10); do
        progress_bar $i 10
        sleep 0.1
      done
    done
    wait "$pid"
    progress_bar 10 10
    echo
    log_ok "Repository cloned"
  fi
}

# ---------------------------------------------------------------
# Step 4 — zero command
# ---------------------------------------------------------------

create_symlink() {
  log_step 4 "Creating zero command"

  mkdir -p "$PREFIX/bin"
  rm -f "$PREFIX/bin/zero"
  ln -sf "$REPO_DIR/zero/bin/zero" "$PREFIX/bin/zero"

  if [[ -L "$PREFIX/bin/zero" ]]; then
    log_ok "Symlink created: zero → ${REPO_DIR}/zero/bin/zero"
  else
    log_fail "Failed to create symlink"
    return 1
  fi
}

# ---------------------------------------------------------------
# Step 5 — Zero-Termux APT repository
# ---------------------------------------------------------------

setup_apt_repo() {
  log_step 5 "Configuring Zero-Termux APT repository"

  mkdir -p "$PREFIX/etc/apt/sources.list.d" "$PREFIX/etc/apt/trusted.gpg.d"

  echo "deb [trusted=yes arch=all] $APT_URL $APT_SUITE main" > "$APT_LIST"
  log_ok "Repository configured: $APT_LIST"

  if curl -fsSL "$GPG_URL" -o "$GPG_KEY"; then
    log_ok "GPG key installed: $GPG_KEY"
  else
    log_fail "Could not fetch $GPG_URL — apt will still work with trusted=yes, but verify the key later."
  fi

  if apt update -y; then
    log_ok "Package lists updated"
  else
    log_fail "apt update failed — run 'pkg update' after the installer finishes."
  fi
}

# ---------------------------------------------------------------
# Step 6 — save configuration
# ---------------------------------------------------------------

save_config() {
  log_step 6 "Saving configuration"

  cat >"$CONFIG_DIR/config" <<EOF
zero_data='$REPO_DIR'
zero_cache='$CACHE_DIR'
zero_config='$CONFIG_DIR'
zero_source='$REPO_DIR'
zero_tool_data='$TOOL_DATA_DIR'
EOF

  log_ok "Configuration saved"
}

# ---------------------------------------------------------------
# Step 7 — final message
# ---------------------------------------------------------------

show_final_message() {
  log_step 7 "Finalizing"

  echo
  separator
  echo -e "  ${P_OK}◆${P_NC}  ${P_PRIMARY}Installation Complete${P_NC}"
  separator
  echo
  echo -e "  ${P_DIM}Run${P_NC}  ${P_HL}zero${P_NC}  ${P_DIM}to get started${P_NC}"
  echo
  echo -e "  ${P_DIM}Install modules:${P_NC}"
  echo
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install lang" "Programming languages"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install db" "Databases"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install ai" "AI tools"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install editor" "Code editor"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install dev" "Dev tools"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install npm" "Node.js tools"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install shell" "ZSH shell"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install ui" "Termux UI"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "zero install auto" "n8n"
  echo
  echo -e "  ${P_DIM}APT packages (Zero-Termux repository):${P_NC}"
  echo
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "pkg search <tool>" "Search packages"
  printf "    ${P_PRIMARY}%-20s${P_NC} ${P_DIM}%s${P_NC}\n" "pkg install zero-termux" "Zero-Termux package manager"
  echo
  echo -e "  ${P_DIM}Website:${P_NC}  ${P_HL}https://vaizer0.github.io/zero-termux${P_NC}"
  echo
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------

main() {
  if [[ "$SILENT_MODE" == false ]]; then
    echo
    echo -e "${P_INFO}This will install Zero-Termux (zero CLI + APT repository) on your Termux device.${P_NC}"
    read -r -p "Continue? [Y/n] " answer
    case "$answer" in
      n|N|no) echo "Aborted."; exit 0 ;;
    esac
  fi

  bootstrap_dependencies
  banner
  install_dependencies
  setup_directories
  clone_repo
  create_symlink
  setup_apt_repo
  save_config
  show_final_message
}

P_INFO="${P_DIM}"
main
