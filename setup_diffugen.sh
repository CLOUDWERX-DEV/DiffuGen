#!/bin/bash

# DiffuGen Setup Script
# Made with <3 by CLOUDWERX LAB "Digital Food for the Analog Soul"
# http://github.com/CLOUDWERX-DEV/diffugen
# http://cloudwerx.dev
# !! Open-Source !!

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to perform cross-platform sed in-place edit
cross_platform_sed() {
    local pattern="$1"
    local file="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires an extension for -i
        sed -i '' "$pattern" "$file" 2>/dev/null
    else
        # Linux and Windows (in WSL)
        sed -i "$pattern" "$file" 2>/dev/null
    fi
    
    return $?
}

# Add a comprehensive dependency check function
check_dependencies() {
    local build_type="${1:-general}"
    
    print_color "PURPLE" "Checking for required dependencies..." "subheader"
    
    local missing_deps=0
    local critical_deps=("git" "curl" "python3" "pip")
    
    # Check critical dependencies first
    for dep in "${critical_deps[@]}"; do
        echo -ne "${YELLOW}Checking for ${BOLD_WHITE}$dep${NC}... "
        if command_exists $dep; then
            echo -e "${BOLD_GREEN}✓${NC}"
        else
            echo -e "${BOLD_RED}✗${NC}"
            print_color "RED" "Critical dependency missing: $dep" "error"
            missing_deps=$((missing_deps + 1))
        fi
    done
    
    # Check build dependencies if we're planning to build
    if [[ "$build_type" == "build" ]]; then
        local build_deps=("cmake" "make" "g++")
        
        for dep in "${build_deps[@]}"; do
            echo -ne "${YELLOW}Checking for ${BOLD_WHITE}$dep${NC}... "
            if command_exists $dep; then
                echo -e "${BOLD_GREEN}✓${NC}"
            else
                echo -e "${BOLD_RED}✗${NC}"
                print_color "YELLOW" "Build dependency missing: $dep" "warning"
                missing_deps=$((missing_deps + 1))
            fi
        done
    fi
    
    if [ $missing_deps -gt 0 ]; then
        print_color "YELLOW" "Some dependencies are missing. Would you like to install them?" "warning"
        read -p "$(echo -e ${BOLD_YELLOW}Install missing dependencies? \(y/n\)${NC} )" -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
            return $?
        else
            print_color "RED" "Cannot proceed without required dependencies." "error"
            return 1
        fi
    fi
    
    print_color "GREEN" "✓ All required dependencies are installed" "success"
    return 0
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
    
    # Use -S to read password from stdin and keep sudo timestamp updated
    echo -e "${BOLD_CYAN}[sudo] password for $USER: ${NC}"
    # Use sudo with -v to explicitly validate and extend the sudo timeout
    sudo -v
    
    # If sudo validation was successful, run the command
    if [ $? -eq 0 ]; then
        # Now run the actual command with sudo
        sudo eval "$cmd" 2>/dev/null &
        local pid=$!
        
        # Show spinner while command is running
        spinner $pid
        return $?
    else
        print_color "RED" "Authentication failed" "error"
        return 1
    fi
}

# Function to initialize paths and directories
initialize_paths() {
    print_color "PURPLE" "Setting up essential paths and directories..." "subheader"
    
    # Get the absolute path of the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Set up models directory
    MODELS_DIR="${SCRIPT_DIR}/models"
    
    # Create models directory if it doesn't exist
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "YELLOW" "Creating models directory at: $MODELS_DIR" "info"
        mkdir -p "$MODELS_DIR"
        if [ ! -d "$MODELS_DIR" ]; then
            print_color "RED" "Failed to create models directory." "error"
            return 1
        fi
        print_color "GREEN" "Models directory created successfully!" "success"
    else
        print_color "GREEN" "Using existing models directory: $MODELS_DIR" "success"
    fi
    
    # Create subdirectories for different model types
    mkdir -p "$MODELS_DIR/sd15"
    mkdir -p "$MODELS_DIR/sdxl"
    mkdir -p "$MODELS_DIR/sd3"
    mkdir -p "$MODELS_DIR/flux-schnell"
    mkdir -p "$MODELS_DIR/flux-dev"
    
    print_color "GREEN" "✓ Path initialization completed successfully" "success"
    echo -e "${BOLD_GREEN}┌─────────────────────────────────────────────────────────┐"
    echo -e "│ ${WHITE}Models will be stored in:${BOLD_GREEN}                      │"
    echo -e "│ ${BOLD_WHITE}${MODELS_DIR}${BOLD_GREEN}                             │"
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    
    return 0
}

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
MODELS_DIR="" # Initialize MODELS_DIR globally

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
    echo -e "                                           ${BOLD_PURPLE} {´◕ ◡ ◕｀}                                             "
    echo -e "                                    ${BOLD_PURPLE}[ DiffuGen Setup Utility ]                                     "
    echo -e "${NC}"
    
 echo -e "${BOLD_PURPLE}"   
               echo  "              ______ ________________ _______          _______________       "
               sleep 0.1
               echo "              (  __  \\__   __(  ____ (  ____ \\       /( ____ (  ____ ( (     /|"
               sleep 0.1
               echo -e "${YELLOW}              | (  \  )  ) (  | (    \/ (    \/ )   ( | (    \/ (    \/  \  ( |"
               echo "              | |   ) |  | |  | (__   | (__   | |   | | |     | (__   | (\ \) |"
               sleep 0.1
               echo "              | |   | |  | |  |  __)  |  __)  | |   | | | ____|  __)  | | \   |"
               sleep 0.1
               echo "              | |   ) |  | |  | (     | (     | |   | | | \_  ) (     | | \   |"
               sleep 0.1
               echo -e "${BOLD_PURPLE}              | (__/  )__) (__| )     | )     | (___) | (___) | (____/\ )  \  |"
               sleep 0.1
               echo "              (______/\_______//      |/      (_______|_______|_______//    )_)"
               echo -e "${NC}"


    
   box "Advanced Stable Diffusion Image Generator Designed For MCP Tool Usage & CLI Image Generation" "BOLD_PURPLE"
   animate_text "Made with ❤️  by CLOUDWERX LAB - Visit us at http://cloudwerx.dev | http://github.com/CLOUDWERX-DEV" "BOLD_YELLOW"

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
            
            # Create a temporary script to run both commands
            TEMP_SCRIPT=$(mktemp)
            echo "#!/bin/bash" > "$TEMP_SCRIPT"
            echo "apt-get update" >> "$TEMP_SCRIPT"
            echo "apt-get install -y git cmake make g++ curl python3 python3-venv python3-pip bc" >> "$TEMP_SCRIPT"
            chmod +x "$TEMP_SCRIPT"
            
            # Run the script with a single sudo call
            print_color "YELLOW" "Updating package lists and installing packages..." "info"
            print_color "CYAN" "Please enter your password when prompted" "info"
            sudo "$TEMP_SCRIPT" &
            spinner $!
            
            # Clean up
            rm -f "$TEMP_SCRIPT"
            
            if [ $? -eq 0 ]; then
                print_color "BOLD_GREEN" "Dependencies installed successfully!" "success"
            else
                print_color "RED" "Failed to install dependencies" "error"
                return 1
            fi
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
                print_color "YELLOW" "Keeping incomplete download file. You can try to resume the download later." "info"
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
        "repository")
            print_color "YELLOW" "The error appears to be related to updating/cloning stable-diffusion.cpp:" "warning"
            echo -e "${BOLD_WHITE}• Ensure the repository directory ownership is correct"
            echo -e "${BOLD_WHITE}• Run the suggested git config command to add the safe directory exception"
            echo -e "${BOLD_WHITE}• Verify that you have write permissions on the directory"
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
    # Use a different style header (more subtle than the function-specific headers)
    echo -e "${BOLD_PURPLE}╔═════════════════════════════════════════════════════════╗"
    echo -e "${BOLD_PURPLE}║ ${YELLOW}RUNNING: ${WHITE}$cmd_description${BOLD_PURPLE}                    "
    echo -e "${BOLD_PURPLE}╚═════════════════════════════════════════════════════════╝"
    echo
    
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
    
    # Execute the command and capture its return code
    "$@"
    local return_code=$?
    
    # Reset the critical operation flag
    set_critical_operation false
    
    if [ $return_code -eq 0 ]; then
        # Success
        print_color "BOLD_GREEN" "Completed: $cmd_description" "success"
    elif [ $return_code -eq 2 ] && [[ "$cmd_description" == *"Downloading models"* ]]; then
        # Special case: model selection with no models selected/downloaded
        # Don't show a completion message for this case
        return 0
    else
        # Error occurred
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
                "repository")
                    error_type="repository"
                    ;;
                *)
                    error_type="unknown"
                    ;;
            esac
        fi
        
        cleanup "$error_message" "$error_type"
    fi
}

# Function to clone or update stable-diffusion.cpp with enhanced visuals
setup_stable_diffusion_cpp() {
    # Check for required dependencies first
    if ! check_dependencies "build"; then
        print_color "RED" "Required dependencies for building are missing." "error"
        return 1
    fi

    if [ -d "stable-diffusion.cpp" ]; then
        print_color "YELLOW" "stable-diffusion.cpp directory already exists." "info"
        read -p "$(echo -e ${BOLD_CYAN}Would you like to update it? \(y/n\)${NC} )" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color "BLUE" "Updating stable-diffusion.cpp repository..." "info"
            (cd stable-diffusion.cpp && {
                # First try to pull with fast-forward only
                if git pull origin master --ff-only; then
                    print_color "GREEN" "Repository updated successfully!" "success"
                else
                    # If that fails, offer to reset to origin/master
                    print_color "YELLOW" "Fast-forward update failed due to divergent branches." "warning"
                    print_color "YELLOW" "Local changes might be lost if you continue." "warning"
                    read -p "$(echo -e ${BOLD_YELLOW}Reset to upstream master branch? This will discard local changes. \(y/n\)${NC} )" -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        git fetch origin master && git reset --hard origin/master
                        print_color "GREEN" "Repository reset to origin/master successfully!" "success"
                    else
                        print_color "YELLOW" "Continuing with existing repository version." "info"
                        # Don't return 1 here - continue with existing repo
                    fi
                fi
                git submodule init && git submodule update
                return 0
            })
            ret=$?
            if [ $ret -ne 0 ]; then
                print_color "YELLOW" "There were some issues with the repository update." "warning"
                print_color "YELLOW" "This is often due to permission issues or directory ownership." "info"
                print_color "YELLOW" "To add an exception for this directory, run:" "info"
                safe_dir=$(realpath stable-diffusion.cpp)
                echo -e "${BOLD_CYAN}git config --global --add safe.directory ${safe_dir}${NC}"
                print_color "BLUE" "Continuing with existing repository version." "info"
                # Return success since we already have the repo
                return 0
            else
                print_color "BOLD_GREEN" "Repository update completed successfully!" "success"
            fi
        else
            print_color "YELLOW" "Skipping update as requested." "info"
        fi
    else
        print_color "BLUE" "Cloning stable-diffusion.cpp..." "info"
        echo -e "${BOLD_CYAN}This may take a few minutes depending on your internet connection.${NC}"
        echo
        print_color "YELLOW" "Cloning in progress..." "info"
        git clone --recursive https://github.com/leejet/stable-diffusion.cpp
        
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
        print_color "YELLOW" "First build attempt failed. Trying once more..." "warning"
        echo "------------------------------------------------------------"
        tail -n 10 make_output.log
        echo "------------------------------------------------------------"
        
        # Try building one more time
        make -j$(nproc) > make_output.log 2>&1 &
        build_pid=$!
        
        # Show a spinner with elapsed time for second attempt
        start_time=$(date +%s)
        while kill -0 $build_pid 2>/dev/null; do
            current_time=$(date +%s)
            elapsed=$((current_time - start_time))
            
            if [ $elapsed -gt 60 ]; then
                mins=$((elapsed / 60))
                secs=$((elapsed % 60))
                echo -ne "${BOLD_PURPLE}Second build attempt in progress... ${WHITE}${mins}m ${secs}s elapsed${NC}\r"
            else
                echo -ne "${BOLD_PURPLE}Second build attempt in progress... ${WHITE}${elapsed}s elapsed${NC}\r"
            fi
            
            sleep 1
        done
        
        # Check if the second build was successful
        wait $build_pid
        build_status=$?
        echo -e "\n"
        
        if [ $build_status -ne 0 ]; then
            print_color "RED" "Compilation failed after two attempts. Showing tail of make_output.log:" "error"
            echo "------------------------------------------------------------"
            tail -n 20 make_output.log
            echo "------------------------------------------------------------"
            return 1
        fi
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

# Function to verify Python version compatibility
verify_python_version() {
    print_color "PURPLE" "Checking Python version..." "subheader"
    
    # Check if python3 command exists
    if ! command_exists python3; then
        print_color "RED" "Python 3 is not installed or not in PATH. Please install Python 3.8 or higher." "error"
        return 1
    fi
    
    # Get Python version
    local python_version=$(python3 --version 2>&1 | awk '{print $2}')
    print_color "YELLOW" "Detected Python version: $python_version" "info"
    
    # Extract major and minor version
    local major_version=$(echo $python_version | cut -d. -f1)
    local minor_version=$(echo $python_version | cut -d. -f2)
    
    # Check if version meets requirements (Python 3.8+)
    if [ "$major_version" -lt 3 ] || ([ "$major_version" -eq 3 ] && [ "$minor_version" -lt 8 ]); then
        print_color "RED" "Python version too old. Python 3.8 or higher is required." "error"
        print_color "YELLOW" "Current version: $python_version" "warning"
        return 1
    fi
    
    print_color "GREEN" "Python version check passed: $python_version" "success"
    return 0
}

# Function to set up virtual environment
setup_venv() {
    print_color "PURPLE" "Setting up Python virtual environment..." "subheader"
    
    # Verify Python version before proceeding
    if ! verify_python_version; then
        print_color "RED" "Python version check failed. Cannot continue with setup." "error"
        return 1
    fi
    
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
    
    # Check if requirements.txt exists
    if [ ! -f "requirements.txt" ]; then
        print_color "RED" "requirements.txt not found. Cannot install Python dependencies." "error"
        print_color "YELLOW" "Please make sure the requirements.txt file exists in the current directory." "warning"
        return 1
    fi  # Changed from } to fi to properly close the if statement
    
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
    
    echo -e "${YELLOW}Checking for configuration files...${NC}"
    
    # Check if required files exist
    local missing_files=0
    for file in diffugen.json diffugen.sh diffugen.py; do
        if [ ! -f "$file" ]; then
            print_color "RED" "Missing file: $file" "error"
            missing_files=$((missing_files + 1))
        fi
    done
    
    if [ $missing_files -gt 0 ]; then
        print_color "RED" "Cannot update paths: $missing_files required files are missing." "error"
        return 1
    fi
    
    echo -e "${YELLOW}Updating paths in configuration files...${NC}"
    
    # List files to be updated
    echo -e "${BOLD_PURPLE}The following files will be updated:${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.json${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.sh${NC}"
    echo -e "${BOLD_GREEN}  • ${WHITE}diffugen.py${NC}"
    echo
    
    # Create a backup directory for original files
    local backup_dir="setup_backups_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo -e "${YELLOW}Backing up original files to ${BOLD_WHITE}$backup_dir${NC}"
    
    # Show progress for each file
    for file in diffugen.json diffugen.sh diffugen.py; do
        echo -ne "${YELLOW}Updating ${BOLD_WHITE}$file${YELLOW}...${NC} "
        
        # Create a backup
        cp "$file" "$backup_dir/$file.orig"
        
        # Normalize path for the current OS
        local normalized_path="$current_dir"
        
        # For Windows compatibility, escape backslashes in the path for sed
        if [[ "$os_type" == "windows" ]]; then
            # Double escape backslashes for sed on Windows
            normalized_path=$(echo "$current_dir" | sed 's/\\/\\\\\\\\/g')
        fi
        
        # Special handling for diffugen.json with proper JSON structure
        if [ "$file" = "diffugen.json" ]; then
            echo -ne "\n${YELLOW}Updating JSON paths with proper structure in ${BOLD_WHITE}$file${YELLOW}...${NC} "
            
            # Check if the file has the mcpServers.diffugen structure
            if grep -q "mcpServers" "$file" && grep -q "diffugen" "$file"; then
                # Update resources.output_dir and resources.models_dir with correct paths
                local models_dir="$current_dir/stable-diffusion.cpp/models"
                local output_dir="$current_dir/outputs"
                
                # For Windows compatibility, escape backslashes
                if [[ "$os_type" == "windows" ]]; then
                    models_dir=$(echo "$models_dir" | sed 's/\\/\\\\\\\\/g')
                    output_dir=$(echo "$output_dir" | sed 's/\\/\\\\\\\\/g')
                fi
                
                # Update the resource paths in the JSON structure
                cross_platform_sed 's|"models_dir": *"[^"]*"|"models_dir": "'"$models_dir"'"|g' "$file"
                cross_platform_sed 's|"output_dir": *"[^"]*"|"output_dir": "'"$output_dir"'"|g' "$file"
                
                # Update command to use absolute path instead of relative path
                cross_platform_sed 's|"command": *"[^"]*"|"command": "'"$normalized_path/diffugen.sh"'"|g' "$file"
                
                # Update SD_CPP_PATH in the environment section
                cross_platform_sed 's|"SD_CPP_PATH": *"[^"]*"|"SD_CPP_PATH": "'"$normalized_path/stable-diffusion.cpp"'"|g' "$file"
                
                if [ $? -eq 0 ]; then
                    echo -e "${BOLD_GREEN}✓${NC}"
                else
                    echo -e "${BOLD_RED}✗${NC}"
                    print_color "RED" "Failed to update JSON structure in $file" "error"
                    return 1
                fi
            else
                echo -e "${BOLD_RED}✗${NC}"
                print_color "RED" "JSON file does not have the expected mcpServers.diffugen structure" "error"
                return 1
            fi
            
            # Continue to the next file
            continue
        fi
        
        # Replace all instances of /path/to/diffugen with the actual path
        cross_platform_sed "s|/path/to/diffugen|$normalized_path|g" "$file"
        
        # Also replace any remaining hardcoded paths that might exist
        # This handles the case where paths like /mnt/... might still be in the files
        if grep -q "/mnt/" "$file"; then
            cross_platform_sed "s|/mnt/[^/]*/Servers/MCP/Tools/DiffuGen|$normalized_path|g" "$file"
        fi
        
        # Also handle other potential path patterns
        if grep -q "/home/" "$file"; then
            cross_platform_sed "s|/home/[^/]*/[^/]*/Servers/MCP/Tools/DiffuGen|$normalized_path|g" "$file"
        fi
        
        # Check if the virtual environment path needs updating
        if grep -q "diffugen_env" "$file"; then
            # Ensure the path to the venv is correct
            local venv_path="$current_dir/diffugen_env"
            
            # For Windows compatibility, escape backslashes in the venv path
            if [[ "$os_type" == "windows" ]]; then
                venv_path=$(echo "$venv_path" | sed 's/\\/\\\\\\\\/g')
            fi
            
            cross_platform_sed "s|/[^\"']*/diffugen_env|$venv_path|g" "$file"
        fi
        
        # For diffugen.sh, update the jq path handling for the MCP config
        if [ "$file" = "diffugen.sh" ]; then
            echo -ne "\n${YELLOW}Updating MCP config parsing in ${BOLD_WHITE}$file${YELLOW}...${NC} "
            
            # Update jq extraction to use the correct JSON path
            cross_platform_sed "s|jq -r '.resources.output_dir // empty'|jq -r '.mcpServers.diffugen.resources.output_dir // empty'|g" "$file"
            
            if [ $? -eq 0 ]; then
                echo -e "${BOLD_GREEN}✓${NC}"
            else
                echo -e "${BOLD_RED}✗${NC}"
                print_color "RED" "Failed to update MCP config parsing in $file" "error"
            fi
        fi
        
        # For diffugen.py specifically, ensure the sd_cpp_path line is updated with the full path
        if [ "$file" = "diffugen.py" ]; then
            echo -ne "\n${YELLOW}Updating SD_CPP_PATH in ${BOLD_WHITE}$file${YELLOW}...${NC} "
            
            # Define the full path to stable-diffusion.cpp
            local sd_cpp_full_path="$current_dir/stable-diffusion.cpp"
            
            # For Windows compatibility, escape backslashes in the path
            if [[ "$os_type" == "windows" ]]; then
                sd_cpp_full_path=$(echo "$sd_cpp_full_path" | sed 's/\\/\\\\\\\\/g')
            fi
            
            # Update the sd_cpp_path line with the full absolute path, regardless of its current format
            # This will handle both the dynamic path and any hardcoded path
            cross_platform_sed "s|sd_cpp_path = os.environ.get(\"SD_CPP_PATH\", .*)|sd_cpp_path = os.environ.get(\"SD_CPP_PATH\", \"$sd_cpp_full_path\")|g" "$file"
            
            # Also update the json parsing to use the mcpServers.diffugen structure
            echo -ne "\n${YELLOW}Updating MCP JSON parsing in ${BOLD_WHITE}$file${YELLOW}...${NC} "
            
            # Make sure the JSON parsing code is using the mcpServers.diffugen structure
            if grep -q "mcpServers.*diffugen" "$file"; then
                echo -e "${BOLD_GREEN}✓ (Already updated)${NC}"
            else
                # If the file doesn't already have the updated structure, it needs a more comprehensive update
                print_color "YELLOW" "The JSON parsing needs to be updated manually in $file" "warning"
                print_color "YELLOW" "Please ensure it uses the mcpServers.diffugen.resources structure" "warning"
            fi
            
            if [ $? -eq 0 ]; then
                echo -e "${BOLD_GREEN}✓${NC}"
            else
                echo -e "${BOLD_RED}✗${NC}"
                print_color "RED" "Failed to update SD_CPP_PATH in $file" "error"
            fi
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${BOLD_GREEN}✓${NC}"
        else
            echo -e "${BOLD_RED}✗${NC}"
            print_color "RED" "Failed to update $file" "error"
            return 1
        fi
        
        # Verify that paths have been updated
        if grep -q "/path/to/diffugen\|/mnt/" "$file"; then
            echo -e "${BOLD_YELLOW}⚠️  Warning: Some paths may still need manual adjustment in $file${NC}"
        fi
        
        # Small delay for visual effect
        sleep 0.5
    done
    
    echo
    print_color "GREEN" "✅ Configuration files updated successfully! ✅" "success"
    echo -e "${BOLD_GREEN}Original files backed up to: ${WHITE}$backup_dir/${NC}"
    
    # Ensure diffugen.sh is executable
    echo -ne "${YELLOW}Setting execute permissions on diffugen.sh...${NC} "
    chmod +x diffugen.sh
    if [ $? -eq 0 ]; then
        echo -e "${BOLD_GREEN}✓${NC}"
    else
        echo -e "${BOLD_RED}✗${NC}"
        print_color "RED" "Failed to set execute permissions on diffugen.sh" "error"
    fi
    
    return 0
}

# Function to handle downloads with proper progress display
download_file() {
    local url="$1"
    local dest_path="$2"
    local file_name="$3"
    local retries="${4:-3}"
    
    mkdir -p "$(dirname "$dest_path")"
    
    # Set the current download file for tracking
    current_model_name="$file_name"
    current_download_file="$dest_path"
    
    # Create header for download
    echo -e "${BOLD_PURPLE}┌────────────────────────────────────────────────────────────────────────┐"
    echo -e "${BOLD_PURPLE}│ ${BOLD_WHITE}Downloading: ${BOLD_YELLOW}$file_name${BOLD_PURPLE}                                             "
    echo -e "${BOLD_PURPLE}└────────────────────────────────────────────────────────────────────────┘${NC}"
    
    local attempt=1
    while [ $attempt -le $retries ]; do
        # Use a temporary file for downloading
        local temp_file="${dest_path}.part"
        
        # First get file size using a HEAD request with completely silent output
        local total_size=""
        echo -e "${BOLD_WHITE}Fetching file size...${NC}"
        total_size=$(curl -sI -L "$url" | grep -i "Content-Length" | tail -1 | awk '{print $2}' | tr -d '\r')
        
        # If we couldn't get the size, use curl's built-in progress bar
        if [ -z "$total_size" ] || [ "$total_size" -lt 1000 ]; then
            echo -e "${BOLD_YELLOW}Using standard progress indicator (file size unavailable)${NC}"
            
            if curl -L --progress-bar -o "$temp_file" "$url"; then
                mv "$temp_file" "$dest_path"
                echo -e "${BOLD_GREEN}✓ Download successful: ${BOLD_YELLOW}$file_name${NC}"
                current_model_name=""
                current_download_file=""
                return 0
            else
                echo -e "${BOLD_YELLOW}⚠ Download attempt $attempt failed${NC}"
                if [ $attempt -lt $retries ]; then
                    echo -e "${BOLD_YELLOW}Retrying in 3 seconds...${NC}"
                    sleep 3
                fi
                attempt=$((attempt + 1))
                rm -f "$temp_file" 2>/dev/null
            fi
        else
            # Display file size in human-readable format
            if [ "$total_size" -ge 1073741824 ]; then # 1 GB or more
                echo -e "${BOLD_WHITE}Total size: ${BOLD_CYAN}$(echo "scale=2; $total_size/1073741824" | bc) GB${NC}"
            elif [ "$total_size" -ge 1048576 ]; then # 1 MB or more
                echo -e "${BOLD_WHITE}Total size: ${BOLD_CYAN}$(echo "scale=2; $total_size/1048576" | bc) MB${NC}"
            else
                echo -e "${BOLD_WHITE}Total size: ${BOLD_CYAN}$(echo "scale=2; $total_size/1024" | bc) KB${NC}"
            fi
            
            echo -e "${BOLD_WHITE}Starting download...${NC}"
            
            # Start download in background with completely silent curl
            curl -s -L -o "$temp_file" "$url" &
            local curl_pid=$!
            
            # Initialize variables for progress tracking
            local bar_width=50
            local start_time=$(date +%s)
            local last_update=0
            local last_size=0
            
            # Progress display loop
            while kill -0 $curl_pid 2>/dev/null; do
                if [ -f "$temp_file" ]; then
                    # Only update display every 1 second to avoid flickering
                    local current_time=$(date +%s)
                    if (( current_time - last_update >= 1 )); then
                        last_update=$current_time
                        
                        # Get current size and calculate percentage
                        local current_size=$(stat -c %s "$temp_file" 2>/dev/null || stat -f %z "$temp_file" 2>/dev/null)
                        local percent=0
                        if [ "$current_size" -gt 0 ] && [ "$total_size" -gt 0 ]; then
                            percent=$(( (current_size * 100) / total_size ))
                            if [ "$percent" -gt 100 ]; then percent=100; fi
                        fi
                        
                        # Calculate progress bar visuals
                        local completed=$(( (bar_width * percent) / 100 ))
                        local remaining=$(( bar_width - completed ))
                        
                        # Calculate download speed and ETA using standard methods
                        local speed_text=""
                        local eta_text=""
                        
                        # Get current time and size
                        local current_time=$(date +%s)
                        local current_size=$(stat -c %s "$temp_file" 2>/dev/null || stat -f %z "$temp_file" 2>/dev/null)
                        
                        # Always calculate and show speed, using a standard approach
                        if [ $current_size -gt 0 ]; then
                            local bytes_per_sec=0
                            
                            # Calculate speed based on recent interval for more accuracy
                            if [ $last_size -gt 0 ]; then
                                local time_diff=$(( current_time - last_update ))
                                # Prevent division by zero
                                if [ $time_diff -ge 1 ]; then
                                    local size_diff=$(( current_size - last_size ))
                                    bytes_per_sec=$(( size_diff / time_diff ))
                                fi
                            fi
                            
                            # Fallback to average speed if recent speed is zero or very small
                            if [ $bytes_per_sec -lt 1024 ]; then
                                local elapsed=$(( current_time - start_time ))
                                if [ $elapsed -ge 1 ]; then
                                    bytes_per_sec=$(( current_size / elapsed ))
                                fi
                            fi
                            
                            # Format speed in human-readable units (no caps)
                            if [ $bytes_per_sec -ge 1048576 ]; then
                                speed_text="$(echo "scale=2; $bytes_per_sec/1048576" | bc) MB/s"
                            elif [ $bytes_per_sec -ge 1024 ]; then
                                speed_text="$(echo "scale=2; $bytes_per_sec/1024" | bc) KB/s"
                            else
                                speed_text="${bytes_per_sec} B/s"
                            fi
                            
                            # Calculate and display ETA whenever we have speed data
                            if [ $bytes_per_sec -gt 0 ]; then
                                local remaining_bytes=$(( total_size - current_size ))
                                local eta_seconds=$(( remaining_bytes / bytes_per_sec ))
                                
                                # Format ETA in human-readable units
                                if [ $eta_seconds -ge 3600 ]; then
                                    eta_text="$(( eta_seconds / 3600 ))h $(( (eta_seconds % 3600) / 60 ))m"
                                elif [ $eta_seconds -ge 60 ]; then
                                    eta_text="$(( eta_seconds / 60 ))m $(( eta_seconds % 60 ))s"
                                else
                                    eta_text="${eta_seconds}s"
                                fi
                            else
                                eta_text="calculating..."
                            fi
                        fi
                        
                        # Always update last_size and last_update
                        last_size=$current_size
                        last_update=$current_time
                        
                        # Clear the entire line before printing new content
                        printf "\r\033[K"
                        
                        # Print progress bar on a single line
                        echo -ne "${BOLD_PURPLE}["
                        # Draw the filled portion
                        for ((i=0; i<completed; i++)); do
                            echo -ne "${BOLD_PURPLE}█"
                        done
                        
                        # Draw the current position marker
                        if [ $completed -lt $bar_width ]; then
                            echo -ne "${BOLD_YELLOW}>"
                            
                            # Draw the empty portion
                            for ((i=0; i<remaining-1; i++)); do
                                echo -ne " "
                            done
                        fi
                        
                        # Print percentage and speed
                        echo -ne "${BOLD_PURPLE}] ${BOLD_WHITE}${percent}%"
                        
                        if [ -n "$speed_text" ]; then
                            echo -ne " ${BOLD_WHITE}| ${BOLD_CYAN}$speed_text"
                        fi
                        
                        if [ -n "$eta_text" ]; then
                            echo -ne " ${BOLD_WHITE}| ${BOLD_GREEN}ETA: $eta_text"
                        fi
                    fi
                fi
                
                # Sleep to reduce CPU usage
                sleep 0.5
            done
            
            # Clear the line and move to next line when download completes
            printf "\r\033[K"
            
            # Verify download success
            wait $curl_pid
            local curl_status=$?
            
            if [ $curl_status -eq 0 ] && [ -f "$temp_file" ]; then
                mv "$temp_file" "$dest_path"
                echo -e "${BOLD_GREEN}✓ Download successful: ${BOLD_YELLOW}$file_name${NC}"
                current_model_name=""
                current_download_file=""
                return 0
            else
                echo -e "${BOLD_YELLOW}⚠ Download attempt $attempt failed${NC}"
                if [ $attempt -lt $retries ]; then
                    echo -e "${BOLD_YELLOW}Retrying in 3 seconds...${NC}"
                    sleep 3
                fi
                attempt=$((attempt + 1))
                rm -f "$temp_file" 2>/dev/null
            fi
        fi
    done
    
    echo -e "${BOLD_RED}✗ Download failed after $retries attempts for ${BOLD_YELLOW}$file_name${NC}"
    current_model_name=""
    current_download_file=""
    return 1
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
    
    # Set critical operation for download
    set_critical_operation true "download"
    
    # Add extra spacing and clear the previous header style
    echo -e "\n\n"
    
    # Use a different style for the model selection header
    echo -e "${BOLD_CYAN}┌─────────────────────────────────────────────────────────┐"
    echo -e "│ ${WHITE}MODEL SELECTION${BOLD_CYAN}                                          "
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "${BOLD_WHITE}Choose models to download for DiffuGen${NC}"
    echo
    
    # Create model directories
    mkdir -p "stable-diffusion.cpp/models/flux"
    if [ $? -ne 0 ]; then
        print_color "BOLD_RED" "Failed to create model directories" "error"
        set_critical_operation false
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
    echo -e "│ ${WHITE}Available Models${BOLD_PURPLE}                                         "
    echo -e "└─────────────────────────────────────────────────────────┘${NC}"
    echo
    print_color "BOLD_CYAN" "Select models to download:" "info"
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
    echo -e "${BOLD_WHITE}Enter the numbers of models to download (comma-separated), 'a' for all, or just press Enter to cancel:${NC}"
    echo -ne "${YELLOW}> ${BOLD_PURPLE}"
    read model_selection
    echo -ne "${NC}"
    
    # Handle empty input gracefully
    if [ -z "$model_selection" ]; then
        print_color "YELLOW" "No models selected. Returning to main menu." "info"
        return 0  # Return success (0) to avoid triggering error handling
    fi
    
    if [[ $model_selection == "a" || $model_selection == "A" ]]; then
        animate_text "Selecting all models..." "BOLD_GREEN"
        for i in "${!models[@]}"; do
                selected+=($i)
        done
    else
        for choice in $model_selection; do
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
    
    # Check if any models were selected
    if [ ${#selected[@]} -eq 0 ]; then
        print_color "BOLD_RED" "No models selected. Aborting download." "error"
        set_critical_operation false
        return 1
    fi
    
    echo
    print_color "BOLD_CYAN" "Download Summary" "subheader"
    echo -e "${BOLD_WHITE}Selected models to download:${NC}"
    
    for idx in "${selected[@]}"; do
        IFS=':' read -r name url description <<< "${models[$idx]}"
        echo -e "${BOLD_GREEN}• ${WHITE}$name${NC}"
        sleep 0.1
    done
    
    echo
    print_color "BOLD_YELLOW" "Starting downloads..." "info"
    echo -e "${BOLD_CYAN}This may take a while depending on your internet connection and model sizes.${NC}"
    echo
    
    # Clear any leftover progress bars or spinners
    echo -ne "\033[2K\r"
    
    # Track overall success
    local all_downloads_successful=true
    
    for idx in "${selected[@]}"; do
        IFS=':' read -r name url description <<< "${models[$idx]}"
        
        # Process URL with better validation
        echo -e "${BOLD_CYAN}Processing URL for ${WHITE}$name${NC}"

        # Validate URL format before proceeding
        if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ ]]; then
            if [[ "$url" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ ]]; then
                # URL is missing protocol
                url="https://$url"
                print_color "YELLOW" "Added https:// prefix to URL" "info"
            else
                print_color "RED" "Invalid URL format: $url" "error"
                print_color "YELLOW" "URL must be a valid web address starting with http:// or https://" "warning"
                all_downloads_successful=false
                continue
            fi
        fi

        echo -e "${BOLD_CYAN}Final URL: ${WHITE}$url${NC}"
        
        # Final validation check
        if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/ ]]; then
            echo -e "${BOLD_RED}❌ Invalid URL format: ${WHITE}$url${NC}"
            echo -e "${BOLD_RED}Please check the model definition and try again.${NC}"
            all_downloads_successful=false
            continue
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
            dest_path="stable-diffusion.cpp/models/sdxl_vae-fp16-fix.safetensors"
        elif [[ $name == "sd15" ]]; then
            dest_path="stable-diffusion.cpp/models/v1-5-pruned-emaonly.safetensors"
        elif [[ $name == "sd3" ]]; then
            dest_path="stable-diffusion.cpp/models/sd3_medium_incl_clips_t5xxlfp16.safetensors"
        else
            dest_path="stable-diffusion.cpp/models/$filename"
        fi
        
        # Full path debugging (using absolute path)
        local full_path="$(realpath .)/$(realpath --relative-to="$(pwd)" "$dest_path")"
        echo -e "${BOLD_CYAN}Full destination path: ${WHITE}$full_path${NC}"
    
    # Check if file already exists
        if [ -f "$dest_path" ]; then
            echo -e "${BOLD_BLUE}┌─────────────────────────────────────────────────────────┐"
            echo -e "│ ${WHITE}File already exists: ${BOLD_CYAN}$name${BOLD_BLUE}                               "
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
        echo -e "${BOLD_WHITE}────────────────────────────────────────────────────────────────────────${NC}"
        
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
        
        # Download the file using our download_file function
        if ! download_file "$url" "$dest_path" "$name" 3; then
            print_color "BOLD_RED" "Failed to download $name. Please try again later." "error"
            all_downloads_successful=false
            continue
        fi
        
        echo
    done
    
    # After all downloads, verify that files were actually saved
    echo -e "${BOLD_CYAN}Verifying downloaded models...${NC}"
    echo -e "${BOLD_WHITE}Checking models directory: stable-diffusion.cpp/models/${NC}"
    ls -la stable-diffusion.cpp/models/ || print_color "BOLD_RED" "Failed to list models directory." "error"
    
    # Reset critical operation at the end
    set_critical_operation false
    
    echo
    if [ "$all_downloads_successful" = true ]; then
        print_color "BOLD_GREEN" "✅ All models downloaded successfully! ✅" "success"
            return 0
        else
        print_color "BOLD_YELLOW" "⚠ Some downloads failed. Please try again later." "warning"
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
    echo

    echo -e "${YELLOW}1.  Install dependencies${NC} ${CYAN}(~2 min)${NC}"
    echo -e "   ${WHITE}Install required packages for building and running DiffuGen${NC}"
    
    echo -e "${YELLOW}2.  Clone/update stable-diffusion.cpp${NC} ${CYAN}(~1 min)${NC}"
    echo -e "   ${WHITE}Get or update the core stable-diffusion.cpp code repository${NC}"
    
    echo -e "${YELLOW}3.  Build stable-diffusion.cpp${NC} ${CYAN}(~10-20 min)${NC}"
    echo -e "   ${WHITE}Compile the stable-diffusion.cpp library - CPU intensive${NC}"
    
    echo -e "${YELLOW}4.  Set up Python environment${NC} ${CYAN}(~2 min)${NC}"
    echo -e "   ${WHITE}Create virtual environment and install Python dependencies${NC}"
    
    echo -e "${YELLOW}5.  Update configuration files${NC} ${CYAN}(~1 min)${NC}"
    echo -e "   ${WHITE}Configure file paths for your system${NC}"
    
    echo
    echo -e "${BOLD_YELLOW}6.  Run all steps ${PURPLE}(recommended)${NC}"
    echo -e "   ${WHITE}Complete setup with core components (steps 1-5)${NC}"
    
    echo
    echo -e "${CYAN}7.  Download models${NC} ${CYAN}(long process - may take hours)${NC}"
    echo -e "   ${WHITE}Download Stable Diffusion models (several GB of data)${NC}"
    
    echo -e "${YELLOW}8.  ${YELLOW}Model Manager${NC}"
    echo -e "   ${WHITE}Manage, view, and clean up downloaded models${NC}"
    
    echo -e "${PURPLE}9.  ${BOLD_PURPLE}Display Guide${NC}"
    echo -e "   ${WHITE}View comprehensive usage instructions${NC}"
    
    echo -e "${CYAN}10. ${BOLD_CYAN}Clean up partial downloads${NC}"
    echo -e "    ${WHITE}Find and remove incomplete or partial downloads${NC}"
    
    echo -e "${RED}11. ${BOLD_RED}Exit${NC}"
    echo
    
    echo -ne "${YELLOW}Enter your choice ${BOLD_PURPLE}(${BOLD_PURPLE}1${BOLD_PURPLE}-${BOLD_PURPLE}11${BOLD_PURPLE}): ${BOLD_PURPLE}"
    read choice
    echo -ne "${NC}"
    echo
    
    case $choice in
        1)
            # Before installing dependencies, make sure we can detect system properly
            detect_os
            run_with_error_handling "Installing dependencies" "dependencies" install_dependencies
            read -p "Press Enter to continue..."  # Add this back
            display_tui_menu
            ;;
        2)
            # Remove duplicate dependency check to fix the issue
            run_with_error_handling "Setting up stable-diffusion.cpp" "repository" setup_stable_diffusion_cpp
            read -p "Press Enter to continue..."  # Add this back
            display_tui_menu
            ;;
        3)
            run_with_error_handling "Building stable-diffusion.cpp" "build" build_stable_diffusion_cpp
            read -p "Press Enter to continue..."  # Add this back
            display_tui_menu
            ;;
        4)
            run_with_error_handling "Setting up Python environment" "" setup_venv
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        5)
            run_with_error_handling "Updating configuration files" "" update_file_paths
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        6)
            run_with_error_handling "Installing dependencies" "" install_dependencies
            run_with_error_handling "Setting up stable-diffusion.cpp" "" setup_stable_diffusion_cpp
            run_with_error_handling "Building stable-diffusion.cpp" "" build_stable_diffusion_cpp
            run_with_error_handling "Setting up Python environment" "" setup_venv
            run_with_error_handling "Updating configuration files" "" update_file_paths
            
            # Core setup complete message
            echo
            print_color "BOLD_GREEN" "✅ DiffuGen core setup complete! ✅" "success"
            echo
            print_color "BOLD_YELLOW" "You can now use option 7 to download models when ready." "info"
            print_color "BOLD_YELLOW" "Models are large files (1-10GB each) and may take a long time to download." "info"
            
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        7)
            # Run model_selection_menu directly
            model_selection_menu
            # Check return code but don't trigger error handling for cancellation
            if [ $? -ne 0 ]; then
                print_color "YELLOW" "Model download was cancelled or failed." "info"
            fi
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        8)
            run_with_error_handling "Managing models" "" model_manager
            display_tui_menu
            ;;
        9)
            show_completion_guide            
            # Return to the menu with full logo display
            MENU_DISPLAYED=""
            display_tui_menu
            ;;    
        10)
            run_with_error_handling "Cleaning up partial downloads" "" cleanup_partial_downloads
            read -p "Press Enter to continue..."
            display_tui_menu
            ;;
        11)
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

# Model Manager function
model_manager() {
    # Set MODELS_DIR if not already set
    if [ -z "$MODELS_DIR" ]; then
        MODELS_DIR="./stable-diffusion.cpp/models"
    fi
    
    local submenu_choice
    local exit_submenu=false
    
    while [ "$exit_submenu" = false ]; do
        clear
        print_color "BOLD_CYAN" "MODEL MANAGER" "header"
        echo -e "${BOLD_WHITE}Manage your installed models${NC}"
        echo
        
        # Check if the models directory exists
        if [ ! -d "$MODELS_DIR" ]; then
            print_color "YELLOW" "Models directory not found at: $MODELS_DIR" "warning"
            echo -e "${BOLD_WHITE}Would you like to create it?${NC}"
            read -p "$(echo -e ${BOLD_YELLOW}Create models directory? \(y/n\)${NC} )" -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$MODELS_DIR"
                if [ -d "$MODELS_DIR" ]; then
                    print_color "BOLD_GREEN" "✓ Models directory created successfully" "success"
                else
                    print_color "BOLD_RED" "✗ Failed to create models directory" "error"
                    read -p "Press Enter to return to main menu..."
                    return 1
                fi
            else
                print_color "YELLOW" "Models directory is required for model management." "warning"
                read -p "Press Enter to return to main menu..."
                return 1
            fi
        fi
        
        # Display the submenu
        echo -e "${BOLD_PURPLE}===== Model Management Options ====="
        echo -e "${YELLOW}1.  View installed models"
        echo -e "${YELLOW}2.  Delete models"
        echo -e "${YELLOW}3.  Check model integrity"
        echo -e "${YELLOW}4.  View detailed model information"
        echo -e "${RED}5.  Return to main menu"
        echo
        
        echo -ne "${YELLOW}Enter your choice ${BOLD_PURPLE}(${BOLD_PURPLE}1${BOLD_PURPLE}-${BOLD_PURPLE}5${BOLD_PURPLE}): ${BOLD_PURPLE}"
        read submenu_choice
        echo -ne "${NC}"
        echo
        
        case $submenu_choice in
            1)
                view_installed_models
                ;;
            2)
                delete_model
                ;;
            3)
                check_model_integrity
                ;;
            4)
                view_model_details
                ;;
            5)
                exit_submenu=true
                ;;
            *)
                print_color "RED" "Invalid choice. Please try again." "error"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to view installed models
view_installed_models() {
    clear
    print_color "BOLD_CYAN" "INSTALLED MODELS" "header"
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "RED" "Models directory not found at: $MODELS_DIR" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Count models
    local model_count=0
    local total_size=0
    
    # Define table width and column widths
    local table_width=80  # Increased overall table width
    local num_width=3
    local name_width=35   # Increased model name width
    local size_width=10
    local type_width=15
    local status_width=10
    
    # Header for the table
    echo -e "${BOLD_WHITE}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}Models found in:${BOLD_WHITE} $MODELS_DIR${NC}$(printf '%*s' $((table_width - 17 - ${#MODELS_DIR})) "")${BOLD_WHITE}${NC}"
    echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}#${NC}$(printf '%*s' $num_width "")${BOLD_YELLOW}Model Name${NC}$(printf '%*s' $((name_width - 10)) "") ${BOLD_GREEN}Size${NC}$(printf '%*s' $((size_width - 4)) "") ${BOLD_BLUE}Type${NC}$(printf '%*s' $((type_width - 4)) "") ${BOLD_CYAN}Status${NC}$(printf '%*s' $((status_width - 6)) "")${BOLD_WHITE}${NC}"
    echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Find all model files in the directory and subdirectories (include .gguf and .sft extensions)
    local model_files=($(find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.gguf" -o -name "*.sft" \) 2>/dev/null | sort))
    
    if [ ${#model_files[@]} -eq 0 ]; then
        echo -e "${BOLD_WHITE}║ ${YELLOW}No model files found${NC}$(printf '%*s' $((table_width - 20)) "")${BOLD_WHITE}${NC}"
    else
        # Loop through each model file
        for ((i=0; i<${#model_files[@]}; i++)); do
            local file="${model_files[$i]}"
            local filename=$(basename "$file")
            local rel_path=${file#"$MODELS_DIR/"}
            
            # Get file size
            local size=$(du -h "$file" | cut -f1)
            local size_bytes=$(du -b "$file" | cut -f1)
            total_size=$((total_size + size_bytes))
            
            # Determine model type
            local model_type=""
            if [[ "$filename" == *"flux"* || "$rel_path" == *"flux/"* || "$filename" == *".gguf" ]]; then
                model_type="Flux"
            elif [[ "$filename" == *"sdxl"* ]]; then
                model_type="SDXL"
            elif [[ "$filename" == *"sd15"* || "$filename" == *"v1-5"* ]]; then
                model_type="SD 1.5"
            elif [[ "$filename" == *"sd3"* ]]; then
                model_type="SD 3"
            elif [[ "$filename" == *"control"* ]]; then
                model_type="ControlNet"
            elif [[ "$filename" == *"lora"* ]]; then
                model_type="LoRA"
            elif [[ "$filename" == *"clip"* ]]; then
                model_type="CLIP"
            elif [[ "$filename" == *"vae"* || "$filename" == *"ae.sft" ]]; then
                model_type="VAE"
            else
                model_type="Standard"
            fi
            
            # Check if the file is complete (simple check)
            local status="OK"
            local status_color="${BOLD_GREEN}"
            if [[ "$filename" == *.part || "$size_bytes" -lt 10000 ]]; then
                status="Incomplete"
                status_color="${BOLD_RED}"
            fi
            
            # Trim filename if too long
            if [ ${#filename} -gt $((name_width - 3)) ]; then
                filename="${filename:0:$((name_width - 6))}..."
            fi
            
            # Print the model information in table format with proper alignment
            echo -e "${BOLD_WHITE}║${NC} ${BOLD_PURPLE}$(($i+1))${NC}$(printf '%*s' $((num_width - ${#i})) "") ${BOLD_YELLOW}${filename}${NC}$(printf '%*s' $((name_width - ${#filename})) "") ${BOLD_GREEN}${size}${NC}$(printf '%*s' $((size_width - ${#size})) "") ${BOLD_BLUE}${model_type}${NC}$(printf '%*s' $((type_width - ${#model_type})) "") ${status_color}${status}${NC}$(printf '%*s' $((status_width - ${#status})) "")${BOLD_WHITE}${NC}"
            
            model_count=$((model_count + 1))
        done
    fi
    
    # Format total size for human readability
    local total_size_human=""
    if [ $total_size -ge 1073741824 ]; then # 1 GB or more
        total_size_human=$(echo "scale=2; $total_size/1073741824" | bc)" GB"
    elif [ $total_size -ge 1048576 ]; then # 1 MB or more
        total_size_human=$(echo "scale=2; $total_size/1048576" | bc)" MB"
    elif [ $total_size -ge 1024 ]; then # 1 KB or more
        total_size_human=$(echo "scale=2; $total_size/1024" | bc)" KB"
    else
        total_size_human="$total_size bytes"
    fi
    
    # Footer for the table
    echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Total:${NC} ${model_count} models, ${BOLD_CYAN}Total size:${NC} ${total_size_human}$(printf '%*s' $((table_width - 22 - ${#model_count} - ${#total_size_human})) "")${BOLD_WHITE}${NC}"
    echo -e "${BOLD_WHITE}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to delete a model
delete_model() {
    clear
    print_color "BOLD_CYAN" "DELETE MODELS" "header"
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "RED" "Models directory not found at: $MODELS_DIR" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Find all model files in the directory and subdirectories
    local model_files=($(find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.gguf" -o -name "*.sft" \) 2>/dev/null | sort))
    
    if [ ${#model_files[@]} -eq 0 ]; then
        print_color "YELLOW" "No model files found in: $MODELS_DIR" "warning"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Display model list for selection
    echo -e "${BOLD_WHITE}Available models to delete:${NC}"
    echo
    
    for ((i=0; i<${#model_files[@]}; i++)); do
        local file="${model_files[$i]}"
        local filename=$(basename "$file")
        local rel_path=${file#"$MODELS_DIR/"}
        local size=$(du -h "$file" | cut -f1)
        
        echo -e "${BOLD_PURPLE}$(($i+1))${NC}. ${BOLD_YELLOW}${rel_path}${NC} (${BOLD_GREEN}${size}${NC})"
    done
    
    echo
    echo -e "${BOLD_WHITE}Enter the number of the model to delete, or${NC}"
    echo -e "${BOLD_WHITE}Enter 'all' to delete all models, or${NC}"
    echo -e "${BOLD_WHITE}Enter 0 to cancel${NC}"
    echo -ne "${YELLOW}Your choice: ${BOLD_PURPLE}"
    read delete_choice
    echo -ne "${NC}"
    
    if [[ "$delete_choice" == "0" ]]; then
        print_color "YELLOW" "Operation cancelled." "warning"
        read -p "Press Enter to continue..."
        return 0
    elif [[ "$delete_choice" == "all" ]]; then
        echo
        print_color "RED" "⚠️  WARNING: You are about to delete ALL model files!" "error"
        print_color "RED" "This action cannot be undone." "error"
        echo
        read -p "$(echo -e ${BOLD_RED}Are you ABSOLUTELY SURE you want to delete ALL models? \(yes/no\)${NC} )" confirm
        
        if [[ "$confirm" == "yes" ]]; then
            echo
            print_color "YELLOW" "Deleting all model files..." "warning"
            local success_count=0
            local fail_count=0
            
            for file in "${model_files[@]}"; do
                echo -ne "${YELLOW}Deleting: ${CYAN}$(basename "$file")${NC}... "
                
                if rm "$file"; then
                    echo -e "${BOLD_GREEN}✓${NC}"
                    success_count=$((success_count + 1))
                else
                    echo -e "${BOLD_RED}✗${NC}"
                    fail_count=$((fail_count + 1))
                fi
            done
            
            echo
            print_color "BOLD_GREEN" "Deletion complete: $success_count files deleted successfully, $fail_count failed" "success"
            read -p "Press Enter to continue..."
        else
            print_color "YELLOW" "Operation cancelled." "warning"
            read -p "Press Enter to continue..."
        fi
    else
        # Convert to integer and check if valid
        delete_choice=$(echo "$delete_choice" | tr -d ' ')
        
        if ! [[ "$delete_choice" =~ ^[0-9]+$ ]]; then
            print_color "RED" "Invalid choice. Please enter a number." "error"
            read -p "Press Enter to continue..."
            return 1
        fi
        
        delete_index=$((delete_choice - 1))
        
        if [ $delete_index -lt 0 ] || [ $delete_index -ge ${#model_files[@]} ]; then
            print_color "RED" "Invalid selection. Please choose a number between 1 and ${#model_files[@]}" "error"
            read -p "Press Enter to continue..."
            return 1
        fi
        
        local selected_file="${model_files[$delete_index]}"
        local selected_filename=$(basename "$selected_file")
        
        echo
        print_color "YELLOW" "You selected: $selected_filename" "warning"
        local file_size=$(du -h "$selected_file" | cut -f1)
        echo -e "${BOLD_WHITE}Path: ${CYAN}$selected_file${NC}"
        echo -e "${BOLD_WHITE}Size: ${CYAN}$file_size${NC}"
        echo
        
        read -p "$(echo -e ${BOLD_YELLOW}Are you sure you want to delete this model? \(y/n\)${NC} )" -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            print_color "YELLOW" "Deleting model: $selected_filename" "warning"
            
            if rm "$selected_file"; then
                print_color "BOLD_GREEN" "✓ Model deleted successfully" "success"
            else
                print_color "BOLD_RED" "✗ Failed to delete model" "error"
            fi
            
            read -p "Press Enter to continue..."
        else
            print_color "YELLOW" "Operation cancelled." "warning"
            read -p "Press Enter to continue..."
        fi
    fi
}

# Function to check model integrity
check_model_integrity() {
    clear
    print_color "BOLD_CYAN" "CHECK MODEL INTEGRITY" "header"
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "RED" "Models directory not found at: $MODELS_DIR" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Find all model files in the directory and subdirectories
    local model_files=($(find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.gguf" -o -name "*.sft" \) 2>/dev/null | sort))
    
    if [ ${#model_files[@]} -eq 0 ]; then
        print_color "YELLOW" "No model files found in: $MODELS_DIR" "warning"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Ask user whether to check all models or select one
    echo -e "${BOLD_WHITE}Options:${NC}"
    echo -e "${BOLD_PURPLE}1${NC}. ${BOLD_YELLOW}Check all models${NC} (slower but thorough)"
    echo -e "${BOLD_PURPLE}2${NC}. ${BOLD_YELLOW}Select a specific model${NC} to check"
    echo -e "${BOLD_PURPLE}0${NC}. ${BOLD_YELLOW}Cancel${NC} and return to previous menu"
    echo
    
    echo -ne "${YELLOW}Your choice: ${BOLD_PURPLE}"
    read integrity_choice
    echo -ne "${NC}"
    
    case $integrity_choice in
        0)
            print_color "YELLOW" "Operation cancelled." "warning"
            read -p "Press Enter to continue..."
            return 0
            ;;
        1)
            echo
            print_color "YELLOW" "Checking all models (this may take some time)..." "info"
            local issues_found=0
            local checked_count=0
            
            # Create a table header for results
            echo -e "${BOLD_WHITE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}Model Integrity Check Results${BOLD_WHITE}                  ${NC}"
            echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_YELLOW}Model Name                     ${BOLD_GREEN}Size       ${BOLD_BLUE}Status        ${BOLD_WHITE}${NC}"
            echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
            
            for file in "${model_files[@]}"; do
                local filename=$(basename "$file")
                local file_size=$(du -h "$file" | cut -f1)
                local size_bytes=$(du -b "$file" | cut -f1)
                
                # Trim filename if too long
                if [ ${#filename} -gt 28 ]; then
                    display_name="${filename:0:25}..."
                else
                    display_name="$filename"
                fi
                
                echo -ne "${BOLD_WHITE}║ ${BOLD_YELLOW}${display_name}${NC}$(printf '%*s' $((30 - ${#display_name})) "") ${BOLD_GREEN}${file_size}${NC}$(printf '%*s' $((12 - ${#file_size})) "") ${BOLD_BLUE}Checking...${NC}$(printf '%*s' $((8)) "") ${BOLD_WHITE}${NC}\r"
                
                # Basic integrity check
                local integrity_status="OK"
                local status_color="${BOLD_GREEN}"
                
                # Check for zero or very small file size
                if [ $size_bytes -lt 1000 ]; then
                    integrity_status="Empty"
                    status_color="${BOLD_RED}"
                    issues_found=$((issues_found + 1))
                fi
                
                # Check for incomplete downloads (.part files)
                if [[ "$filename" == *.part ]]; then
                    integrity_status="Incomplete"
                    status_color="${BOLD_RED}"
                    issues_found=$((issues_found + 1))
                fi
                
                # Check file is readable
                if ! cat "$file" &> /dev/null; then
                    integrity_status="Unreadable"
                    status_color="${BOLD_RED}"
                    issues_found=$((issues_found + 1))
                fi
                
                # Display result for this file
                echo -e "${BOLD_WHITE}║ ${BOLD_YELLOW}${display_name}${NC}$(printf '%*s' $((30 - ${#display_name})) "") ${BOLD_GREEN}${file_size}${NC}$(printf '%*s' $((12 - ${#file_size})) "") ${status_color}${integrity_status}${NC}$(printf '%*s' $((15 - ${#integrity_status})) "") ${BOLD_WHITE}${NC}"
                
                checked_count=$((checked_count + 1))
            done
            
            # Display summary
            echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
            if [ $issues_found -eq 0 ]; then
                echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}All models passed integrity check ($checked_count files checked)${NC}$(printf '%*s' $((23 - ${#checked_count})) "") ${BOLD_WHITE}${NC}"
            else
                echo -e "${BOLD_WHITE}║ ${BOLD_RED}Issues found in $issues_found files${NC} (out of $checked_count checked)$(printf '%*s' $((28 - ${#issues_found} - ${#checked_count})) "") ${BOLD_WHITE}${NC}"
            fi
            echo -e "${BOLD_WHITE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
            
            echo
            read -p "Press Enter to continue..."
            ;;
        2)
            # Display a list of models for the user to select
            echo
            echo -e "${BOLD_WHITE}Select a model to check:${NC}"
            echo
            
            for ((i=0; i<${#model_files[@]}; i++)); do
                local file="${model_files[$i]}"
                local filename=$(basename "$file")
                local rel_path=${file#"$MODELS_DIR/"}
                local size=$(du -h "$file" | cut -f1)
                
                echo -e "${BOLD_PURPLE}$(($i+1))${NC}. ${BOLD_YELLOW}${rel_path}${NC} (${BOLD_GREEN}${size}${NC})"
            done
            
            echo
            echo -ne "${YELLOW}Enter the number of the model to check: ${BOLD_PURPLE}"
            read model_number
            echo -ne "${NC}"
            
            # Validate input
            if ! [[ "$model_number" =~ ^[0-9]+$ ]]; then
                print_color "RED" "Invalid choice. Please enter a number." "error"
                read -p "Press Enter to continue..."
                return 1
            fi
            
            model_index=$((model_number - 1))
            
            if [ $model_index -lt 0 ] || [ $model_index -ge ${#model_files[@]} ]; then
                print_color "RED" "Invalid selection. Please choose a number between 1 and ${#model_files[@]}" "error"
                read -p "Press Enter to continue..."
                return 1
            fi
            
            local selected_file="${model_files[$model_index]}"
            local selected_filename=$(basename "$selected_file")
            local file_size=$(du -h "$selected_file" | cut -f1)
            local size_bytes=$(du -b "$selected_file" | cut -f1)
            
            echo
            print_color "YELLOW" "Checking model: $selected_filename" "info"
            echo -e "${BOLD_WHITE}Path: ${CYAN}$selected_file${NC}"
            echo -e "${BOLD_WHITE}Size: ${CYAN}$file_size${NC}"
            echo
            
            # Perform more detailed integrity check on the single selected file
            print_color "BLUE" "Running integrity checks..." "info"
            echo
            
            # Start a spinner animation
            echo -ne "${BOLD_CYAN}Checking file integrity...${NC} "
            
            # Check is readable
            if ! cat "$selected_file" &> /dev/null; then
                echo -e "${BOLD_RED}✗ File not readable${NC}"
                local integrity_issue=true
            else
                echo -e "${BOLD_GREEN}✓ File is readable${NC}"
            fi
            
            # Check for zero or very small file size
            echo -ne "${BOLD_CYAN}Checking file size...${NC} "
            if [ $size_bytes -lt 1000 ]; then
                echo -e "${BOLD_RED}✗ File is too small ($size_bytes bytes)${NC}"
                local integrity_issue=true
            else
                echo -e "${BOLD_GREEN}✓ File size appears normal${NC}"
            fi
            
            # Check file format based on extension
            echo -ne "${BOLD_CYAN}Validating file format...${NC} "
            if [[ "$selected_filename" == *.safetensors ]]; then
                # Better check for safetensors format - looking for JSON header
                # SafeTensors files start with a JSON header which will contain certain patterns
                if hexdump -n 128 "$selected_file" | grep -q "metadata" || \
                   file "$selected_file" | grep -q "data" || \
                   head -c 256 "$selected_file" 2>/dev/null | grep -q -E "tensor|dtype|shape"; then
                    echo -e "${BOLD_GREEN}✓ File format appears valid${NC}"
                else
                    echo -e "${BOLD_RED}✗ File format may be invalid${NC}"
                    local integrity_issue=true
                fi
            elif [[ "$selected_filename" == *.pth || "$selected_filename" == *.ckpt ]]; then
                # Basic check for PyTorch files
                if file "$selected_file" | grep -q -i "data"; then
                    echo -e "${BOLD_GREEN}✓ File format appears valid${NC}"
                else
                    echo -e "${BOLD_RED}✗ File format may be invalid${NC}"
                    local integrity_issue=true
                fi
            else
                echo -e "${BOLD_YELLOW}⚠ Unable to verify format for this file type${NC}"
            fi
            
            # Check file permissions
            echo -ne "${BOLD_CYAN}Checking permissions...${NC} "
            if [ -r "$selected_file" ]; then
                echo -e "${BOLD_GREEN}✓ File is readable${NC}"
            else
                echo -e "${BOLD_RED}✗ File is not readable${NC}"
                local integrity_issue=true
            fi
            
            echo
            
            # Display final result
            if [ "$integrity_issue" = true ]; then
                echo -e "${BOLD_RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${BOLD_RED}║ ⚠️  Issues detected with this model file!                           ║${NC}"
                echo -e "${BOLD_RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
                echo
                print_color "YELLOW" "Recommendations:" "warning"
                echo -e "${BOLD_WHITE}• Try re-downloading the model${NC}"
                echo -e "${BOLD_WHITE}• Check disk for errors${NC}"
                echo -e "${BOLD_WHITE}• Ensure you have sufficient permissions${NC}"
            else
                echo -e "${BOLD_GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${BOLD_GREEN}║ ✅ Model appears to be valid and intact!                           ║${NC}"
                echo -e "${BOLD_GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
            fi
            
            echo
            read -p "Press Enter to continue..."
            ;;
        *)
            print_color "RED" "Invalid choice. Please try again." "error"
            read -p "Press Enter to continue..."
            return 1
            ;;
    esac
}

# Function to view detailed model information
view_model_details() {
    clear
    echo -e "${BOLD_PURPLE}══════════════════════════ MODEL DETAILS ══════════════════════════════${NC}"
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "RED" "Models directory not found at: $MODELS_DIR" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Find all model files in the directory and subdirectories
    local model_files=($(find "$MODELS_DIR" -type f \( -name "*.safetensors" -o -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.gguf" -o -name "*.sft" \) 2>/dev/null | sort))
    
    if [ ${#model_files[@]} -eq 0 ]; then
        print_color "YELLOW" "No model files found in: $MODELS_DIR" "warning"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Display a list of models for the user to select
    echo -e "${BOLD_WHITE}Select a model to view detailed information:${NC}"
    echo
    
    for ((i=0; i<${#model_files[@]}; i++)); do
        local file="${model_files[$i]}"
        local filename=$(basename "$file")
        local rel_path=${file#"$MODELS_DIR/"}
        local size=$(du -h "$file" | cut -f1)
        
        echo -e "${BOLD_PURPLE}$(($i+1))${NC}. ${BOLD_YELLOW}${rel_path}${NC} (${BOLD_GREEN}${size}${NC})"
    done
    
    echo
    echo -ne "${YELLOW}Enter the number of the model: ${BOLD_PURPLE}"
    read model_number
    echo -ne "${NC}"
    
    # Validate input
    if ! [[ "$model_number" =~ ^[0-9]+$ ]]; then
        print_color "RED" "Invalid choice. Please enter a number." "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    model_index=$((model_number - 1))
    
    if [ $model_index -lt 0 ] || [ $model_index -ge ${#model_files[@]} ]; then
        print_color "RED" "Invalid selection. Please choose a number between 1 and ${#model_files[@]}" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    local selected_file="${model_files[$model_index]}"
    
    clear
    echo -e "${BOLD_PURPLE}══════════════════════════ MODEL DETAILS ════════════════════════════${NC}"
    
    # Gather detailed information about the model
    local filename=$(basename "$selected_file")
    local filepath=$(dirname "$selected_file")
    local rel_path=${selected_file#"$MODELS_DIR/"}
    local size_human=$(du -h "$selected_file" | cut -f1)
    local size_bytes=$(du -b "$selected_file" | cut -f1)
    local last_modified=$(date -r "$selected_file" "+%Y-%m-%d %H:%M:%S")
    local file_type=$(file -b "$selected_file" | head -c 50)
    local permissions=$(ls -l "$selected_file" | awk '{print $1}')
    local owner=$(ls -l "$selected_file" | awk '{print $3}')
    
    # Get file extension safely
    local file_ext="${filename##*.}"
    # Safely handle filename with no extension
    if [ "$file_ext" = "$filename" ]; then
        file_ext="none"
    fi
    
    # Determine model type
    local model_type=""
    if [[ "$filename" == *"sdxl"* ]]; then
        model_type="Stable Diffusion XL"
    elif [[ "$filename" == *"sd15"* || "$filename" == *"v1-5"* ]]; then
        model_type="Stable Diffusion 1.5"
    elif [[ "$filename" == *"control"* ]]; then
        model_type="ControlNet"
    elif [[ "$filename" == *"lora"* ]]; then
        model_type="LoRA"
    elif [[ "$filename" == *"clip"* ]]; then
        model_type="CLIP"
    elif [[ "$filename" == *"inpaint"* ]]; then
        model_type="Inpainting"
    elif [[ "$filename" == *"vae"* ]]; then
        model_type="VAE"
    else
        model_type="Standard Diffusion Model"
    fi
    
    # Display model information in a clean, fixed format
    echo -e "${BOLD_WHITE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_YELLOW}MODEL INFORMATION${NC}                                 ${NC}"
    echo -e "${BOLD_WHITE}╠═════════════════════════════════════════════════════════════════════╣${NC}"
    
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Model Name:${NC}      ${BOLD_CYAN}$filename"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Model Type:${NC}      ${BOLD_CYAN}$model_type"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}File Format:${NC}     ${BOLD_CYAN}$file_ext${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Location:${NC}        ${BOLD_CYAN}$filepath"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Relative Path:${NC}   ${BOLD_CYAN}$rel_path"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Size:${NC}            ${BOLD_CYAN}$size_human ($size_bytes bytes)"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Permissions:${NC}     ${BOLD_CYAN}$permissions${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}Owner:${NC}           ${BOLD_CYAN}$owner"
    echo -e "${BOLD_WHITE}║ ${BOLD_PURPLE}File Type:${NC}       ${BOLD_CYAN}$file_type${NC}"
    
    echo -e "${BOLD_WHITE}╠═════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_YELLOW}USAGE INFORMATION${NC}                                 ${NC}"
    echo -e "${BOLD_WHITE}╠═════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Display usage examples based on model type
    case $model_type in
        "Stable Diffusion XL")
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Example usage:${NC}${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}./diffugen.sh \"your prompt\" --model sdxl --steps 30${NC}${NC}"
            echo -e "${BOLD_WHITE}║                                                               ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Recommended settings:${NC}                       ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}--cfg-scale 7.5 --steps 30-50 --width 1024 --height 1024${NC}${NC}"
            ;;
        "Stable Diffusion 1.5")
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Example usage:${NC}${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}./diffugen.sh \"your prompt\" --model sd15 --steps 25${NC}${NC}"
            echo -e "${BOLD_WHITE}║                                                                ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Recommended settings:${NC}${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}--cfg-scale 7.0 --steps 20-30 --width 512 --height 512${NC}${NC}"
            ;;
        "ControlNet")
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Example usage:${NC}${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}./diffugen.sh \"your prompt\" --controlnet \"image.png\"${NC}${NC}"
            echo -e "${BOLD_WHITE}║                                                                 ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Recommended settings:${NC}                         ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}--controlnet-scale 0.8 --controlnet-type canny${NC} ${NC}"
            ;;
        "CLIP")
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Example usage:${NC}${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}./diffugen.sh \"your prompt\" --clip-model \"$rel_path\"${NC}${NC}"
            echo -e "${BOLD_WHITE}║                                                                  ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Recommended settings:${NC}                          ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}Used internally by models for text encoding${NC}     ${NC}"
            ;;
        *)
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Example usage:${NC}                                 ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}./diffugen.sh \"your prompt\" --model custom --model-path \"$rel_path\"${NC}${NC}"
            echo -e "${BOLD_WHITE}║                                                                  ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_GREEN}Recommended settings:${NC}                          ${NC}"
            echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}Consult documentation for specific usage recommendations${NC}${NC}"
            ;;
    esac
    
    echo -e "${BOLD_WHITE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    read -p "Press Enter to continue..."
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
    if [ "$CURRENT_OPERATION" = "download" ] && [ -n "$current_model_name" ]; then
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
                    print_color "BOLD_GREEN" "✓ Incomplete download file removed successfully" "success"
                    cleaned_items+=("Incomplete download of $current_model_name")
                else
                    print_color "BOLD_RED" "✗ Failed to remove the incomplete download file" "error"
                fi
            else
                print_color "YELLOW" "Keeping incomplete download file. You can try to resume the download later." "info"
            fi
        else
            # Check for any potential partial files related to this download
            local partial_dir="$(dirname "$current_download_file")"
            local partial_base="$(basename "$current_download_file" | cut -d. -f1)"
            local partial_files=($(find "$partial_dir" -name "${partial_base}*.part" 2>/dev/null))
            
            if [ ${#partial_files[@]} -gt 0 ]; then
                print_color "YELLOW" "Found partial download files that may be incomplete:" "info"
                for partial_file in "${partial_files[@]}"; do
                    echo -e "${BOLD_WHITE}Path: ${CYAN}$partial_file${NC}"
                    
                    # Get file size in a human-readable format
                    local file_size=$(du -h "$partial_file" 2>/dev/null | cut -f1)
                    if [ -n "$file_size" ]; then
                        echo -e "${BOLD_WHITE}Size: ${CYAN}$file_size${NC}"
                    fi
                done
                
                echo
                read -p "$(echo -e ${BOLD_YELLOW}Would you like to remove these incomplete download files? \(y/n\)${NC} )" -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo
                    print_color "YELLOW" "Removing incomplete download files..." "info"
                    local removed=0
                    for partial_file in "${partial_files[@]}"; do
                        rm -f "$partial_file"
                        if [ ! -f "$partial_file" ]; then
                            removed=$((removed + 1))
                        fi
                    done
                    print_color "BOLD_GREEN" "✓ $removed/${#partial_files[@]} incomplete download files removed successfully" "success"
                else
                    print_color "YELLOW" "Keeping incomplete download files. You can try to resume the download later." "info"
                fi
            else
                print_color "YELLOW" "Keeping incomplete download file. You can try to resume the download later." "info"
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

# Function to clean up partial downloads
cleanup_partial_downloads() {
    clear
    print_color "BOLD_CYAN" "CLEAN UP PARTIAL DOWNLOADS" "header"
    
    # Set MODELS_DIR if not already set
    if [ -z "$MODELS_DIR" ]; then
        MODELS_DIR="./stable-diffusion.cpp/models"
    fi
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        print_color "RED" "Models directory not found at: $MODELS_DIR" "error"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${BOLD_WHITE}Searching for partial downloads and incomplete files...${NC}"
    echo
    
    # Find partial download files (*.part files)
    local part_files=($(find "$MODELS_DIR" -type f -name "*.part" 2>/dev/null | sort))
    
    # Find very small files that might be incomplete (less than 10KB)
    local small_files=($(find "$MODELS_DIR" -type f -size -10k \( -name "*.safetensors" -o -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.gguf" -o -name "*.sft" \) 2>/dev/null | sort))
    
    # Merge the lists, avoiding duplicates
    local all_files=()
    for file in "${part_files[@]}"; do
        all_files+=("$file")
    done
    
    for file in "${small_files[@]}"; do
        # Check if the file is not already in the list
        local is_duplicate=false
        for existing in "${all_files[@]}"; do
            if [ "$existing" = "$file" ]; then
                is_duplicate=true
                break
            fi
        done
        
        if [ "$is_duplicate" = false ]; then
            all_files+=("$file")
        fi
    done
    
    # Display results
    if [ ${#all_files[@]} -eq 0 ]; then
        print_color "BOLD_GREEN" "✓ No partial downloads or incomplete files found." "success"
        read -p "Press Enter to continue..."
        return 0
    fi
    
    # Display the found files in a table
    print_color "BOLD_YELLOW" "Found ${#all_files[@]} potential partial downloads or incomplete files:" "warning"
    echo
    
    # Define table
    echo -e "${BOLD_WHITE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_WHITE}║ ${BOLD_CYAN}# ${BOLD_YELLOW}File Path                            ${BOLD_GREEN}Size      ${BOLD_BLUE}Type          ${BOLD_WHITE}${NC}"
    echo -e "${BOLD_WHITE}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Display files in table
    for ((i=0; i<${#all_files[@]}; i++)); do
        local file="${all_files[$i]}"
        local filename=$(basename "$file")
        local rel_path=${file#"$MODELS_DIR/"}
        
        # Get file size
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        if [ -z "$size" ]; then size="unknown"; fi
        
        # Determine file type
        local file_type="Incomplete"
        if [[ "$filename" == *.part ]]; then
            file_type="Partial"
        elif [[ "$filename" == *.gguf ]]; then
            file_type="GGUF"
        elif [[ "$filename" == *.safetensors ]]; then
            file_type="Safetensors"
        elif [[ "$filename" == *.pth ]]; then
            file_type="PyTorch"
        elif [[ "$filename" == *.ckpt ]]; then
            file_type="Checkpoint"
        elif [[ "$filename" == *.bin ]]; then
            file_type="Binary"
        elif [[ "$filename" == *.sft ]]; then
            file_type="SFT"
        fi
        
        # Trim path if too long
        if [ ${#rel_path} -gt 36 ]; then
            rel_path="...${rel_path: -33}"
        fi
        
        # Print table row
        echo -e "${BOLD_WHITE}║${NC} ${BOLD_CYAN}$(($i+1))${NC} ${BOLD_YELLOW}${rel_path}${NC}$(printf '%*s' $((37 - ${#rel_path})) "") ${BOLD_GREEN}${size}${NC}$(printf '%*s' $((10 - ${#size})) "") ${BOLD_BLUE}${file_type}${NC}$(printf '%*s' $((14 - ${#file_type})) "")${BOLD_WHITE}║${NC}"
    done
    
    # Table footer
    echo -e "${BOLD_WHITE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Present options to the user
    echo -e "${BOLD_WHITE}What would you like to do with these files?${NC}"
    echo -e "${BOLD_PURPLE}1${NC}. ${BOLD_YELLOW}Delete all files${NC}"
    echo -e "${BOLD_PURPLE}2${NC}. ${BOLD_YELLOW}Select specific file(s) to delete${NC}"
    echo -e "${BOLD_PURPLE}0${NC}. ${BOLD_YELLOW}Cancel${NC} (keep all files)"
    echo
    
    echo -ne "${YELLOW}Your choice: ${BOLD_PURPLE}"
    read cleanup_choice
    echo -ne "${NC}"
    
    case $cleanup_choice in
        0)
            print_color "YELLOW" "Operation cancelled. No files were deleted." "warning"
            ;;
        1)
            # Delete all files
            echo
            print_color "YELLOW" "Deleting all files..." "warning"
            local success_count=0
            
            for file in "${all_files[@]}"; do
                echo -ne "${YELLOW}Deleting: ${CYAN}$(basename "$file")${NC}... "
                
                if rm "$file" 2>/dev/null; then
                    echo -e "${BOLD_GREEN}✓${NC}"
                    success_count=$((success_count + 1))
                else
                    echo -e "${BOLD_RED}✗${NC}"
                fi
            done
            
            print_color "BOLD_GREEN" "✓ $success_count/${#all_files[@]} files deleted successfully" "success"
            ;;
        2)
            # Select specific files
            echo
            print_color "YELLOW" "Enter the number(s) of the file(s) to delete, separated by spaces:" "info"
            echo -ne "${YELLOW}Your selection: ${BOLD_PURPLE}"
            read -a selected_indices
            echo -ne "${NC}"
            
            if [ ${#selected_indices[@]} -eq 0 ]; then
                print_color "YELLOW" "No files selected. Operation cancelled." "warning"
            else
                echo
                print_color "YELLOW" "Deleting selected files..." "warning"
                local success_count=0
                
                for index in "${selected_indices[@]}"; do
                    # Convert to zero-based index
                    index=$((index - 1))
                    
                    if [ $index -ge 0 ] && [ $index -lt ${#all_files[@]} ]; then
                        local file="${all_files[$index]}"
                        echo -ne "${YELLOW}Deleting: ${CYAN}$(basename "$file")${NC}... "
                        
                        if rm "$file" 2>/dev/null; then
                            echo -e "${BOLD_GREEN}✓${NC}"
                            success_count=$((success_count + 1))
                        else
                            echo -e "${BOLD_RED}✗${NC}"
                        fi
                    else
                        print_color "RED" "Invalid selection: $((index + 1))" "error"
                    fi
                done
                
                print_color "BOLD_GREEN" "✓ $success_count/${#selected_indices[@]} files deleted successfully" "success"
            fi
            ;;
        *)
            print_color "RED" "Invalid choice. No files were deleted." "error"
            ;;
    esac
    
    echo
    return 0
}

# Initialize the menu directly without calling display_logo separately
display_tui_menu

exit 0

