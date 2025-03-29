#!/bin/bash

# DiffuGen MCP Server Launcher
# Made with ❤️ by CLOUDWERX LAB - "Digital Food for the Analog Soul"
# http://github.com/CLOUDWERX-DEV/diffugen
# http://cloudwerx.dev

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR" >&2

# Set default output directory
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/outputs"
echo "Default output directory: $DEFAULT_OUTPUT_DIR" >&2

# Check for Cursor MCP configuration
MCP_CONFIG_PATH="$SCRIPT_DIR/.cursor/mcp.json"
if [ -f "$MCP_CONFIG_PATH" ]; then
    echo "Found Cursor MCP configuration" >&2
    
    # Try to extract diffugen output_dir from MCP configuration 
    # First check if jq is available for proper JSON parsing
    if command -v jq &> /dev/null; then
        echo "Using jq for JSON parsing" >&2
        OUTPUT_DIR=$(jq -r '.mcpServers.diffugen.resources.output_dir // empty' "$MCP_CONFIG_PATH")
    else
        # Fallback to grep/sed method if jq is not available
        echo "jq not available, using fallback grep method" >&2
        OUTPUT_DIR=$(grep -o '"output_dir": *"[^"]*"' "$MCP_CONFIG_PATH" | sed 's/"output_dir": *"\(.*\)"/\1/')
    fi
    
    if [ ! -z "$OUTPUT_DIR" ]; then
        echo "Using output directory from Cursor MCP configuration: $OUTPUT_DIR" >&2
        DEFAULT_OUTPUT_DIR="$OUTPUT_DIR"
    else
        echo "Could not extract output_dir from MCP configuration, using default" >&2
    fi
fi

# Create the output directory if it doesn't exist
mkdir -p "$DEFAULT_OUTPUT_DIR"

# Set the environment variable
export DIFFUGEN_OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"

# Forward SD_CPP_PATH environment variable from MCP if set
if [ -n "$SD_CPP_PATH" ]; then
    echo "Using SD_CPP_PATH from environment: $SD_CPP_PATH" >&2
    # Normalize path for platform compatibility
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* ]]; then
        # Convert Unix-style paths to Windows if needed
        SD_CPP_PATH=$(echo "$SD_CPP_PATH" | sed 's/\//\\/g')
        echo "Normalized for Windows: $SD_CPP_PATH" >&2
    fi
else
    # Set default if not provided
    SD_CPP_PATH="$SCRIPT_DIR/stable-diffusion.cpp"
    echo "Using default SD_CPP_PATH: $SD_CPP_PATH" >&2
fi
# Ensure it's exported
export SD_CPP_PATH

# Activate virtual environment
VENV_PATH="$SCRIPT_DIR/diffugen_env"
echo "Activating virtual environment at: $VENV_PATH" >&2

if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH" >&2
    echo "Please run setup_diffugen.sh first to set up the environment" >&2
    exit 1
fi

source "$VENV_PATH/bin/activate"

# Check if activation was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to activate virtual environment" >&2
    exit 1
fi

echo "Python version: $(python --version)" >&2

# Check for required packages
echo "Checking for required packages..." >&2
if python -c "import fastmcp" 2>/dev/null; then
    echo "fastmcp package found: $(pip show fastmcp | grep Version)" >&2
else
    echo "Error: fastmcp package not found" >&2
    exit 1
fi

if python -c "import mcp" 2>/dev/null; then
    echo "mcp package found: $(pip show mcp | grep Version)" >&2
else
    echo "Error: mcp package not found" >&2
    exit 1
fi

# Change to the script directory
cd "$SCRIPT_DIR"

# Log success message for initialization
echo "DiffuGen server initialization complete" >&2

# Start the diffugen server
echo "Starting DiffuGen server..." >&2
python diffugen.py "$@"
