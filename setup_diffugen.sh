#!/bin/bash

# DiffuGen Setup Script
# Made with <3 by CLOUDWERX LAB "Digital Food for the Analog Soul"
# http://github.com/CLOUDWERX-DEV/diffugen
# http://cloudwerx.dev
# !! Open-Source !!

# Global variables for tracking downloads
current_model_name=""
current_download_file=""

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
    progress_bar 2 20 "Get Ready For AWESOME!..."
    clear
    
    echo -e "${YELLOW_BG}"
    echo -e "                                        ${BOLD_PURPLE} {´◕ ◡ ◕｀}                                               "
    echo -e "                                ${BOLD_PURPLE}[ DiffuGen Setup Utility ]                                        "
    echo -e "${NC}"
    
            echo -e "${BOLD_PURPLE}"   
            echo  "              ______ ________________ _______            _______ _______ _       "
            sleep 0.1
            echo "              (  __  \\__   __(  ____ (  ____ \\      /(  ____ (  ____ ( (    /|"
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
            
            echo -e "\n${!color_name}${left_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char} ${YELLOW}${text} ${!color_name}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${right_char}${NC}\n"
            ;;
        "subheader")
            # Create the decorative subheader with horizontal lines and the text in the middle
            local line_char="─"
            local left_char="┌"
            local right_char="┐"
            local line_length=65
            
            echo -e "\n${!color_name}${left_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char} ${YELLOW}${text} ${!color_name}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${line_char}${right_char}${NC}\n"
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
    print_color "PURPLE_BG" "  ⚠️  ERROR OCCURRED - STARTING CLEANUP PROCESS  " ""
    print_color "PURPLE_BG" "                                                " ""
    echo
    
    if [ -n "$1" ]; then
        print_color "BOLD_YELLOW" "Error message: $1" "error"
    fi
    
    echo
    
    # If we have a current download in progress, only remove that file
    if [ -n "$current_download_file" ] && [ -n "$current_model_name" ]; then
        print_color "BOLD_YELLOW" "Download of '$current_model_name' was interrupted." "warning"
        if [ -f "$current_download_file" ]; then
            read -p "$(echo -e ${BOLD_YELLOW}Remove the incomplete download file? \(y/n\)${NC} )" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                print_color "YELLOW" "Removing incomplete download: $current_download_file" "info"
                rm -f "$current_download_file" 
                print_color "BOLD_GREEN" "Incomplete download file removed." "success"
            else
                print_color "YELLOW" "Keeping incomplete download file." "info"
            fi
        else
            print_color "YELLOW" "No download file found to clean up." "info"
        fi
    else
        # More general cleanup for other types of failures
        read -p "$(echo -e ${BOLD_YELLOW}Would you like to remove partially installed files? \(y/n\)${NC} )" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            # Only offer to remove temporary files and virtual environments, NOT built files
            if [ -d "diffugen_env" ]; then
                print_color "YELLOW" "Removing Python virtual environment..." "info"
                rm -rf diffugen_env &
                spinner $!
            fi
            
            # Remove any temporary download files, but NOT the build directory
            print_color "YELLOW" "Removing temporary download files..." "info"
            rm -f /tmp/diffugen_download_*.part &
            spinner $!
            
            print_color "BOLD_GREEN" "Cleanup completed successfully." "success"
        else
            print_color "YELLOW" "Skipping cleanup as requested." "info"
        fi
    fi
    
    echo
    print_color "YELLOW" "Please fix the issues and try again." "warning"
    echo
    print_color "BOLD_PURPLE" "For help, visit: https://github.com/CLOUDWERX-DEV/diffugen/issues" "info"
    echo
    exit 1
}

# Error handling wrapper with enhanced visuals
run_with_error_handling() {
    local cmd_description=$1
    shift
    
    echo
    print_color "BOLD_BLUE" "Starting: $cmd_description" "header"
    
    if ! "$@"; then
        cleanup "Failed during: $cmd_description"
    fi
    
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
    
    # Create virtual environment with animation
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv diffugen_env > /dev/null 2>&1 &
    spinner $!
    
    if [ ! -d "diffugen_env" ]; then
        print_color "RED" "Failed to create virtual environment." "error"
        return 1
    fi
    
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

# Function to display model selection menu
model_selection_menu() {
    local models=(
        "flux-schnell:huggingface.co/leejet/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-q8_0.gguf:Flux Schnell - Fast generation model (requires t5xxl, clip-l, vae)"
        "flux-dev:huggingface.co/leejet/FLUX.1-dev-gguf/resolve/main/flux1-dev-q8_0.gguf:Flux Dev - Development model with better quality (requires t5xxl, clip-l, vae)"
        "t5xxl:huggingface.co/Sanami/flux1-dev-gguf/resolve/main/t5xxl_fp16.safetensors:T5XXL Text Encoder (required for Flux models)"
        "clip-l:huggingface.co/Sanami/flux1-dev-gguf/resolve/main/clip_l.safetensors:CLIP-L Text Encoder (required for Flux models)"
        "vae:huggingface.co/pretentioushorsefly/flux-models/resolve/main/models/vae/ae.safetensors:VAE for image decoding (required for Flux models)"
        "sdxl:huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors:SDXL 1.0 Base Model (requires sdxl-vae)"
        "sdxl-vae:huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae-fp16-fix.safetensors:SDXL VAE (required for SDXL)"
        "sd15:huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors:Stable Diffusion 1.5 (standalone)"
        "sd3:huggingface.co/leo009/stable-diffusion-3-medium/resolve/main/sd3_medium_incl_clips_t5xxlfp16.safetensors:Stable Diffusion 3 Medium (standalone)"
    )
    
    print_color "PURPLE" "Model Selection" "header"
    
    # Create directory with animation
    echo -e "${YELLOW}Creating model directories...${NC}"
    mkdir -p stable-diffusion.cpp/models/flux > /dev/null 2>&1 &
    spinner $!
    
    if [ ! -d "stable-diffusion.cpp/models/flux" ]; then
        print_color "RED" "Failed to create model directories." "error"
        return 1
    fi
    
    print_color "GREEN" "Model directories created successfully!" "success"
    echo
    
    # Display model dependency information
    print_color "BOLD_YELLOW" "⚠ IMPORTANT MODEL DEPENDENCY INFORMATION ⚠" "warning"
    echo
    print_color "YELLOW" "• Flux models (flux-schnell, flux-dev) require: t5xxl, clip-l, and vae encoders" "bullet"
    print_color "YELLOW" "• SDXL requires the sdxl-vae for proper image generation" "bullet"
    print_color "YELLOW" "• SD15 and SD3 are standalone models" "bullet"
    echo
    print_color "BOLD_RED" "Note: Dependencies are NOT auto-selected. Please select ALL required files manually." "error"
    echo
    
    # Display fancy model selection menu
    echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
    echo -e "│ ${WHITE}Available Models${BOLD_PURPLE}                                         │"
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    echo
    print_color "BOLD_YELLOW" "Select models to download:" "info"
    print_color "BOLD_YELLOW" "Required components are marked accordingly." "warning"
    echo
    
    local selected=()
    for i in "${!models[@]}"; do
        IFS=':' read -r name url description <<< "${models[$i]}"
        
        # Display model information properly
        if [[ $name == "t5xxl" || $name == "clip-l" || $name == "vae" || $name == "sdxl-vae" ]]; then
            echo -e "${BOLD_YELLOW}[$((i+1))] ${WHITE}$name${NC} - $description"
        else
            echo -e "${BOLD_CYAN}[$((i+1))] ${WHITE}$name${NC} - $description"
        fi
        # Small delay for visual effect
        sleep 0.1
    done
    
    echo
    read -p "$(echo -e ${BOLD_YELLOW}Enter numbers for models to download \(space-separated, or 'a' for all\):${NC} )" -r choices
    echo
    
    if [[ $choices == "a" || $choices == "A" ]]; then
        animate_text "Selecting all models..." "BOLD_YELLOW"
        for i in "${!models[@]}"; do
                selected+=($i)
        done
    else
        for choice in $choices; do
            idx=$((choice-1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#models[@]} ]; then
                    selected+=($idx)
                echo -e "${BOLD_GREEN}✓ Selected: ${WHITE}${models[$idx]%%:*}${NC}"
                sleep 0.2
            else
                echo -e "${BOLD_RED}✗ Invalid selection: ${WHITE}$choice${NC}"
                sleep 0.2
            fi
        done
    fi
    
    echo
    print_color "BOLD_YELLOW" "Download Summary" "subheader"
    echo -e "${BOLD_WHITE}Selected models to download:${NC}"
    
    for idx in "${selected[@]}"; do
        IFS=':' read -r name url description <<< "${models[$idx]}"
        echo -e "${BOLD_GREEN}• ${WHITE}$name${NC}"
        sleep 0.1
    done
    
    echo
    print_color "BOLD_YELLOW" "Starting downloads..." "info"
    echo -e "${BOLD_YELLOW}This may take a while depending on your internet connection and model sizes.${NC}"
    echo
    
    # Clear any leftover progress bars or spinners
    echo -ne "\033[2K\r"
    
    for idx in "${selected[@]}"; do
        IFS=':' read -r name url description <<< "${models[$idx]}"
        
        # Debug the URL to be 100% sure
        echo -e "${BOLD_CYAN}Debug - Original URL: ${WHITE}$url${NC}"
        
        # Remove any duplicate https:// prefixes that might have been added
        url=$(echo "$url" | sed 's|^https://https://|https://|')
        
        # Make sure the URL has exactly one https:// prefix
        if [[ ! "$url" =~ ^https?:// ]]; then
            url="https://$url"
        fi
        
        echo -e "${BOLD_PURPLE}Debug - Final URL: ${YELLOW}$url${NC}"
        
        # Final validation check
        if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ ]]; then
            echo -e "${BOLD_RED}❌ Invalid URL format: ${WHITE}$url${NC}"
            echo -e "${BOLD_RED}Please check the model definition and try again.${NC}"
            return 1
        fi
        
        filename=$(basename "$url" | sed 's/\?.*//')
        
        # Determine the correct destination path based on model type
        local dest_path
        if [[ $name == "flux-schnell" || $name == "flux-dev" ]]; then
            dest_path="stable-diffusion.cpp/models/flux/$filename"
        elif [[ $name == "t5xxl" ]]; then
            dest_path="stable-diffusion.cpp/models/t5xxl_fp16.safetensors"
        elif [[ $name == "clip-l" ]]; then
            dest_path="stable-diffusion.cpp/models/clip_l.safetensors"
        elif [[ $name == "vae" ]]; then
            dest_path="stable-diffusion.cpp/models/ae.sft"
        elif [[ $name == "sdxl" ]]; then
            dest_path="stable-diffusion.cpp/models/sd_xl_base_1.0.safetensors"
        elif [[ $name == "sdxl-vae" ]]; then
            dest_path="stable-diffusion.cpp/models/sdxl.vae.safetensors"
        elif [[ $name == "sd15" ]]; then
            dest_path="stable-diffusion.cpp/models/v1-5-pruned-emaonly.safetensors"
        elif [[ $name == "sd3" ]]; then
            dest_path="stable-diffusion.cpp/models/sd3_medium_incl_clips_t5xxlfp16.safetensors"
        else
            dest_path="stable-diffusion.cpp/models/$filename"
        fi
        
        # Ensure parent directory exists with proper permissions
        local parent_dir=$(dirname "$dest_path")
        if [ ! -d "$parent_dir" ]; then
            print_color "BOLD_YELLOW" "Creating directory: $parent_dir" "info"
            mkdir -p "$parent_dir"
            chmod 775 "$parent_dir"  # Ensure directory is writable
        fi
        
        # Full path debugging
        local full_path="$(pwd)/$dest_path"
        echo -e "${BOLD_PURPLE}Full destination path: ${YELLOW}$full_path${NC}"
        
        # Check if file already exists
        if [ -f "$dest_path" ]; then
            echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
            echo -e "│ ${WHITE}File already exists: ${BOLD_YELLOW}$name${BOLD_PURPLE}                               │"
            echo -e "└─────────────────────────────────────────────────────────┘${NC}"
            echo -e "${BOLD_WHITE}Path: ${CYAN}$dest_path${NC}"
            
            # Get file size in a human-readable format
            local file_size=$(du -h "$dest_path" | cut -f1)
            echo -e "${BOLD_WHITE}Size: ${CYAN}$file_size${NC}"
            echo
            
            read -p "$(echo -e ${BOLD_YELLOW}Re-download this file? \(y/n\)${NC} )" -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BOLD_GREEN}✓ Skipping download: ${WHITE}$name${NC}"
                echo
                continue
            fi
            
            echo -e "${BOLD_YELLOW}Will re-download: ${WHITE}$name${NC}"
            echo
        fi
        
        # Create fancy download indicator with divider to separate from previous output
        echo -e "${BOLD_WHITE}────────────────────────────────────────────────────────────────${NC}"
        echo -e "${BOLD_PURPLE}┌─────────────────────────────────────────────────────────┐"
        echo -e "│ ${WHITE}Downloading: ${BOLD_CYAN}$name${BOLD_PURPLE}                                     │"
        echo -e "└─────────────────────────────────────────────────────────┘${NC}"
        echo -e "${BOLD_WHITE}Source: ${CYAN}$url${NC}"
        echo -e "${BOLD_WHITE}Destination: ${CYAN}$dest_path${NC}"
        
        # Add estimation of file size if available in the model description
        if [[ $name == "sd15" ]]; then
            echo -e "${BOLD_WHITE}Estimated size: ${CYAN}~4 GB${NC}"
        elif [[ $name == "sdxl" ]]; then
            echo -e "${BOLD_WHITE}Estimated size: ${CYAN}~6 GB${NC}"
        elif [[ $name == "sd3" ]]; then
            echo -e "${BOLD_WHITE}Estimated size: ${CYAN}~10 GB${NC}"
        elif [[ $name == "flux-schnell" || $name == "flux-dev" ]]; then
            echo -e "${BOLD_WHITE}Estimated size: ${CYAN}~2-4 GB${NC}"
        elif [[ $name == "t5xxl" || $name == "clip-l" || $name == "vae" || $name == "sdxl-vae" ]]; then
            echo -e "${BOLD_WHITE}Estimated size: ${CYAN}~1-2 GB${NC}"
        fi
        echo
        
        # Set global variables to track current download for cleanup function
        current_model_name="$name"
        current_download_file="$dest_path"
        
        # Download with progress bar and retry logic
        max_retries=3
        retry_count=0
        download_success=false
        
        while [ $retry_count -lt $max_retries ] && [ "$download_success" = false ]; do
            if [ $retry_count -gt 0 ]; then
                echo -e "${BOLD_YELLOW}Retry attempt $retry_count of $max_retries...${NC}"
                sleep 2
            fi
            
            # Use a temporary file for curl output to prevent interference with other output
            local temp_file="/tmp/diffugen_download_$$.part"
            
            # Clean up the terminal for proper progress display
            echo -e "${BOLD_PURPLE}Preparing to download...${NC}"
            
            # Create clear visual separation before the progress bar
            echo -e "${BOLD_PURPLE}┌────────────────────────────────────────────────────┐"
            echo -e "│ ${WHITE}Download Progress${BOLD_PURPLE}                                  │"
            echo -e "└────────────────────────────────────────────────────┘${NC}"
            
            # Wait a moment for the terminal to be ready
            sleep 1
            
            # Run curl with progress
            echo -e "${YELLOW}Downloading ${BOLD_WHITE}$name${YELLOW}...${NC}"
            curl -L "$url" -o "$temp_file" --progress-bar
            curl_status=$?
            
            # Add a newline after progress bar completes
            echo
            
            # Continue with the rest of the download logic
            if [ $curl_status -eq 0 ]; then
                # Move from temporary location to final destination
                if [ -f "$temp_file" ]; then
                    echo -e "${BOLD_PURPLE}Moving file to final destination...${NC}"
                    mv "$temp_file" "$dest_path"
                    move_status=$?
                    
                    if [ $move_status -eq 0 ] && [ -f "$dest_path" ]; then
                        download_success=true
                        # Get file size for confirmation
                        local file_size=$(du -h "$dest_path" | cut -f1)
                        echo -e "\n${BOLD_GREEN}✅ Download complete: ${WHITE}$name ${BOLD_GREEN}(${YELLOW}$file_size${BOLD_GREEN})${NC}"
                        echo -e "${BOLD_WHITE}File saved to: ${CYAN}$dest_path${NC}"
                        echo -e "${BOLD_WHITE}Verifying file integrity...${NC}"
                        
                        # Verify file size is non-zero
                        local file_bytes=$(stat -c %s "$dest_path" 2>/dev/null || stat -f %z "$dest_path" 2>/dev/null)
                        if [ "$file_bytes" -gt 1000 ]; then  # File should be at least 1KB
                            echo -e "${BOLD_GREEN}✓ File integrity check passed!${NC}"
                            
                            # Make sure file is readable by everyone
                            chmod 664 "$dest_path"
                        else
                            echo -e "${BOLD_RED}⚠ Warning: Downloaded file is very small (${file_bytes} bytes)${NC}"
                            echo -e "${BOLD_YELLOW}This may indicate a download problem.${NC}"
                        fi
                    else
                        echo -e "\n${BOLD_RED}❌ Error: Failed to move file to final destination:${NC}"
                        echo -e "${BOLD_WHITE}Source: $temp_file${NC}"
                        echo -e "${BOLD_WHITE}Destination: $dest_path${NC}"
                        echo -e "${BOLD_RED}Move status: $move_status${NC}"
                        
                        # Try an alternative approach with sudo if standard move failed
                        echo -e "${BOLD_YELLOW}Attempting fallback copy method...${NC}"
                        cp "$temp_file" "$dest_path" 2>/dev/null
                        
                        if [ -f "$dest_path" ]; then
                            download_success=true
                            local file_size=$(du -h "$dest_path" | cut -f1)
                            echo -e "${BOLD_GREEN}✓ Copy successful! (${CYAN}$file_size${BOLD_GREEN})${NC}"
                            # Make sure file is readable by everyone
                            chmod 664 "$dest_path"
                        else
                            retry_count=$((retry_count + 1))
                            if [ $retry_count -lt $max_retries ]; then
                                echo -e "${BOLD_YELLOW}Retrying download...${NC}"
                            else
                                echo -e "${BOLD_RED}Failed to save file after $max_retries attempts.${NC}"
                                # Clean up any temp files that might exist
                                rm -f "$temp_file" 2>/dev/null
                                return 1
                            fi
                        fi
                    fi
                else
                    echo -e "\n${BOLD_RED}❌ Error: Temporary file was not created:${NC}"
                    echo -e "${BOLD_WHITE}$temp_file${NC}"
                    
                    retry_count=$((retry_count + 1))
                    if [ $retry_count -lt $max_retries ]; then
                        echo -e "${BOLD_YELLOW}Retrying download...${NC}"
                    else
                        echo -e "${BOLD_RED}Failed to download after $max_retries attempts.${NC}"
                        # Clean up any temp files that might exist
                        rm -f "$temp_file" 2>/dev/null
                        return 1
                    fi
                fi
            else
                retry_count=$((retry_count + 1))
                if [ $retry_count -lt $max_retries ]; then
                    echo -e "\n${BOLD_YELLOW}⚠ Download failed with error code $curl_status. Retrying...${NC}"
                    # Clean up any temp files that might exist
                    rm -f "$temp_file" 2>/dev/null
                else
                    echo -e "\n${BOLD_RED}❌ Download failed after $max_retries attempts: ${WHITE}$name${NC}"
                    echo -e "${BOLD_RED}Error code: $curl_status${NC}"
                    # Clean up any temp files that might exist
                    rm -f "$temp_file" 2>/dev/null
                    return 1
                fi
            fi
        done
        
        # Clear the current download tracking variables once download is complete
        current_model_name=""
        current_download_file=""
        
        echo
    done
    
    # After all downloads, verify that files were actually saved
    echo -e "${BOLD_PURPLE}Verifying downloaded models...${NC}"
    echo -e "${BOLD_WHITE}Checking models directory: stable-diffusion.cpp/models/${NC}"
    ls -la stable-diffusion.cpp/models/
    echo -e "${BOLD_WHITE}Checking flux directory: stable-diffusion.cpp/models/flux/${NC}"
    ls -la stable-diffusion.cpp/models/flux/ 2>/dev/null || echo -e "${BOLD_YELLOW}(Flux directory is empty or not created)${NC}"
    
    echo
    print_color "BOLD_GREEN" "✅ All models downloaded successfully! ✅" "success"
    
    # Display dependency warning after downloads if specific combinations were downloaded
    local has_flux=$(echo "${selected[@]}" | grep -E '(^|[[:space:]])(0|1)($|[[:space:]])' | wc -l)
    local has_flux_deps=$(echo "${selected[@]}" | grep -E '(^|[[:space:]])(2|3|4)($|[[:space:]])' | wc -c)
    local has_sdxl=$(echo "${selected[@]}" | grep -E '(^|[[:space:]])5($|[[:space:]])' | wc -l)
    local has_sdxl_vae=$(echo "${selected[@]}" | grep -E '(^|[[:space:]])6($|[[:space:]])' | wc -l)
    
    if [ "$has_flux" -gt 0 ] && [ "$has_flux_deps" -eq 0 ]; then
        echo
        print_color "BOLD_RED" "⚠ WARNING: You downloaded Flux models but not all required dependencies!" "warning"
        print_color "BOLD_YELLOW" "Flux models require t5xxl, clip-l, and vae files to work properly." "warning"
        print_color "BOLD_YELLOW" "Please run the download step again to get the missing dependencies." "warning"
    fi
    
    if [ "$has_sdxl" -gt 0 ] && [ "$has_sdxl_vae" -eq 0 ]; then
        echo
        print_color "BOLD_RED" "⚠ WARNING: You downloaded SDXL but not the required VAE!" "warning"
        print_color "BOLD_YELLOW" "SDXL requires the sdxl-vae file to generate proper images." "warning"
        print_color "BOLD_YELLOW" "Please run the download step again to get the missing dependency." "warning"
    fi
    
    return 0
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
            run_with_error_handling "Installing dependencies" install_dependencies
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        2)
            run_with_error_handling "Setting up stable-diffusion.cpp" setup_stable_diffusion_cpp
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        3)
            run_with_error_handling "Building stable-diffusion.cpp" build_stable_diffusion_cpp
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        4)
            run_with_error_handling "Setting up Python environment" setup_venv
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        5)
            run_with_error_handling "Downloading models" model_selection_menu
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        6)
            run_with_error_handling "Updating configuration files" update_file_paths
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        7)
            run_with_error_handling "Installing dependencies" install_dependencies
            run_with_error_handling "Setting up stable-diffusion.cpp" setup_stable_diffusion_cpp
            run_with_error_handling "Building stable-diffusion.cpp" build_stable_diffusion_cpp
            run_with_error_handling "Setting up Python environment" setup_venv
            run_with_error_handling "Downloading models" model_selection_menu
            run_with_error_handling "Updating configuration files" update_file_paths
            
            print_color "GREEN" "DiffuGen setup completed successfully!" "success"
            
            # Show completion guide
            show_completion_guide
            
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        8)  
            show_completion_guide            
            read -p "Press Enter to continue..."
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
        ;;
    *)
        print_color "RED" "Invalid choice. Returning to main menu." "error"
        ;;
esac
}

# Main script execution
trap 'cleanup "Script interrupted by user"' INT TERM

# Before we start, ensure we have a trap function to handle the signals properly
handle_interrupt() {
    echo
    if [ -n "$current_model_name" ] && [ -n "$current_download_file" ]; then
        print_color "BOLD_YELLOW" "Download of '$current_model_name' was interrupted by user." "warning"
        cleanup "Download of '$current_model_name' was interrupted"
    else
        cleanup "Script interrupted by user"
    fi
    exit 1
}

# Set up trap to catch interrupts
trap handle_interrupt INT TERM

# Initialize the menu directly without calling display_logo separately
display_tui_menu

exit 0

