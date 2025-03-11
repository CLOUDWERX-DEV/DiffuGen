#!/bin/bash

# DiffuGen MCP Server Launcher
# Made with ❤️ by CLOUDWERX LAB - "Digital Food for the Analog Soul"
# http://github.com/CLOUDWERX-DEV/diffugen
# http://cloudwerx.dev

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

# Activate virtual environment
VENV_PATH="$SCRIPT_DIR/diffugen_env"
echo "Activating virtual environment at: $VENV_PATH"

if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH"
    echo "Please run setup_diffugen.sh first to set up the environment"
    exit 1
fi

source "$VENV_PATH/bin/activate"

# Check if activation was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to activate virtual environment"
    exit 1
fi

echo "Python version: $(python --version)"

# Check for required packages
echo "Checking for required packages..."
if python -c "import fastmcp" 2>/dev/null; then
    echo "fastmcp package found: $(pip show fastmcp | grep Version)"
else
    echo "Error: fastmcp package not found"
    exit 1
fi

if python -c "import mcp" 2>/dev/null; then
    echo "mcp package found: $(pip show mcp | grep Version)"
else
    echo "Error: mcp package not found"
    exit 1
fi

# Change to the script directory
cd "$SCRIPT_DIR"

# Start the diffugen server
echo "Starting DiffuGen server..."
python diffugen.py "$@"
