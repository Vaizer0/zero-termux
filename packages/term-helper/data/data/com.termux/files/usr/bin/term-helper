#!/usr/bin/bash

# Clear screen and set error handling
clear
set -euo pipefail

# Color codes for better readability
RED='\e[31;1m'
GREEN='\e[32;1m'
YELLOW='\e[33;1m'
BLUE='\e[34;1m'
MAGENTA='\e[35;1m'
CYAN='\e[36;1m'
RESET='\e[0m'
BOLD='\e[1m'

# Configuration
DEFAULT_SAVE_DIR="$HOME/termux-cheatsheets"
SAVE_EXTENSION=".txt"
SCRIPT_NAME=$(basename "$0")

# Function to check and install dependencies
check_dependencies() {
    local deps=("pv" "curl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing missing dependencies: ${missing_deps[*]}${RESET}"
        apt install -y "${missing_deps[@]}"
    fi
}

# Function to create save directory if it doesn't exist
create_save_dir() {
    if [ ! -d "$DEFAULT_SAVE_DIR" ]; then
        mkdir -p "$DEFAULT_SAVE_DIR"
        echo -e "${GREEN}Created save directory: $DEFAULT_SAVE_DIR${RESET}"
    fi
}

# Function to display enhanced banner
show_banner() {
    echo -e "${CYAN}${BOLD}
       ▀▛▘            ▌ ▌   ▜          
        ▌▞▀▖▙▀▖▛▚▀▖▄▄▖▙▄▌▞▀▖▐ ▛▀▖▞▀▖▙▀▖
        ▌▛▀ ▌  ▌▐ ▌   ▌ ▌▛▀ ▐ ▙▄▘▛▀ ▌  
        ▘▝▀▘▘  ▘▝ ▘   ▘ ▘▝▀▘ ▘▌  ▝▀▘▘${RESET} ${MAGENTA}version 1.1.1${RESET}"
        
    echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}Author ${GREEN}:${RESET} ${BOLD}Alienkrishn ${RED}[${GREEN}Anon4You${RED}]${RESET}"
    echo -e "${BOLD}About  ${GREEN}:${RESET} ${BOLD}A simple script to learn Terminal commands${RESET}"
    echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════${RESET}"
    echo
}

# Function to display usage with better formatting
show_usage() {
    echo -e "${GREEN}${BOLD}USAGE:${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${CYAN}<query>${RESET} ${MAGENTA}[--save | -s] [filename]${RESET}"
    echo
    echo -e "${GREEN}${BOLD}EXAMPLES:${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${CYAN}python${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${CYAN}bash/:learn ${MAGENTA}--save${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${CYAN}python/:list ${MAGENTA}-s my_python_notes${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${CYAN}git ${MAGENTA}--save git_cheatsheet${RESET}"
    echo -e "  ${BOLD}${SCRIPT_NAME} ${MAGENTA}--help${RESET}"
    echo
    echo -e "${GREEN}${BOLD}ARGUMENTS:${RESET}"
    echo -e "  ${CYAN}:learn${RESET}      - Learning resources and tutorials"
    echo -e "  ${CYAN}:list${RESET}       - List available topics and subtopics"
    echo -e "  ${CYAN}:overview${RESET}   - Quick overview of a command/tool"
    echo -e "  ${CYAN}:cheat${RESET}      - Quick cheat sheet (default)"
    echo -e "  ${MAGENTA}--save, -s${RESET}  - Save output to file"
    echo -e "  ${MAGENTA}--help, -h${RESET}  - Show this help message"
    echo -e "  ${MAGENTA}--list, -l${RESET}  - Show available topics"
    echo
    echo -e "${GREEN}${BOLD}SAVE OPTIONS:${RESET}"
    echo -e "  ${MAGENTA}--save${RESET}          - Save with automatic filename"
    echo -e "  ${MAGENTA}--save filename${RESET} - Save with custom filename"
    echo -e "  ${MAGENTA}-s${RESET}              - Short form of --save"
    echo
    echo -e "${YELLOW}Files are saved to: $DEFAULT_SAVE_DIR/${RESET}"
    echo
}

# Function to generate filename from query
generate_filename() {
    local query="$1"
    # Replace special characters with underscores
    local clean_query=$(echo "$query" | sed 's/[\/:?&=%]/_/g' | sed 's/ /_/g')
    echo "${clean_query}${SAVE_EXTENSION}"
}

# Function to save content to file
save_to_file() {
    local content="$1"
    local filename="$2"
    local filepath="$DEFAULT_SAVE_DIR/$filename"
    
    echo "$content" > "$filepath"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully saved to: ${filepath}${RESET}"
        echo -e "${CYAN}File size: $(du -h "$filepath" | cut -f1)${RESET}"
    else
        echo -e "${RED}✗ Failed to save file${RESET}"
        return 1
    fi
}

# Function to fetch cheat sheet with better formatting
fetch_cheatsheet() {
    local query="$1"
    local save_output="$2"
    local custom_filename="$3"
    
    echo -e "${GREEN}Fetching cheatsheet for...${RESET} ${CYAN}${query}${RESET}" | pv -qL 15
    
    # Use curl with timeout and error handling
    echo -e "${YELLOW}${BOLD}────────────────────────────────────────────────────────${RESET}"
    
    local api_output
    if ! api_output=$(curl -s --max-time 10 "cht.sh/${query}"); then
        echo -e "${RED}Error: Failed to fetch data. Check your connection.${RESET}"
        exit 1
    fi
    
    # Display the output
    echo "$api_output"
    
    echo -e "${YELLOW}${BOLD}────────────────────────────────────────────────────────${RESET}"
    
    # Save to file if requested
    if [ "$save_output" = true ]; then
        local filename
        if [ -n "$custom_filename" ]; then
            filename="${custom_filename}${SAVE_EXTENSION}"
        else
            filename=$(generate_filename "$query")
        fi
        
        echo -e "${GREEN}Saving output to file...${RESET}" | pv -qL 10
        save_to_file "$api_output" "$filename"
    fi
}

# Function to show available topics
show_topics() {
    local save_output="$1"
    local custom_filename="$2"
    
    echo -e "${GREEN}Fetching popular topics...${RESET}" | pv -qL 15
    echo -e "${YELLOW}${BOLD}────────────────────────────────────────────────────────${RESET}"
    
    local api_output
    api_output=$(curl -s --max-time 10 "cht.sh/:list" | head -30)
    
    echo "$api_output"
    echo -e "${YELLOW}${BOLD}────────────────────────────────────────────────────────${RESET}"
    echo -e "${CYAN}Use '${SCRIPT_NAME} <topic>/:list' to see more specific topics${RESET}"
    
    # Save to file if requested
    if [ "$save_output" = true ]; then
        local filename
        if [ -n "$custom_filename" ]; then
            filename="${custom_filename}${SAVE_EXTENSION}"
        else
            filename="topics_list${SAVE_EXTENSION}"
        fi
        
        echo -e "${GREEN}Saving topics list to file...${RESET}" | pv -qL 10
        save_to_file "$api_output" "$filename"
    fi
}

# Function to parse command line arguments
parse_arguments() {
    local query=""
    local save_output=false
    local custom_filename=""
    local help_requested=false
    local list_requested=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                help_requested=true
                shift
                ;;
            --save|-s)
                save_output=true
                # Check if next argument is a filename (not another option)
                if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
                    custom_filename="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --list|-l|:list)
                list_requested=true
                shift
                ;;
            *)
                # Assume it's the query
                if [ -z "$query" ]; then
                    query="$1"
                else
                    echo -e "${RED}Error: Unexpected argument: $1${RESET}"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    echo "$help_requested $list_requested $save_output $query $custom_filename"
}

# Main execution
main() {
    check_dependencies
    create_save_dir
    
    if [[ $# -eq 0 ]]; then
        show_banner
        show_usage
        exit 0
    fi
    
    # Parse arguments
    IFS=' ' read -r help_requested list_requested save_output query custom_filename <<< "$(parse_arguments "$@")"
    
    if [ "$help_requested" = true ]; then
        show_usage
    elif [ "$list_requested" = true ]; then
        show_banner
        show_topics "$save_output" "$custom_filename"
    elif [ -n "$query" ]; then
        show_banner
        fetch_cheatsheet "$query" "$save_output" "$custom_filename"
    else
        echo -e "${RED}Error: No query provided${RESET}"
        show_usage
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
