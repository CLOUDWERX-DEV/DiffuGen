#!/bin/bash

# DiffuGen Setup Script
# Made with <3 by CLOUDWERX LAB "Digital Food for the Analog Soul"
# http://github.com/CLOUDWERX-DEV/diffugen
# http://cloudwerx.dev
# !! Open-Source !!

# Define ANSI art with heredoc for safe inclusion
read -r -d '' ANSI_LOGO << 'ENDOFANSI'
\e[49m \e[38;5;232;49m▄\e[38;5;233;49m▄\e[38;5;233;48;5;232m▄\e[38;5;233;48;5;233m▄\e[48;5;233m \e[38;5;233;48;5;233m▄▄▄▄▄▄▄▄▄\e[48;5;233m  \e[38;5;233;48;5;233m▄▄▄▄▄\e[38;5;233;49m▄▄\e[49m \e[m
\e[38;5;233;49m▄\e[38;5;233;48;5;233m▄▄\e[38;5;203;48;5;233m▄\e[38;5;203;48;5;167m▄\e[38;5;203;48;5;203m▄\e[38;5;209;48;5;209m▄▄▄▄\e[38;5;215;48;5;209m▄\e[38;5;215;48;5;215m▄▄\e[38;5;216;48;5;216m▄▄\e[38;5;216;48;5;222m▄\e[38;5;215;48;5;222m▄\e[38;5;215;48;5;215m▄▄▄▄\e[38;5;221;48;5;233m▄\e[38;5;233;48;5;233m▄▄\e[38;5;233;49m▄\e[m
\e[38;5;233;48;5;233m▄\e[38;5;234;48;5;234m▄\e[38;5;203;48;5;167m▄\e[38;5;203;48;5;203m▄▄▄\e[38;5;209;48;5;209m▄▄▄▄\e[38;5;215;48;5;215m▄▄\e[38;5;215;48;5;216m▄\e[38;5;215;48;5;215m▄▄▄▄▄▄▄▄▄\e[38;5;215;48;5;179m▄\e[38;5;234;48;5;233m▄\e[38;5;233;48;5;233m▄\e[m
\e[38;5;233;48;5;233m▄\e[38;5;233;48;5;234m▄\e[38;5;203;48;5;203m▄▄▄▄\e[38;5;209;48;5;209m▄▄▄▄\e[38;5;131;48;5;215m▄\e[38;5;235;48;5;209m▄\e[38;5;234;48;5;137m▄\e[38;5;235;48;5;215m▄\e[38;5;137;48;5;215m▄\e[38;5;215;48;5;215m▄▄▄▄▄▄▄▄\e[48;5;234m \e[48;5;233m \e[m
\e[48;5;233m  \e[38;5;203;48;5;203m▄▄▄▄\e[38;5;203;48;5;209m▄\e[38;5;237;48;5;209m▄\e[38;5;235;48;5;131m▄\e[38;5;234;48;5;236m▄\e[38;5;233;48;5;234m▄\e[38;5;0;48;5;234m▄\e[49;38;5;233m▀\e[38;5;0;48;5;234m▄\e[38;5;233;48;5;234m▄\e[38;5;234;48;5;238m▄\e[38;5;235;48;5;137m▄\e[38;5;94;48;5;215m▄\e[38;5;215;48;5;215m▄▄▄▄▄\e[38;5;233;48;5;234m▄\e[38;5;233;48;5;233m▄\e[m
\e[48;5;233m \e[38;5;233;48;5;233m▄\e[38;5;167;48;5;203m▄▄\e[38;5;168;48;5;203m▄\e[38;5;168;48;5;167m▄\e[38;5;168;48;5;168m▄\e[38;5;235;48;5;235m▄\e[48;5;233m \e[49;38;5;0m▀\e[38;5;233;49m▄\e[38;5;237;48;5;232m▄\e[38;5;24;48;5;232m▄\e[38;5;23;48;5;232m▄\e[38;5;233;49m▄\e[49;38;5;233m▀\e[48;5;234m \e[38;5;236;48;5;236m▄\e[38;5;215;48;5;215m▄▄▄▄▄\e[48;5;233m \e[38;5;233;48;5;233m▄\e[m
\e[48;5;233m  \e[38;5;161;48;5;161m▄\e[38;5;162;48;5;168m▄\e[38;5;168;48;5;168m▄▄▄\e[38;5;235;48;5;235m▄\e[48;5;233m \e[48;5;232m \e[38;5;237;48;5;237m▄\e[38;5;132;48;5;96m▄\e[38;5;96;48;5;61m▄\e[38;5;67;48;5;31m▄\e[38;5;236;48;5;236m▄\e[48;5;0m \e[48;5;234m \e[38;5;236;48;5;236m▄\e[38;5;215;48;5;215m▄▄▄\e[38;5;179;48;5;215m▄\e[38;5;144;48;5;215m▄\e[48;5;233m  \e[m
\e[38;5;233;48;5;233m▄\e[48;5;233m \e[38;5;161;48;5;161m▄▄\e[38;5;161;48;5;168m▄\e[38;5;168;48;5;168m▄▄\e[38;5;235;48;5;235m▄\e[38;5;233;48;5;233m▄\e[38;5;232;49m▄\e[49;38;5;233m▀\e[38;5;233;48;5;89m▄\e[38;5;234;48;5;96m▄\e[38;5;233;48;5;238m▄\e[49;38;5;233m▀\e[38;5;232;49m▄\e[38;5;234;48;5;234m▄\e[38;5;236;48;5;236m▄\e[38;5;173;48;5;209m▄\e[38;5;102;48;5;215m▄\e[38;5;73;48;5;179m▄\e[38;5;38;48;5;73m▄\e[38;5;38;48;5;38m▄\e[38;5;233;48;5;233m▄▄\e[m
\e[38;5;233;48;5;233m▄\e[48;5;233m \e[38;5;161;48;5;161m▄▄▄\e[38;5;167;48;5;167m▄\e[38;5;168;48;5;168m▄\e[38;5;168;48;5;89m▄\e[38;5;131;48;5;234m▄\e[38;5;236;48;5;234m▄\e[38;5;234;48;5;233m▄\e[38;5;233;49m▄\e[38;5;232;49m▄\e[38;5;233;49m▄\e[38;5;233;48;5;232m▄\e[38;5;235;48;5;233m▄\e[38;5;60;48;5;234m▄\e[38;5;67;48;5;239m▄\e[38;5;67;48;5;67m▄▄\e[38;5;67;48;5;37m▄\e[38;5;73;48;5;37m▄\e[38;5;37;48;5;37m▄\e[38;5;233;48;5;233m▄\e[48;5;233m \e[m
\e[38;5;233;48;5;233m▄▄\e[38;5;161;48;5;161m▄▄▄▄\e[38;5;161;48;5;167m▄\e[38;5;167;48;5;168m▄\e[38;5;168;48;5;168m▄\e[38;5;132;48;5;132m▄\e[38;5;132;48;5;239m▄\e[38;5;96;48;5;235m▄\e[38;5;240;48;5;234m▄\e[38;5;60;48;5;235m▄\e[38;5;61;48;5;237m▄\e[38;5;61;48;5;61m▄▄\e[38;5;61;48;5;67m▄\e[38;5;67;48;5;67m▄▄▄▄\e[38;5;67;48;5;31m▄\e[38;5;233;48;5;233m▄▄\e[m
\e[38;5;233;48;5;233m▄▄\e[38;5;233;48;5;125m▄\e[38;5;161;48;5;161m▄▄▄▄▄\e[38;5;162;48;5;168m▄\e[38;5;132;48;5;132m▄▄\e[38;5;96;48;5;96m▄\e[38;5;96;48;5;97m▄\e[38;5;97;48;5;61m▄\e[38;5;61;48;5;61m▄▄▄▄▄\e[38;5;61;48;5;67m▄▄▄\e[38;5;233;48;5;61m▄\e[38;5;233;48;5;233m▄▄\e[m
\e[49m \e[38;5;232;48;5;233m▄\e[38;5;233;48;5;233m▄▄\e[38;5;233;48;5;161m▄▄▄▄▄\e[38;5;233;48;5;126m▄\e[38;5;233;48;5;132m▄\e[38;5;233;48;5;96m▄▄\e[38;5;233;48;5;60m▄\e[38;5;233;48;5;61m▄▄▄▄▄▄▄\e[38;5;233;48;5;233m▄▄\e[38;5;232;48;5;233m▄\e[49m \e[m
\e[49m  \e[49;38;5;0m▀\e[49;38;5;233m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\e[49m  \e[m
ENDOFANSI

# Initialize global variables for operation tracking and error handling
initialize_globals() {
    # Critical operation tracking
    IN_CRITICAL_OPERATION=false
    CURRENT_OPERATION=""
    
    # Current download tracking
    current_model_name=""
    current_download_file=""
    
    # Session resources tracking
    TEMP_FILES_CREATED_THIS_SESSION=()
    VENV_CREATED_THIS_SESSION=false
    
    # Track if the menu has been displayed
    MENU_DISPLAYED=""
}

# This function should be called early in the script
initialize_globals

# Global variables for tracking downloads
current_model_name=""
current_download_file=""

# Session tracking variables - track what was created in this session
VENV_CREATED_THIS_SESSION=false
TEMP_FILES_CREATED_THIS_SESSION=()
CURRENT_OPERATION=""

# Function for updating the critical operation flag
set_critical_operation() {
    local state=$1
    local operation_type="${2:-generic}"
    IN_CRITICAL_OPERATION=$state
    
    if [ "$state" = true ]; then
        CURRENT_OPERATION="$operation_type"
    else
        CURRENT_OPERATION=""
    fi
}

# Enhanced color definitions
RED='\033[0;31m'
BOLD_RED='\033[1;31m'
GREEN='\033[0;32m'
BOLD_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
BOLD_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
BOLD_CYAN='\033[1;36m'
WHITE='\033[1;37m'
BLACK_BG='\033[40m'
RED_BG='\033[41m'
GREEN_BG='\033[42m'
YELLOW_BG='\033[43m'
BLUE_BG='\033[44m'
PURPLE_BG='\033[45m'
CYAN_BG='\033[46m'
NC='\033[0m' # No Color

# Function for animated text
animate_text() {
    local text="$1"
    local color="${!2}"
    local delay=0.02
    
    echo -ne "${color}"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo -e "${NC}"
}

# Function for spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='.O.O'
    
    echo -ne "${PURPLE}"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -ne "\r"
        sleep $delay
    done
    echo -ne "${NC}\r"
    printf "    \r"
}

# Enhanced progress bar with animated filling
progress_bar() {
    local total_duration=$1
    local steps=$2
    local message="$3"
    local start_time=$(date +%s)
    local sleep_duration=$(bc <<< "scale=4; $total_duration / $steps")
    
    echo -e "${YELLOW}$message${NC}"
    
    for ((i=0; i<=$steps; i++)); do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local estimated_total=$((elapsed * steps / (i+1)))
        local remaining=$((estimated_total - elapsed))
        
        # Avoid division by zero
        if [ $i -eq 0 ]; then
            remaining=$total_duration
        fi
        
        local percent=$((i*100/steps))
        local filled=$((i*50/steps))
        local empty=$((50-filled))
        
        echo -ne "${BOLD_GREEN}["
        for ((j=0; j<filled; j++)); do
            echo -ne "█"
        done
        
        if [ $filled -lt 50 ]; then
            echo -ne "${YELLOW}>"
            for ((j=0; j<empty-1; j++)); do
                echo -ne " "
            done
        fi
        
        echo -ne "${BOLD_GREEN}] ${WHITE}${percent}%${NC} "
        
        if [ $remaining -gt 60 ]; then
            echo -ne "(Est: $(($remaining/60))m $(($remaining%60))s)  \r"
        else
            echo -ne "(Est: ${remaining}s)  \r"
        fi
        
        sleep $sleep_duration
    done
    echo -e "\n${BOLD_GREEN}✓ Complete!${NC}"
}

# Function to draw a box around text
box() {
    local text="$1"
    local color="${!2}"
    local width=$((${#text} + 4))
    
    echo -ne "${color}"
    echo -n "┌"
    for ((i=0; i<width; i++)); do echo -n "─"; done
    echo "┐"
    
    echo -n "│  ${text}  │"
    echo
    
    echo -n "└"
    for ((i=0; i<width; i++)); do echo -n "─"; done
    echo -e "┘${NC}"
}

# Enhanced ASCII Art Logo with animation
display_logo() {
    clear
    echo
    animate_text "Loading DiffuGen Setup... Hang Tight!" "BOLD_PURPLE"
    progress_bar 2 20 "Initializing Setup..."
    clear
    
    echo -e "${YELLOW_BG}"
    echo -e "                                         ${BOLD_PURPLE} {´◕ ◡ ◕｀}                                               "
    echo -e "                                  ${BOLD_PURPLE}[ DiffuGen Setup Utility ]                                       "
    echo -e "${NC}"
    # Display the ANSI art logo centered
    # Calculate terminal width for centering
    TERM_WIDTH=$(tput cols)
    # The ANSI art is approximately 80 columns wide
    ANSI_WIDTH=25
    # Calculate padding needed to center the ANSI art
    PADDING=$(( (TERM_WIDTH - ANSI_WIDTH) / 5 ))

    # Apply padding by adding spaces before each line of the ANSI art
    if [ $PADDING -gt 0 ]; then
        echo -e "$ANSI_LOGO" | sed "s/^/$(printf '%*s' $PADDING '')/g"
    else
        # If terminal is too narrow, just display without centering
        echo -e "$ANSI_LOGO"
    fi
    
echo -e "${BOLD_PURPLE}"   
            echo  "              ______ ________________ _______          _______________       "
            sleep 0.1
            echo "              (  __  \\__   __(  ____ (  ____ \\       /( ____ (  ____ ( (     /|"
            sleep 0.1
            echo -e "${YELLOW}              | (  \  )  ) (  | (    \/ (    \/ )   ( | (    \/ (    \/  \  ( |"
            echo "              | |   ) |  | |  | (__   | (__   | |   | | |     | (__   |   \ | |"
            sleep 0.1
            echo "              | |   | |  | |  |  __)  |  __)  | |   | | | ____|  __)  | (\ \) |"
            sleep 0.1
            echo "              | |   ) |  | |  | (     | (     | |   | | | \_  ) (     | | \   |"
            sleep 0.1
            echo -e "${BOLD_PURPLE}              | (__/  )__) (__| )     | )     | (___) | (___) | (____/\ )  \  |"
            sleep 0.1
            echo "              (______/\_______//      |/      (_______|_______|_______//    )_)"
            echo -e "${NC}"


    
   box "Advanced Stable Diffusion Image Generator Designed For MCP Tool Usage & CLI Image Generation" "BOLD_PURPLE"
   animate_text "Made with ❤️  by CLOUDWERX LAB - VIsit us at http://cloudwerx.dev | http://github.com/CLOUDWERX-DEV" "BOLD_YELLOW"

echo -e  -------------------------------  "${BOLD_CYAN}\"${BOLD_GREEN}Digital Food "${WHITE}"for the ${BOLD_PURPLE}Analog Soul${BOLD_CYAN}\"${NC}"  -------------------------------
    echo
    
    # Draw a decorative line
    echo -ne "${YELLOW}"
    for ((i=0; i<98; i++)); do
        echo -n "═"
        sleep 0.005
    done
    echo -e "${NC}"
    echo
}

# Enhanced colored text function
print_color() {
    local color_name=$1
    local text=$2
    local style=$3
    
    case $style in
        "header")
            # Create the decorative header with horizontal lines and the text in the middle
            local line_char="═"
            local left_char="╔"
            local right_char="╗"
            local line_length=70
            
            echo -e "\n${!color_name}${left_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char} ${YELLOW}${text} ${!color_name}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${right_char}${NC}\n"
            ;;
        "subheader")
            # Create the decorative subheader with horizontal lines and the text in the middle
            local line_char="─"
            local left_char="┌"
            local right_char="┐"
            local line_length=65
            
            echo -e "\n${!color_name}${left_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char} ${YELLOW}${text} ${!color_name}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${right_char}${NC}\n"
            ;;
        "success")
            echo -e "${BOLD_GREEN}✓ ${!color_name}${text}${NC}"
            ;;
        "warning")
            echo -e "${BOLD_YELLOW}⚠ ${!color_name}${text}${NC}"
            ;;
        "error")
            echo -e "${BOLD_RED}✗ ${!color_name}${text}${NC}"
            ;;
        "info")
            echo -e "${BOLD_BLUE}ℹ ${!color_name}${text}${NC}"
            ;;
        "bullet")
            echo -e "${BOLD_PURPLE}• ${!color_name}${text}${NC}"
            ;;
        "model")
            echo -e "${!color_name}${text}"
            ;;
        *)
            echo -e "${!color_name}${text}${NC}"
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run sudo commands with proper password masking
run_sudo_command() {
    local cmd="$1"
    local msg="${2:-Running command with elevated privileges...}"
    
    # Check if we already have sudo privileges
    if sudo -n true 2>/dev/null; then
        print_color "BLUE" "Using existing sudo privileges" "info"
        eval "sudo $cmd" &
        spinner $!
        return $?
    fi
    
    # We need to ask for password
    print_color "YELLOW" "$msg" "info"
    print_color "CYAN" "Please enter your password when prompted" "info"
    
    # Use -S to read password from stdin
    echo -e "${BOLD_CYAN}[sudo] password for $USER: ${NC}"
    sudo -S eval "$cmd" 2>/dev/null &
    local pid=$!
    
    # Show spinner while command is running
    spinner $pid
    return $?
}

# Function to detect OS with fancy output
detect_os() {
    print_color "BOLD_BLUE" "Detecting operating system..." "info"
    sleep 0.5
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || grep -q 'ID_LIKE="ubuntu debian"' /etc/os-release 2>/dev/null || grep -q 'ID_LIKE=debian' /etc/os-release 2>/dev/null || grep -q 'ID=linuxmint' /etc/os-release 2>/dev/null; then
            print_color "BOLD_GREEN" "Detected Debian/Ubuntu based system" "success"
            echo "debian"
        elif [ -f /etc/arch-release ] || grep -q 'ID=arch' /etc/os-release 2>/dev/null; then
            print_color "BOLD_GREEN" "Detected Arch Linux based system" "success"
            echo "arch"
        elif [ -f /etc/fedora-release ] || grep -q 'ID=fedora' /etc/os-release 2>/dev/null; then
            print_color "BOLD_GREEN" "Detected Fedora based system" "success"
            echo "fedora"
        else
            print_color "BOLD_GREEN" "Detected other Linux distribution" "success"
            echo "linux-other"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_color "BOLD_GREEN" "Detected macOS system" "success"
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
        print_color "BOLD_GREEN" "Detected Windows system" "success"
        echo "windows"
    else
        print_color "BOLD_YELLOW" "Unknown operating system" "warning"
        echo "unknown"
    fi
}

# Function to install dependencies based on OS with enhanced visuals
install_dependencies() {
    local os_type=$(detect_os)
    local deps=("git" "cmake" "make" "g++" "curl" "python3" "python3-venv" "pip")
    
    print_color "BOLD_CYAN" "Preparing to install dependencies" "header"
    
    case $os_type in
        debian)
            print_color "YELLOW" "Installing dependencies for Debian/Ubuntu..." "subheader"
            echo -ne "${BOLD_CYAN}"
            echo "The following packages will be installed:"
            echo -ne "${BOLD_GREEN}"
            echo "  • git: Version control system"
            echo "  • cmake: Build system generator"
            echo "  • make: Build automation tool"
            echo "  • g++: C++ compiler"
            echo "  • curl: Command line tool for transferring data"
            echo "  • python3: Python programming language"
            echo "  • python3-venv: Python virtual environment"
            echo "  • python3-pip: Python package installer"
            echo "  • bc: Command line calculator"
            echo -e "${NC}"
            
            echo -e "${YELLOW}Updating package lists...${NC}"
            run_sudo_command "apt-get update" "Updating package lists..."
            
            echo -e "${YELLOW}Installing packages...${NC}"
            run_sudo_command "apt-get install -y git cmake make g++ curl python3 python3-venv python3-pip bc" "Installing packages..."
            
            print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            ;;
        arch)
            print_color "YELLOW" "Installing dependencies for Arch Linux..." "subheader"
            run_sudo_command "pacman -Sy git cmake make gcc curl python python-pip bc" "Installing packages for Arch Linux..."
            print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            ;;
        fedora)
            print_color "YELLOW" "Installing dependencies for Fedora..." "subheader"
            run_sudo_command "dnf install -y git cmake make gcc-c++ curl python3 python3-pip bc" "Installing packages for Fedora..."
            print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            ;;
        macos)
            print_color "YELLOW" "Installing dependencies for macOS..." "subheader"
            if ! command_exists brew; then
                print_color "RED" "Homebrew not found. Installing Homebrew..." "info"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &
                spinner $!
            fi
            brew install git cmake make gcc curl python3 bc &
            spinner $!
            print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            ;;
        windows)
            print_color "YELLOW" "Setting up for Windows..." "subheader"
            if command_exists wsl; then
                print_color "GREEN" "WSL detected. Using WSL for setup." "success"
                wsl_setup
                return
            elif command_exists powershell; then
                print_color "YELLOW" "Using PowerShell to install dependencies..." "info"
                powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" &
                spinner $!
                powershell -Command "choco install -y git cmake make python curl" &
                spinner $!
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            else
                print_color "RED" "PowerShell not found. Cannot proceed with Windows setup." "error"
                exit 1
            fi
            ;;
        linux-other)
            print_color "YELLOW" "Attempting to install dependencies for your Linux distribution..." "subheader"
            if command_exists apt-get; then
                print_color "YELLOW" "Detected apt-get package manager, using Debian/Ubuntu method..." "info"
                echo -ne "${BOLD_CYAN}"
                echo "The following packages will be installed:"
                echo -ne "${BOLD_GREEN}"
                echo "  • git: Version control system"
                echo "  • cmake: Build system generator"
                echo "  • make: Build automation tool"
                echo "  • g++: C++ compiler"
                echo "  • curl: Command line tool for transferring data"
                echo "  • python3: Python programming language"
                echo "  • python3-venv: Python virtual environment"
                echo "  • python3-pip: Python package installer"
                echo "  • bc: Command line calculator"
                echo -e "${NC}"
                
                echo -e "${YELLOW}Updating package lists...${NC}"
                run_sudo_command "apt-get update" "Updating package lists..."
                
                echo -e "${YELLOW}Installing packages...${NC}"
                run_sudo_command "apt-get install -y git cmake make g++ curl python3 python3-venv python3-pip bc" "Installing packages..."
                
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            elif command_exists dnf; then
                print_color "YELLOW" "Detected dnf package manager, using Fedora method..." "info"
                run_sudo_command "dnf install -y git cmake make gcc-c++ curl python3 python3-pip bc" "Installing packages for Fedora..."
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            elif command_exists pacman; then
                print_color "YELLOW" "Detected pacman package manager, using Arch method..." "info"
                run_sudo_command "pacman -Sy git cmake make gcc curl python python-pip bc" "Installing packages for Arch Linux..."
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            else
                print_color "RED" "Unsupported OS. Please install dependencies manually." "error"
                print_color "YELLOW" "You will need to install: git, cmake, make, g++, curl, python3, python3-venv, python3-pip, and bc" "info"
                exit 1
            fi
            ;;
        *)
            # Try to detect package manager for unknown OS
            if command_exists apt-get; then
                print_color "YELLOW" "Detected apt-get package manager, trying Debian/Ubuntu method..." "info"
                run_sudo_command "apt-get update" "Updating package lists..."
                run_sudo_command "apt-get install -y git cmake make g++ curl python3 python3-venv python3-pip bc" "Installing packages..."
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            elif command_exists dnf; then
                print_color "YELLOW" "Detected dnf package manager, trying Fedora method..." "info"
                run_sudo_command "dnf install -y git cmake make gcc-c++ curl python3 python3-pip bc" "Installing packages for Fedora..."
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            elif command_exists pacman; then
                print_color "YELLOW" "Detected pacman package manager, trying Arch method..." "info"
                run_sudo_command "pacman -Sy git cmake make gcc curl python python-pip bc" "Installing packages for Arch Linux..."
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            else
                print_color "RED" "Unsupported OS. Please install dependencies manually." "error"
                print_color "YELLOW" "You will need to install: git, cmake, make, g++, curl, python3, python3-venv, python3-pip, and bc" "info"
            exit 1
            fi
            ;;
    esac
}

# Function for WSL setup
wsl_setup() {
    print_color "YELLOW" "Setting up in WSL environment..." "info"
    wsl bash -c "$(cat $0)"
    exit 0
}

# Function to clean up on failure with enhanced visuals
cleanup() {
    echo
    print_color "PURPLE_BG" "                                                " ""
    print_color "PURPLE_BG" "  ⚠️  ERROR RECOVERY - CLEANUP PROCESS STARTED   " ""
    print_color "PURPLE_BG" "                                                " ""
    echo
    
    local error_message="$1"
    local error_type="${2:-unknown}"
    
    # Print a more helpful error message
    if [ -n "$error_message" ]; then
        print_color "BOLD_RED" "Error details: $error_message" "error"
        echo
    fi
    
    # Create an array to track what was cleaned up
    local cleaned_items=()
    
    # Only handle current download if we were actually downloading
    if [ "$CURRENT_OPERATION" = "download" ] && [ -n "$current_download_file" ] && [ -n "$current_model_name" ]; then
        print_color "BOLD_YELLOW" "Detected interrupted download: '$current_model_name'" "warning"
        if [ -f "$current_download_file" ]; then
            print_color "YELLOW" "Found a partial download file that may be incomplete or corrupted." "info"
            echo -e "${BOLD_WHITE}Path: ${CYAN}$current_download_file${NC}"
            
            # Get file size in a human-readable format
            local file_size=$(du -h "$current_download_file" 2>/dev/null | cut -f1)
            if [ -n "$file_size" ]; then
                echo -e "${BOLD_WHITE}Current partial size: ${CYAN}$file_size${NC}"
            fi
            
            echo
            read -p "$(echo -e ${BOLD_YELLOW}Would you like to remove this incomplete download file? \(y/n\)${NC} )" -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                print_color "YELLOW" "Removing incomplete download: $current_download_file" "info"
                rm -f "$current_download_file" 
                if [ ! -f "$current_download_file" ]; then
                    print_color "BOLD_GREEN" "✓ Incomplete download file removed successfully" "success"
                    cleaned_items+=("Incomplete download of $current_model_name")
            else
                    print_color "BOLD_RED" "✗ Failed to remove the incomplete download file" "error"
            fi
        else
                print_color "YELLOW" "Keeping incomplete download file. You can try to resume the download later." "info"
        fi
    else
            print_color "YELLOW" "No download file found at expected location: $current_download_file" "info"
        fi
    else
        # More targeted cleanup based on operation type
        local has_temp_files=false
        local has_venv=false
        local items_to_clean=()
        
        # Determine what should be cleaned based on operation type and session state
        print_color "BOLD_YELLOW" "Analyzing what needs to be cleaned up..." "info"
        echo
        
        # Only offer to clean venv if it was created in this session
        if [ "$CURRENT_OPERATION" = "python" ] && [ "$VENV_CREATED_THIS_SESSION" = true ] && [ -d "diffugen_env" ]; then
            has_venv=true
            items_to_clean+=("Python virtual environment (created in current session)")
        fi
        
        # Check for temporary download files from this session
        if [ "$CURRENT_OPERATION" = "download" ]; then
            local temp_files=(/tmp/diffugen_download_*.part)
            if [ -e "${temp_files[0]}" ]; then
                has_temp_files=true
                items_to_clean+=("Temporary download files in /tmp")
            fi
        fi
        
        # If nothing to clean, inform the user
        if [ ${#items_to_clean[@]} -eq 0 ]; then
            echo -e "${BOLD_GREEN}No items need to be cleaned up from the current operation.${NC}"
            echo
        else
            print_color "YELLOW" "The following items from your current session may need cleanup:" "warning"
            echo
            read -p "$(echo -e ${BOLD_YELLOW}Remove the items above? \(y/n\)${NC} )" -n 1 -r
            echo
            
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
                
                # Remove Python virtual environment if it exists
                if [ "$has_venv" = true ]; then
                print_color "YELLOW" "Removing Python virtual environment..." "info"
                    rm -rf diffugen_env
                    
                    if [ ! -d "diffugen_env" ]; then
                        print_color "BOLD_GREEN" "✓ Virtual environment removed successfully" "success"
                        cleaned_items+=("Python virtual environment")
                    else
                        print_color "BOLD_RED" "✗ Failed to remove the virtual environment" "error"
                    fi
                fi
                
                # Remove temporary download files if they exist
                if [ "$has_temp_files" = true ]; then
            print_color "YELLOW" "Removing temporary download files..." "info"
                    rm -f /tmp/diffugen_download_*.part
                    
                    # Verify cleanup
                    local remaining_files=(/tmp/diffugen_download_*.part)
                    if [ ! -e "${remaining_files[0]}" ]; then
                        print_color "BOLD_GREEN" "✓ Temporary files removed successfully" "success"
                        cleaned_items+=("Temporary download files")
                    else
                        print_color "BOLD_RED" "✗ Failed to remove some temporary files" "error"
                    fi
                fi
                
                print_color "BOLD_GREEN" "Cleanup completed!" "success"
        else
            print_color "YELLOW" "Skipping cleanup as requested." "info"
            fi
        fi
    fi
    
    # Provide guidance based on the error type
    echo
    print_color "BOLD_PURPLE" "────── TROUBLESHOOTING GUIDANCE ──────" ""
    echo
    
    case "$error_type" in
        "download")
            print_color "YELLOW" "The error appears to be related to downloading models:" "warning"
            echo -e "${BOLD_WHITE}• Check your internet connection"
            echo -e "${BOLD_WHITE}• Verify the model URL is accessible"
            echo -e "${BOLD_WHITE}• Make sure you have sufficient disk space"
            echo -e "${BOLD_WHITE}• Try downloading with a different network if possible"
            ;;
        "build")
            print_color "YELLOW" "The error appears to be related to building stable-diffusion.cpp:" "warning"
            echo -e "${BOLD_WHITE}• Make sure you have all required build dependencies installed"
            echo -e "${BOLD_WHITE}• Check for compiler errors in the output above"
            echo -e "${BOLD_WHITE}• Verify you have sufficient disk space and memory"
            echo -e "${BOLD_WHITE}• For CUDA issues, verify your CUDA installation is working correctly"
            ;;
        "python")
            print_color "YELLOW" "The error appears to be related to Python setup:" "warning"
            echo -e "${BOLD_WHITE}• Verify Python 3.x is correctly installed on your system"
            echo -e "${BOLD_WHITE}• Make sure pip is installed and up to date"
            echo -e "${BOLD_WHITE}• Check that you have permissions to create virtual environments"
            ;;
        "permissions")
            print_color "YELLOW" "The error appears to be related to file permissions:" "warning"
            echo -e "${BOLD_WHITE}• Run the script with appropriate permissions"
            echo -e "${BOLD_WHITE}• Make sure you have write access to the install directory"
            echo -e "${BOLD_WHITE}• Check if any files are locked by other processes"
            ;;
        *)
            print_color "YELLOW" "To resolve the issue:" "warning"
            echo -e "${BOLD_WHITE}• Review the error message above for specific details"
            echo -e "${BOLD_WHITE}• Make sure all prerequisites are installed"
            echo -e "${BOLD_WHITE}• Verify you have a stable internet connection"
            echo -e "${BOLD_WHITE}• Check that you have sufficient disk space"
            ;;
    esac
    
    echo
    print_color "BOLD_GREEN" "Cleaned up items:" "success"
    if [ ${#cleaned_items[@]} -eq 0 ]; then
        echo -e "${BOLD_WHITE}None${NC}"
    else
        for item in "${cleaned_items[@]}"; do
            echo -e "${BOLD_WHITE}• ${CYAN}$item${NC}"
        done
    fi
    
    echo
    print_color "BOLD_BLUE" "Next steps:" "info"
    echo -e "${BOLD_WHITE}1. Address the issues mentioned above"
    echo -e "${BOLD_WHITE}2. Run the script again to complete the installation"
    echo -e "${BOLD_WHITE}3. For additional help, visit: ${CYAN}https://github.com/CLOUDWERX-DEV/diffugen/issues${NC}"
    echo
    
    exit 1
}

# Error handling wrapper with enhanced visuals
run_with_error_handling() {
    local cmd_description=$1
    local error_type=$2
    shift 2
    
    echo
    print_color "BOLD_BLUE" "Starting: $cmd_description" "header"
    
    # Determine the operation type based on the command description
    local operation_type="generic"
    if [[ "$cmd_description" == *"dependencies"* ]]; then
        operation_type="dependencies"
    elif [[ "$cmd_description" == *"stable-diffusion.cpp"* ]]; then
        operation_type="build"
    elif [[ "$cmd_description" == *"Python"* || "$cmd_description" == *"virtual environment"* ]]; then
        operation_type="python"
    elif [[ "$cmd_description" == *"models"* || "$cmd_description" == *"download"* ]]; then
        operation_type="download"
    elif [[ "$cmd_description" == *"configuration"* || "$cmd_description" == *"file paths"* ]]; then
        operation_type="configuration"
    fi
    
    # Set the critical operation flag to true with the determined type
    set_critical_operation true "$operation_type"
    
    if ! "$@"; then
        local error_message="Failed during: $cmd_description"
        
        # Determine error type if not provided
        if [ -z "$error_type" ]; then
            case "$operation_type" in
                "dependencies")
                    error_type="dependencies"
                    ;;
                "build")
                    error_type="build"
                    ;;
                "python")
                    error_type="python"
                    ;;
                "download")
                    error_type="download"
                    ;;
                "configuration")
                    error_type="permissions"
                    ;;
                *)
                    error_type="unknown"
                    ;;
            esac
        fi
        
        # Reset the critical operation flag before cleanup
        set_critical_operation false
        
        cleanup "$error_message" "$error_type"
    fi
    
    # Reset the critical operation flag
    set_critical_operation false
    
    print_color "BOLD_GREEN" "Completed: $cmd_description" "success"
}

# Function to clone or update stable-diffusion.cpp with enhanced visuals
setup_stable_diffusion_cpp() {
    if [ -d "stable-diffusion.cpp" ]; then
        print_color "YELLOW" "stable-diffusion.cpp directory already exists." "info"
        read -p "$(echo -e ${BOLD_CYAN}Would you like to update it? \(y/n\)${NC} )" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color "BLUE" "Updating stable-diffusion.cpp repository..." "info"
            (cd stable-diffusion.cpp && git pull origin master && git submodule init && git submodule update) &
            spinner $!
            print_color "BOLD_GREEN" "Repository updated successfully!" "success"
        else
            print_color "YELLOW" "Skipping update as requested." "info"
        fi
    else
        print_color "BLUE" "Cloning stable-diffusion.cpp..." "info"
        echo -e "${BOLD_CYAN}This may take a few minutes depending on your internet connection.${NC}"
        echo
        git clone --recursive https://github.com/leejet/stable-diffusion.cpp &
        spinner $!
        
        if [ -d "stable-diffusion.cpp" ]; then
            print_color "BOLD_GREEN" "Repository cloned successfully!" "success"
        else
            print_color "BOLD_RED" "Failed to clone repository." "error"
            return 1
        fi
    fi
    return 0
}

# Function to build stable-diffusion.cpp
build_stable_diffusion_cpp() {
    cd stable-diffusion.cpp || return 1
    print_color "PURPLE" "Building stable-diffusion.cpp..." "subheader"
    mkdir -p build && cd build || return 1
    
    # Check if CUDA is available
    local cuda_available=false
    if command_exists nvcc; then
        cuda_version=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        print_color "YELLOW" "CUDA compiler (nvcc) found, version: $cuda_version" "success"
        cuda_available=true
    else
        print_color "YELLOW" "CUDA compiler (nvcc) not found in PATH." "warning"
        
        # Check common CUDA installation locations
        if [ -f "/usr/local/cuda/bin/nvcc" ]; then
            print_color "YELLOW" "CUDA found at /usr/local/cuda but not in PATH." "info"
            print_color "YELLOW" "You may need to add CUDA to your PATH:" "info"
            echo -e "${BOLD_CYAN}  export PATH=/usr/local/cuda/bin:\$PATH${NC}"
            cuda_available=true
        elif [ -d "/usr/local/cuda" ]; then
            print_color "YELLOW" "CUDA directory found at /usr/local/cuda but nvcc not found." "warning"
            print_color "YELLOW" "You may need to install CUDA development tools." "info"
        fi
    fi
    
    echo
    echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
    echo -e "│ ${YELLOW}CUDA Configuration${BOLD_CYAN}                               │"
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    echo
    read -p "$(echo -e ${BOLD_GREEN}Build Stable-Diffusion.cpp with CUDA support? \(y/n\)${NC} )" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$cuda_available" = false ]; then
            print_color "YELLOW" "Warning: CUDA compiler not detected, but attempting CUDA build anyway." "warning"
            echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
            echo -e "│ ${YELLOW}CUDA Troubleshooting Guide${BOLD_YELLOW}                     │"
            echo -e "└─────────────────────────────────────────────────────────┘${NC}"
            echo
            print_color "YELLOW" "If build fails, you may need to:" "bullet"
            echo -e "${BOLD_PURPLE}  1. ${YELLOW}Install CUDA toolkit ${CYAN}(https://developer.nvidia.com/cuda-downloads)${NC}"
            echo -e "${BOLD_PURPLE}  2. ${YELLOW}Make sure nvcc is in your PATH${NC}"
            echo -e "${BOLD_PURPLE}  3. ${YELLOW}Set CUDACXX environment variable to point to nvcc${NC}"
            echo -e "${BOLD_PURPLE}  4. ${YELLOW}Try building without CUDA support instead${NC}"
            echo
            read -p "$(echo -e ${BOLD_YELLOW}Continue with CUDA build attempt? \(y/n\)${NC} )" -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_color "BLUE" "Switching to non-CUDA build..." "info"
                
                # Show a spinner during cmake configuration
                echo -e "${YELLOW}Configuring build without CUDA...${NC}"
                cmake .. -DCMAKE_BUILD_TYPE=Release > cmake_output.log 2>&1 &
                spinner $!
                
                if [ $? -ne 0 ]; then
                    print_color "RED" "CMake configuration failed. Check cmake_output.log for details." "error"
                    return 1
                fi
            else
                # Try to find CUDA and set environment variables
                if [ -f "/usr/local/cuda/bin/nvcc" ]; then
                    print_color "BLUE" "Setting CUDACXX environment variable..." "info"
                    export CUDACXX="/usr/local/cuda/bin/nvcc"
                    export PATH="/usr/local/cuda/bin:$PATH"
                    print_color "GREEN" "Environment variables set successfully!" "success"
                fi
                
                echo -e "${YELLOW}Configuring build with CUDA...${NC}"
                cmake .. -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON > cmake_output.log 2>&1 &
                spinner $!
                
                if [ $? -ne 0 ]; then
                    print_color "RED" "CMake configuration failed. Check cmake_output.log for details." "error"
                    return 1
                fi
            fi
        else
            echo -e "${YELLOW}Configuring build with CUDA...${NC}"
            cmake .. -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON > cmake_output.log 2>&1 &
            spinner $!
            
            if [ $? -ne 0 ]; then
                print_color "RED" "CMake configuration failed. Check cmake_output.log for details." "error"
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}Configuring build without CUDA...${NC}"
        cmake .. -DCMAKE_BUILD_TYPE=Release > cmake_output.log 2>&1 &
        spinner $!
        
        if [ $? -ne 0 ]; then
            print_color "RED" "CMake configuration failed. Check cmake_output.log for details." "error"
            return 1
        fi
    fi
    
    print_color "YELLOW" "Compiling stable-diffusion.cpp (this may take a while)..." "info"
    echo -e "${BOLD_PURPLE}This process will utilize all available CPU cores for faster compilation.${NC}"
    echo -e "${BOLD_PURPLE}Your system may become less responsive during this process.${NC}"
    echo
    
    # Start the build process in the background
    make -j$(nproc) > make_output.log 2>&1 &
    build_pid=$!
    
    # Monitor the build process
    echo -e "${YELLOW}Building in progress...${NC}"
    
    # Show a spinner with elapsed time
    start_time=$(date +%s)
    while kill -0 $build_pid 2>/dev/null; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt 60 ]; then
            mins=$((elapsed / 60))
            secs=$((elapsed % 60))
            echo -ne "${BOLD_PURPLE}Build in progress... ${WHITE}${mins}m ${secs}s elapsed${NC}\r"
        else
            echo -ne "${BOLD_PURPLE}Build in progress... ${WHITE}${elapsed}s elapsed${NC}\r"
        fi
        
        sleep 1
    done
    
    # Check if the build was successful
    wait $build_pid
    build_status=$?
    echo -e "\n"
    
    if [ $build_status -ne 0 ]; then
        print_color "RED" "Compilation failed. Check make_output.log for details." "error"
        return 1
    fi
    
    # Verify the build was successful
    if [ -f "bin/sd" ]; then
        echo
        print_color "GREEN" "✅ Build successful! ✅" "success"
        echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
        echo -e "│ ${YELLOW}Executable created at:${BOLD_GREEN}                          │"
        echo -e "│ ${BOLD_WHITE}$(pwd)/bin/sd${BOLD_GREEN}                              │"
        echo -e "└─────────────────────────────────────────────────────────┘${NC}"
        echo
        print_color "BOLD_GREEN" "Press Enter to continue..." "info"
    else
        print_color "RED" "Build completed but executable not found. There might be an issue." "error"
        return 1
    fi
    
    cd ../.. || return 1
    return 0
}

# Function to set up virtual environment
setup_venv() {
    print_color "PURPLE" "Setting up Python virtual environment..." "subheader"
    
    # Check Python version
    local python_version=$(python3 --version 2>&1 | awk '{print $2}')
    print_color "YELLOW" "Detected Python version: $python_version" "info"
    
    # Check if venv already exists
    if [ -d "diffugen_env" ]; then
        print_color "YELLOW" "Virtual environment already exists." "info"
        echo -e "${BOLD_YELLOW}Would you like to reuse the existing environment or create a fresh one?${NC}"
        echo -e "${BOLD_PURPLE}1. ${BOLD_WHITE}Reuse existing (faster)${NC}"
        echo -e "${BOLD_PURPLE}2. ${BOLD_WHITE}Create fresh environment (cleaner)${NC}"
        read -p "$(echo -e ${BOLD_YELLOW}Enter your choice \(1/2\):${NC} )" -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[2]$ ]]; then
            print_color "YELLOW" "Removing existing virtual environment..." "info"
            rm -rf diffugen_env
            if [ ! -d "diffugen_env" ]; then
                print_color "GREEN" "Existing environment removed successfully." "success"
            else
                print_color "RED" "Failed to remove existing environment." "error"
                return 1
            fi
        else
            print_color "GREEN" "Reusing existing virtual environment." "success"
            VENV_CREATED_THIS_SESSION=false
            # Just activate and proceed
            echo -e "${YELLOW}Activating virtual environment...${NC}"
            source diffugen_env/bin/activate
            if [ $? -ne 0 ]; then
                print_color "RED" "Failed to activate virtual environment." "error"
                return 1
            fi
            print_color "GREEN" "Virtual environment activated!" "success"
            echo
            print_color "GREEN" "✅ Python environment ready! ✅" "success"
            return 0
        fi
    fi
    
    # Create virtual environment with animation
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv diffugen_env > /dev/null 2>&1 &
    spinner $!
    
    if [ ! -d "diffugen_env" ]; then
        print_color "RED" "Failed to create virtual environment." "error"
        return 1
    fi
    
    # Mark that we created the venv in this session
    VENV_CREATED_THIS_SESSION=true
    
    print_color "GREEN" "Virtual environment created successfully!" "success"
    
    # Activate virtual environment
    echo -e "${YELLOW}Activating virtual environment...${NC}"
    source diffugen_env/bin/activate
    
    if [ $? -ne 0 ]; then
        print_color "RED" "Failed to activate virtual environment." "error"
        return 1
    fi
    
    print_color "GREEN" "Virtual environment activated!" "success"
    
    # Install dependencies with progress animation
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    echo -e "${BOLD_PURPLE}This may take a few minutes depending on your internet connection.${NC}"
    echo
    
    # Show fancy progress bar
    progress_bar 5 30 "Installing Python packages..."
    
    pip install -r requirements.txt > pip_output.log 2>&1
    
    if [ $? -ne 0 ]; then
        print_color "RED" "Failed to install dependencies. Check pip_output.log for details." "error"
        return 1
    fi
    
    echo
    print_color "GREEN" "✅ Python environment setup complete! ✅" "success"
    echo -e "${BOLD_GREEN}┌─────────────────────────────────────────────────────────┐"
    echo -e "│ ${WHITE}Virtual environment:${BOLD_GREEN}                            │"
    echo -e "│ ${BOLD_WHITE}$(pwd)/diffugen_env${BOLD_GREEN}                        │"
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    
    return 0
}

# Function to update file paths
update_file_paths() {
    print_color "PURPLE" "Updating configuration files..." "subheader"
    
    local current_dir=$(pwd)
    print_color "YELLOW" "Current directory: $current_dir" "info"
    
    echo -e "${YELLOW}Updating paths in configuration files...${NC}"
    
    # List files to be updated
    echo -e "${BOLD_PURPLE}The following files will be updated:${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.json${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.sh${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.py${NC}"
    echo
    
    # Show progress for each file
    for file in diffugen.json diffugen.sh diffugen.py; do
        echo -ne "${YELLOW}Updating ${BOLD_WHITE}$file${YELLOW}...${NC} "
        sed -i.bak "s|/path/to/diffugen|$current_dir|g" "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${BOLD_GREEN}✓${NC}"
        else
            echo -e "${BOLD_RED}✗${NC}"
            print_color "RED" "Failed to update $file" "error"
            return 1
        fi
        
        # Small delay for visual effect
        sleep 0.5
    done
    
    echo
    print_color "GREEN" "✅ Configuration files updated successfully! ✅" "success"
    
    return 0
}

# Function to handle model selection and downloading
model_selection_menu() {
    clear
    print_color "BOLD_CYAN" "MODEL SELECTION" "header"
    echo -e "${BOLD_WHITE}Choose models to download for stable-diffusion.cpp${NC}"
    echo
    
    # Set current operation
    CURRENT_OPERATION="download"
    
    # List available models
    echo -e "${BOLD_WHITE}Available Models:${NC}"
    echo
    
    # Use associative array for better model management
    declare -A models
    
    models["1"]="sd_v1.5.safetensors (1.5GB) - Standard Stable Diffusion v1.5"
    models["2"]="sd_v1.5-pruned-emaonly.safetensors (1.5GB) - Pruned SD v1.5"
    models["3"]="realisticVisionV51_v51VAE.safetensors (4GB) - Realistic Vision v5.1"
    models["4"]="dreamshaper_8.safetensors (2GB) - Dreamshaper v8"
    models["5"]="revAnimated_v122.safetensors (2GB) - Rev Animated v1.2.2"
    models["6"]="sdxl_1.0_fp16.safetensors (6GB) - SDXL 1.0 FP16"
    models["7"]="controllnet/control_v11p_sd15_canny.safetensors (1.4GB) - ControlNet Canny"
    models["8"]="controllnet/control_v11p_sd15_openpose.safetensors (1.4GB) - ControlNet OpenPose"
    
    # Display models with numbers
    for num in "${!models[@]}"; do
        local model_info="${models[$num]}"
        echo -e "${CYAN}$num)${NC} ${BOLD_WHITE}${model_info}${NC}"
    done
    
    echo
    print_color "BOLD_WHITE" "Enter numbers for models to download (space-separated, or a for all):" "prompt"
    read model_choice
    
    # Handle no selection
    if [ -z "$model_choice" ]; then
        echo
        print_color "YELLOW" "No models selected. Returning to main menu." "warning"
        echo
        read -p "Press Enter to continue..."
        return
    fi
    
    # Handle 'a' for all
    if [ "$model_choice" = "a" ]; then
        model_choice="1 2 3 4 5 6 7 8"
    fi
    
    # Process each selection
    for choice in $model_choice; do
        if [ -n "${models[$choice]}" ]; then
            # Extract model filename from the model info
            local model_info="${models[$choice]}"
            local model_filename=$(echo "$model_info" | awk '{print $1}')
            
            # Remember what we're currently downloading
            current_model_name="$model_filename"
            current_download_file="$MODELS_DIR/$model_filename"
            
            # Set up destination directory for controlnet models
            if [[ "$model_filename" == controllnet/* ]]; then
                mkdir -p "$MODELS_DIR/controllnet"
            fi
            
            # Download the model
            download_model "$model_filename"
            
            # Clear current download tracking after successful completion
            current_model_name=""
            current_download_file=""
        else
            echo
            print_color "YELLOW" "Invalid selection: $choice" "warning"
        fi
    done
    
    echo
    print_color "BOLD_GREEN" "✓ Model download process complete" "success"
    echo
    read -p "Press Enter to continue..."
}

# Function to download a specific model
download_model() {
    local model_name="$1"
    local model_dir="$MODELS_DIR"
    local temp_file="/tmp/diffugen_download_${model_name##*/}.part"
    
    echo
    print_color "BOLD_CYAN" "DOWNLOADING $model_name" "subheader"
    
    # Update current download variables for interrupt handling
    current_model_name="$model_name"
    current_download_file="$model_dir/$model_name"
    
    # Determine URL based on model name
    local url=""
    case "$model_name" in
        "sd_v1.5.safetensors")
            url="https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
            ;;
        "sd_v1.5-pruned-emaonly.safetensors")
            url="https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
            ;;
        "realisticVisionV51_v51VAE.safetensors")
            url="https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/realisticVisionV51_v51VAE.safetensors"
            ;;
        "dreamshaper_8.safetensors")
            url="https://huggingface.co/Lykon/DreamShaper/resolve/main/dreamshaper_8.safetensors"
            ;;
        "revAnimated_v122.safetensors")
            url="https://huggingface.co/manashiku/rev-animated/resolve/main/revAnimated_v122.safetensors"
            ;;
        "sdxl_1.0_fp16.safetensors")
            url="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors"
            ;;
        "controllnet/control_v11p_sd15_canny.safetensors")
            url="https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth"
            ;;
        "controllnet/control_v11p_sd15_openpose.safetensors")
            url="https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth"
            ;;
        *)
            print_color "BOLD_RED" "✗ Unknown model: $model_name" "error"
            return 1
            ;;
    esac
    
    # Check if file already exists
    if [ -f "$model_dir/$model_name" ]; then
        print_color "BOLD_GREEN" "✓ Model $model_name already exists" "success"
        return 0
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$model_dir/$model_name")"
    
    # Download with progress bar using wget or curl
    echo -e "${BOLD_WHITE}Downloading from:${NC} ${CYAN}$url${NC}"
    echo -e "${BOLD_WHITE}Saving to:${NC} ${CYAN}$model_dir/$model_name${NC}"
    echo
    
    if command -v wget &> /dev/null; then
        wget --show-progress -q -c "$url" -O "$temp_file"
        download_status=$?
    elif command -v curl &> /dev/null; then
        curl -# -C - -L "$url" -o "$temp_file"
        download_status=$?
    else
        print_color "BOLD_RED" "✗ Neither curl nor wget is installed" "error"
                                return 1
                            fi
    
    # Move the file if download was successful
    if [ $download_status -eq 0 ]; then
        mv "$temp_file" "$model_dir/$model_name"
        if [ -f "$model_dir/$model_name" ]; then
            print_color "BOLD_GREEN" "✓ Successfully downloaded $model_name" "success"
            # Clear current download tracking after successful completion
            current_model_name=""
            current_download_file=""
            return 0
        else
            print_color "BOLD_RED" "✗ Failed to save $model_name" "error"
                        return 1
                fi
            else
        print_color "BOLD_RED" "✗ Failed to download $model_name" "error"
                    return 1
                fi
}

# Function to display TUI menu
display_tui_menu() {
    # Use a static variable to track if this is the first run
    if [ -z "$MENU_DISPLAYED" ]; then
    clear
    display_logo
        MENU_DISPLAYED=1
    else
        clear
    fi
    
    echo -e "${BOLD_PURPLE}===== DiffuGen Setup Menu ====="

    echo -e "${YELLOW}1. Install dependencies"
    echo -e "${YELLOW}2. Clone/update stable-diffusion.cpp"
    echo -e "${YELLOW}3. Build stable-diffusion.cpp"
    echo -e "${YELLOW}4. Set up Python environment"
    echo -e "${YELLOW}5. Download models"
    echo -e "${YELLOW}6. Update configuration files"
    echo -e "${BOLD_YELLOW}7. Run all steps ${PURPLE}(recommended)"
    echo -e "${PURPLE}8. ${BOLD_PURPLE}Display Guide"
    echo -e "${RED}9. ${BOLD_RED}Exit"
    echo
    
    echo -ne "${YELLOW}Enter your choice ${BOLD_PURPLE}(${BOLD_PURPLE}1${BOLD_PURPLE}-${BOLD_PURPLE}9${BOLD_PURPLE}): ${BOLD_PURPLE}"
    read choice
    echo -ne "${NC}"
    echo
    
    case $choice in
        1)
            run_with_error_handling "Installing dependencies" "" install_dependencies
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        2)
            run_with_error_handling "Setting up stable-diffusion.cpp" "" setup_stable_diffusion_cpp
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        3)
            run_with_error_handling "Building stable-diffusion.cpp" "" build_stable_diffusion_cpp
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        4)
            run_with_error_handling "Setting up Python environment" "" setup_venv
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        5)
            run_with_error_handling "Downloading models" "" model_selection_menu
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        6)
            run_with_error_handling "Updating configuration files" "" update_file_paths
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        7)
            run_with_error_handling "Installing dependencies" "" install_dependencies
            run_with_error_handling "Setting up stable-diffusion.cpp" "" setup_stable_diffusion_cpp
            run_with_error_handling "Building stable-diffusion.cpp" "" build_stable_diffusion_cpp
            run_with_error_handling "Setting up Python environment" "" setup_venv
            run_with_error_handling "Downloading models" "" model_selection_menu
            run_with_error_handling "Updating configuration files" "" update_file_paths
            
            print_color "GREEN" "DiffuGen setup completed successfully!" "success"
            
            # Show completion guide
            show_completion_guide
            
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        8)
            show_completion_guide            
            # Return to the menu with full logo display
            MENU_DISPLAYED=""
            display_tui_menu
            ;;    
        9)
            print_color "YELLOW" "Exiting DiffuGen setup." "warning"
            exit 0
            ;;
        *)
            print_color "RED" "Invalid choice. Please try again." "error"
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;    
    esac
}

# Function to show completion guide
show_completion_guide() {
    print_color "GREEN" "✅ DiffuGen Setup Successfully Completed! ✅" "success"
echo

print_color "PURPLE" "╔════════════════════════════════════════════════════════════════════════╗"
print_color "PURPLE" "║                          COMPREHENSIVE GUIDE                           ║"
print_color "PURPLE" "╚════════════════════════════════════════════════════════════════════════╝"
echo

echo
print_color "PURPLE" "    ______   __   ___   ___         _______              "
print_color "GREEN" "   |   _  \ |__|.'  _|.'  _|.--.--.|   _   |.-----.-----. "
print_color "YELLOW" "   |.  |   \|  ||   _||   _||  |  ||.  |___||  -__|     |"
print_color "PURPLE" "   |.  |    \__||__|  |__|  |_____||.  |   ||_____|__|__|"
print_color "BLUE" "     |:  1    /                      |:  1   |             "
print_color "YELLOW" "   |::.. . /                       |::.. . |             "
    print_color "PURPLE" "   \`------'                        \`-------'             "

# MCP Integration Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 MCP INTEGRATION ══════════════════════════════════════════════════╗${NC}\n"
echo "To use DiffuGen with MCP-compatible IDEs (Cursor, Windsurf, etc.):"
echo
print_color "YELLOW" "1. Add the following to your MCP configuration:"
echo "───────────────────────────────────────────────────────────"
cat diffugen.json | sed 's/^/  /'
echo "───────────────────────────────────────────────────────────"
echo

# Command Line Usage Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 COMMAND LINE USAGE ════════════════════════════════════════════════╗${NC}\n"
echo "To generate images directly from the command line:"
echo
print_color "YELLOW" "Basic usage:"
echo "  ./diffugen.sh \"A beautiful sunset over mountains\""
echo
print_color "YELLOW" "Advanced usage with parameters:"
echo "  ./diffugen.sh \"A beautiful sunset over mountains\" \\"
echo "    --model flux-dev \\"
echo "    --width 1024 \\"
echo "    --height 768 \\"
echo "    --steps 30 \\"
echo "    --cfg-scale 7 \\"
echo "    --seed 42 \\"
echo "    --sampling-method euler_a \\"
echo "    --negative-prompt \"blurry, ugly\""
echo

# Supported Models Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 SUPPORTED MODELS ═════════════════════════════════════════════════╗${NC}\n"
echo "DiffuGen supports the following models:"
echo

print_color "YELLOW" "-  flux-schnell: " && echo "Fast generation model (default)"
print_color "YELLOW" "-  flux-dev:    " && echo "Development model with better quality"
print_color "YELLOW" "-  sdxl:        " && echo "Stable Diffusion XL 1.0 for high-quality images"
print_color "YELLOW" "-  sd3:         " && echo "Stable Diffusion 3 Medium"
print_color "YELLOW" "-  sd15:        " && echo "Stable Diffusion 1.5 classic model"
echo

    # Model Dependencies Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 MODEL DEPENDENCIES ══════════════════════════════════════════════╗${NC}\n"
    echo "Make sure you have all required files for the models you want to use:"
    echo

    print_color "YELLOW" "-  Flux models (flux-schnell, flux-dev) require:"
    print_color "CYAN" "   • t5xxl Text Encoder" "bullet"
    print_color "CYAN" "   • clip-l Text Encoder" "bullet"
    print_color "CYAN" "   • VAE decoder" "bullet"
    echo

    print_color "YELLOW" "-  SDXL requires:"
    print_color "CYAN" "   • sdxl-vae VAE file" "bullet"
    echo

    print_color "YELLOW" "-  SD15 and SD3 models are standalone and don't require additional files"
    echo

# Examples Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 EXAMPLES ════════════════════════════════════════════════════════╗${NC}\n"
echo "Try these example prompts to get started:"
echo
print_color "YELLOW" "-  Generate a simple image:"
echo "  ./diffugen.sh \"A cat sitting on a windowsill\""
echo
print_color "YELLOW" "-  Generate with specific dimensions:"
echo "  ./diffugen.sh \"A futuristic cityscape\" --width 1024 --height 512"
echo
print_color "YELLOW" "-  Use a different model with custom parameters:"
echo "  ./diffugen.sh \"Portrait of a cyberpunk character\" --model sdxl --steps 50 --cfg-scale 8"
echo

# Troubleshooting Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 TROUBLESHOOTING ════════════════════════════════════════════════════╗${NC}\n"
echo "If you encounter issues:"
echo
print_color "YELLOW" "-  Verify model files are in the correct location:"
echo "  ls -la ./stable-diffusion.cpp/models/"
echo
print_color "YELLOW" "-  Check for CUDA compatibility:"
echo "  ./stable-diffusion.cpp/build/bin/sd --help"
echo
print_color "YELLOW" "-  For low VRAM, try reducing dimensions or steps:"
echo "  ./diffugen.sh \"Simple landscape\" --width 512 --height 512 --steps 20"
echo

# Resources Section
echo -e "\n${BOLD_PURPLE}╔══════ 📌 RESOURCES ══════════════════════════════════════════════════════════╗${NC}\n"
echo "For more information and support:"
echo
print_color "YELLOW" "-  GitHub:  " && echo "http://github.com/CLOUDWERX-DEV/diffugen"
print_color "YELLOW" "-  Website: " && echo "http://cloudwerx.dev"
print_color "YELLOW" "-  Documentation: " && echo "http://github.com/CLOUDWERX-DEV/diffugen/wiki"
print_color "YELLOW" "-  Report Issues: " && echo "http://github.com/CLOUDWERX-DEV/diffugen/issues"
echo

# Footer
print_color "PURPLE" "╔════════════════════════════════════════════════════════════════════════╗"
print_color "PURPLE" "║                                                                        ║"
print_color "PURPLE" "║                   Made with ❤️ by CLOUDWERX LAB                         ║"
print_color "PURPLE" "║               \"Digital Food for the Analog Soul\"                       ║"
print_color "PURPLE" "║                                                                        ║"
print_color "PURPLE" "╚════════════════════════════════════════════════════════════════════════╝"

# Prompt for next steps
echo
print_color "BOLD_PURPLE" "What would you like to do next?"
echo "1. View documentation"
echo "2. Return to main menu"
read -p "Enter your choice (1-2): " choice

case $choice in
    1)
        echo "Opening documentation..."
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://github.com/CLOUDWERX-DEV/diffugen"
        elif command -v open &> /dev/null; then
            open "http://github.com/CLOUDWERX-DEV/diffugen"
        elif command -v start &> /dev/null; then
            start "http://github.com/CLOUDWERX-DEV/diffugen"
        else
            echo "Could not open browser automatically. Please visit: http://github.com/CLOUDWERX-DEV/diffugen"
        fi
        ;;
    2)
        print_color "YELLOW" "Returning to main menu..." "info"
        # Reset the MENU_DISPLAYED variable to force logo display
        MENU_DISPLAYED=""
        ;;
    *)
        print_color "RED" "Invalid choice. Returning to main menu." "error"
        # Reset the MENU_DISPLAYED variable to force logo display
        MENU_DISPLAYED=""
        ;;
esac
}

# Main script execution
trap 'cleanup "Script interrupted by user"' INT TERM

# Before we start, ensure we have a trap function to handle the signals properly
handle_interrupt() {
    echo
    
    # If we're not in a critical operation (like in the main menu), just exit cleanly
    if [ "$IN_CRITICAL_OPERATION" = false ]; then
        print_color "YELLOW" "Operation cancelled by user. Exiting..." "warning"
        exit 0
    fi
    
    # For user-initiated cancellations, provide a clean, simple exit
    print_color "BOLD_YELLOW" "Operation cancelled by user." "warning"
    
    # Check if we have an ongoing download to clean up
    if [ "$CURRENT_OPERATION" = "download" ] && [ -n "$current_model_name" ] && [ -n "$current_download_file" ]; then
        echo
        print_color "YELLOW" "A download of '$current_model_name' was in progress." "info"
        
        if [ -f "$current_download_file" ]; then
            print_color "YELLOW" "Found a partial download file that may be incomplete:" "info"
            echo -e "${BOLD_WHITE}Path: ${CYAN}$current_download_file${NC}"
            
            # Get file size in a human-readable format
            local file_size=$(du -h "$current_download_file" 2>/dev/null | cut -f1)
            if [ -n "$file_size" ]; then
                echo -e "${BOLD_WHITE}Size: ${CYAN}$file_size${NC}"
            fi
            
            echo
            read -p "$(echo -e ${BOLD_YELLOW}Would you like to remove this incomplete download file? \(y/n\)${NC} )" -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                print_color "YELLOW" "Removing incomplete download: $current_download_file" "info"
                rm -f "$current_download_file" 
                if [ ! -f "$current_download_file" ]; then
                    print_color "BOLD_GREEN" "✓ Partial download removed successfully" "success"
                else
                    print_color "BOLD_RED" "✗ Failed to remove the partial download file" "error"
                fi
                echo
            else
                print_color "YELLOW" "Keeping partial download file." "info"
                echo
            fi
        fi
    else
        # For other operations, just clean any temp files silently
        if [ "$CURRENT_OPERATION" = "download" ]; then
            # Clean up any temp files silently
            rm -f /tmp/diffugen_download_*.part 2>/dev/null
        fi
    fi
    
    # Return to main menu option
    print_color "BOLD_GREEN" "✓ You can restart this operation from the main menu when ready." "success"
    echo
    
    # Reset critical operation
    set_critical_operation false
    
    # Return to main menu if possible, otherwise exit
    if type display_tui_menu &>/dev/null; then
        # Reset menu display to show logo
        MENU_DISPLAYED=""
        echo
        read -p "Press Enter to return to main menu..." 
        display_tui_menu
    else
        exit 0
    fi
}

# Set up trap to catch interrupts
trap handle_interrupt INT TERM

# Initialize the menu directly without calling display_logo separately
display_tui_menu

exit 0

