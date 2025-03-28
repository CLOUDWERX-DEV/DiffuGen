# DiffuGen - Advanced Stable Diffusion Image Generator with MCP Integration

<p align="center">
  <img src="diffugen.png" alt="DiffuGen Logo" width="200"/>
</p>

<p align="center">
  <em>Seamlessly generate AI images directly within your development workflow. Integrates with Cursor, Windsurf, Roo Code, Cline and other MCP-compatible IDEs for frictionless creative development.</em>
</p>

<p align="center">
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/stargazers"><img src="https://img.shields.io/github/stars/CLOUDWERX-DEV/diffugen" alt="Stars Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/network/members"><img src="https://img.shields.io/github/forks/CLOUDWERX-DEV/diffugen" alt="Forks Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/issues"><img src="https://img.shields.io/github/issues/CLOUDWERX-DEV/diffugen" alt="Issues Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/blob/master/LICENSE"><img src="https://img.shields.io/github/license/CLOUDWERX-DEV/diffugen" alt="License Badge"/></a>
  <a href="https://smithery.ai/server/CLOUDWERX-DEV/DiffuGen"><img alt="Installations" src="https://smithery.duckduckgoose.cc/badge/CLOUDWERX-DEV/DiffuGen"></a>

## 📋 Table of Contents

- [Introduction](#-introduction)
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
  - [Installing via Smithery](#installing-via-smithery)
  - [Automatic Installation](#automatic-installation)
  - [Manual Installation](#manual-installation)
  - [Cross-Platform Considerations](#cross-platform-considerations)
- [Usage](#-usage)
  - [MCP Integration](#mcp-integration)
  - [Command Line Usage](#command-line-usage)
  - [Parameter Reference](#parameter-reference)
  - [Model Selection](#model-selection)
- [Examples](#-examples)
- [Configuration](#-configuration)
  - [Environment Variables](#environment-variables)
  - [Resource Configuration](#resource-configuration)
- [Troubleshooting](#-troubleshooting)
  - [Common Issues](#common-issues)
  - [Error Messages](#error-messages)
  - [Log Files](#log-files)
- [Advanced Usage](#-advanced-usage)
  - [Custom Models](#custom-models)
  - [Batch Processing](#batch-processing)
  - [Performance Tuning](#performance-tuning)
- [Uninstallation](#-uninstallation)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Contact](#-contact)

## 🚀 Introduction

DiffuGen is an advanced image generation tool powered by Stable Diffusion, designed to seamlessly integrate with modern development environments through the MCP (Machine Control Protocol) interface. It supports multiple Stable Diffusion models including Flux Schnell, Flux Dev, SDXL, and SD3, allowing for high-quality image generation with precise control over parameters.

Built on top of the highly optimized [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) implementation, DiffuGen offers exceptional performance even on modest hardware while maintaining high-quality output.

## ✨ Features

- **Multiple Model Support**: Generate images using various models including Flux Schnell, Flux Dev, SDXL, SD3, and SD1.5
- **MCP Integration**: Seamlessly integrates with IDEs that support MCP (Cursor, Windsurf, etc.)
- **Cross-Platform**: Works on Linux, macOS, and Windows (via native or WSL)
- **Parameter Control**: Fine-tune your generations with controls for:
  - Image dimensions (width/height)
  - Sampling steps
  - CFG scale
  - Seed values
  - Negative prompts
  - Sampling methods
- **CUDA Acceleration**: Utilizes GPU acceleration for faster image generation
- **Natural Language Interface**: Generate images using simple natural language commands
- **Smart Error Recovery**: Robust error handling with operation-aware recovery procedures
- **User-Friendly Setup**: Interactive setup script with improved interrupt handling
- **Resource Tracking**: Session-aware resource management for efficient cleanup
- **Customizable Interface**: Support for custom ANSI art logos and visual enhancements

## 💻 System Requirements

### Minimum Requirements:

- **CPU**: 4-core processor (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 8GB system memory (DDR4-2666 or faster recommended)
- **Storage**: 5GB free disk space (SSD preferred for faster model loading)
- **Python**: 3.8 or newer
- **GPU**: Integrated graphics or entry-level dedicated GPU (optional)
- **Network**: Broadband connection for model downloads (5+ Mbps)

### Recommended Requirements:

- **CPU**: 8+ core processor (Intel i7/i9 or AMD Ryzen 7/9)
- **RAM**: 16GB+ system memory (DDR4-3200 or faster)
- **GPU**: NVIDIA GPU with 6GB+ VRAM (RTX 2060 or better for optimal performance)
- **Storage**: 20GB+ free SSD space (NVMe SSD recommended for faster model loading)
- **Python**: 3.10 or newer (3.11 offers best performance)
- **Network**: High-speed connection (20+ Mbps) for efficient model downloads
- **Display**: 1080p or higher resolution for viewing generated images

###### Software Dependencies:

- **Git**: Version 2.25+ (needed to clone repositories and track changes)
  
  - [Linux Installation](https://git-scm.com/download/linux)
  - [macOS Installation](https://git-scm.com/download/mac)
  - [Windows Installation](https://git-scm.com/download/win)

- **CMake**: Version 3.18+ (required for building Stable-Diffusion.cpp)
  
  - [Official Download Page](https://cmake.org/download/)
  - Linux: `sudo apt-get install cmake` (Debian/Ubuntu) or `sudo dnf install cmake` (Fedora)
  - macOS: `brew install cmake`
  - Windows: Use the installer from the official site or `winget install Kitware.CMake`

- **C++ Compiler**:
  
  - Linux: GCC 9+ or Clang 10+
    - Ubuntu/Debian: `sudo apt-get install build-essential`
    - Fedora: `sudo dnf group install "Development Tools"`
    - Arch: `sudo pacman -S base-devel`
  - macOS: Clang 13+ (via Xcode Command Line Tools)
    - Install with: `xcode-select --install`
  - Windows: MSVC 2019+ (via Visual Studio or Build Tools)
    - [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/) (free)
    - [Build Tools for Visual Studio](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) (smaller download)

- **CUDA Toolkit**: Version 11.4+ (for NVIDIA GPU acceleration, 12.0+ recommended)
  
  - [NVIDIA CUDA Toolkit Download](https://developer.nvidia.com/cuda-downloads)
  - Installation guides: [Linux](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/), [Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/), [macOS](https://developer.nvidia.com/cuda-downloads?target_os=MacOSX)
  - Verify installation: `nvcc --version`

- **cuDNN**: Version compatible with your CUDA installation (for optimized neural network operations)
  
  - [NVIDIA cuDNN Download](https://developer.nvidia.com/cudnn) (requires NVIDIA Developer account)
  - [Installation Guide](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html)

- **Python Packages**: All dependencies listed in requirements.txt including MCP, NumPy, and Pillow
  
  - Install Python 3.8+: [Python.org Downloads](https://www.python.org/downloads/)

For troubleshooting dependency issues, consult the [DiffuGen GitHub repository](https://github.com/cloudwerxlab/diffugen) or the [official documentation](https://github.com/leejet/stable-diffusion.cpp) for stable-diffusion.cpp.

## 📥 Installation

### Installing via Smithery

To install DiffuGen automatically for Claude Desktop via Smithery:

```bash
smithery install CLOUDWERX-DEV/DiffuGen
```

### Automatic Installation

The easiest way to install DiffuGen is using the provided setup script:

#### Linux Installation

1. Clone the repository:
   
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

2. Run the setup script:
   
   ```bash
   chmod +x setup_diffugen.sh
   ./setup_diffugen.sh
   ```

3. Follow the interactive prompts to complete the installation.

#### macOS Installation

1. Install Homebrew if not already installed:
   
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install Git if not already installed:
   
   ```bash
   brew install git
   ```

3. Clone the repository:
   
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

4. Make the setup script executable and run it:
   
   ```bash
   chmod +x setup_diffugen.sh
   ./setup_diffugen.sh
   ```

5. The script will automatically detect macOS and install necessary dependencies (cmake, make, gcc, curl, python3, bc) using Homebrew before proceeding with the DiffuGen setup.

6. Follow the interactive prompts to complete the installation.

#### Windows Installation

**Option 1: Using Windows Subsystem for Linux (WSL) - Recommended**

1. Install WSL by opening PowerShell as Administrator and running:
   
   ```powershell
   wsl --install
   ```

2. Restart your computer when prompted.

3. After restart, a Ubuntu terminal will open. Set up your Linux username and password.

4. Update the package lists and install git:
   
   ```bash
   sudo apt update
   sudo apt install git
   ```

5. Clone the repository:
   
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

6. Run the setup script:
   
   ```bash
   chmod +x setup_diffugen.sh
   ./setup_diffugen.sh
   ```

7. Follow the interactive prompts to complete the installation.

**Option 2: Native Windows Installation**

1. Install Git for Windows from [git-scm.com](https://git-scm.com/download/win)

2. Install Visual Studio with C++ development tools from [visualstudio.microsoft.com](https://visualstudio.microsoft.com/downloads/)

3. Install CMake from [cmake.org](https://cmake.org/download/)

4. Install Python 3.8+ from [python.org](https://www.python.org/downloads/)

5. Open Git Bash and clone the repository:
   
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

6. Run the setup script (use PowerShell if available):
   
   ```bash
   ./setup_diffugen.sh
   ```

7. The script will detect Windows and attempt to install dependencies using Chocolatey. If PowerShell is available, it will install Chocolatey and use it to install the required dependencies.

8. Follow the interactive prompts to complete the installation.

The setup script will:

- Install necessary dependencies
- Clone and build stable-diffusion.cpp
- Set up a Python virtual environment
- Download selected models
- Configure file paths for your system

#### Setup Script Features

Our enhanced setup script includes:

- **Smart Interrupt Handling**: Safely cancel operations with Ctrl+C at any point without corrupting your system:
  - Clean exit from menus with a simple "Operation cancelled by user" message
  - Smart detection of partial downloads if interrupting model downloads
  - Contextual recovery based on which operation was interrupted

- **Session-Aware Resource Tracking**:
  - Tracks resources created only during the current session
  - Only offers to clean up files created in the current run
  - Protects valuable models and configurations from previous sessions
  - Variables like `TEMP_FILES_CREATED_THIS_SESSION` and `VENV_CREATED_THIS_SESSION` ensure safety

- **Enhanced Error Recovery**:
  - Operation-specific error handling using operation typing
  - Clear, context-aware error messages that explain what went wrong
  - Graceful recovery from dependency installation failures
  - Intelligent handling of build errors with detailed diagnostics

- **Improved Model Management**:
  - Comprehensive model selection menu with details about each model
  - Displays model size, type, and download status in a well-formatted table
  - Tracks current download progress with `current_model_name` and `current_download_file`
  - Proper cleanup of partial downloads if interrupted

- **Visual Enhancements**:
  - Color-coded status messages for better readability
  - Support for custom ANSI art logos using a heredoc approach
  - Animated progress indicators during lengthy operations
  - Clear formatting of menus and options

### Manual Installation

If you prefer to install manually, follow these steps:

1. Clone the repository:
   
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

2. Clone stable-diffusion.cpp:
   
   ```bash
   git clone --recursive https://github.com/leejet/stable-diffusion.cpp
   ```

3. Build stable-diffusion.cpp:
   
   ```bash
   cd stable-diffusion.cpp
   mkdir -p build && cd build
   ```
   
   ### For CUDA support:

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON
```

### Without CUDA:

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ../..
```

  

4. Create and activate a Python virtual environment:
   
   ```bash
   python3 -m venv diffugen_env
   source diffugen_env/bin/activate  # On Windows: diffugen_env\Scripts\activate
   ```

5. Install Python dependencies:
   
   ```bash
   pip install -r requirements.txt
   ```

6. Download required models:
   
If you prefer to download models manually instead of using the automated setup script, follow these instructions to ensure all files are placed in their correct locations.

### Required Models

First, create the necessary directory structure:

```bash
mkdir -p stable-diffusion.cpp/models/flux
```

#### Core Components (Required)

These components are essential for all models to function properly:

1. **T5XXL Text Encoder**
   
   - Download: [t5xxl_fp16.safetensors](https://huggingface.co/Sanami/flux1-dev-gguf/resolve/main/t5xxl_fp16.safetensors)
   - Save to: `stable-diffusion.cpp/models/t5xxl_fp16.safetensors`

2. **CLIP-L Text Encoder**
   
   - Download: [clip_l.safetensors](https://huggingface.co/Sanami/flux1-dev-gguf/resolve/main/clip_l.safetensors)
   - Save to: `stable-diffusion.cpp/models/clip_l.safetensors`

3. **VAE for Image Decoding**
   
   - Download: [ae.safetensors](https://huggingface.co/pretentioushorsefly/flux-models/resolve/main/models/vae/ae.safetensors)
   - Save to: `stable-diffusion.cpp/models/ae.sft`

### Diffusion Models (Choose at least one)

#### Flux Models

1. **Flux Schnell** - Fast generation model
   
   - Download: [flux1-schnell-q8_0.gguf](https://huggingface.co/leejet/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-q8_0.gguf)
   - Save to: `stable-diffusion.cpp/models/flux/flux1-schnell-q8_0.gguf`

2. **Flux Dev** - Development model with better quality
   
   - Download: [flux1-dev-q8_0.gguf](https://huggingface.co/leejet/FLUX.1-dev-gguf/resolve/main/flux1-dev-q8_0.gguf)
   - Save to: `stable-diffusion.cpp/models/flux/flux1-dev-q8_0.gguf`

#### Standard Stable Diffusion Models

1. **SDXL 1.0 Base Model**
   
   - Download: [sd_xl_base_1.0.safetensors](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors)
   - Save to: `stable-diffusion.cpp/models/sd_xl_base_1.0.safetensors`
   - **Additional requirement**: Download [sdxl_vae-fp16-fix.safetensors](https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae-fp16-fix.safetensors) and save to `stable-diffusion.cpp/models/sdxl_vae-fp16-fix.safetensors`

2. **Stable Diffusion 1.5**
   
   - Download: [v1-5-pruned-emaonly.safetensors](https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors)
   - Save to: `stable-diffusion.cpp/models/v1-5-pruned-emaonly.safetensors`

3. **Stable Diffusion 3 Medium**
   
   - Download: [sd3_medium_incl_clips_t5xxlfp16.safetensors](https://huggingface.co/leo009/stable-diffusion-3-medium/resolve/main/sd3_medium_incl_clips_t5xxlfp16.safetensors)
   - Save to: `stable-diffusion.cpp/models/sd3_medium_incl_clips_t5xxlfp16.safetensors`

### Download Commands

You can use curl or wget to download these files. For example:

```bash
# Create directories
mkdir -p stable-diffusion.cpp/models/flux

# Download required components
curl -L "https://huggingface.co/Sanami/flux1-dev-gguf/resolve/main/t5xxl_fp16.safetensors" -o "stable-diffusion.cpp/models/t5xxl_fp16.safetensors"
curl -L "https://huggingface.co/Sanami/flux1-dev-gguf/resolve/main/clip_l.safetensors" -o "stable-diffusion.cpp/models/clip_l.safetensors"
curl -L "https://huggingface.co/pretentioushorsefly/flux-models/resolve/main/models/vae/ae.safetensors" -o "stable-diffusion.cpp/models/ae.sft"

# Download Flux models
curl -L "https://huggingface.co/leejet/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-q8_0.gguf" -o "stable-diffusion.cpp/models/flux/flux1-schnell-q8_0.gguf"
curl -L "https://huggingface.co/leejet/FLUX.1-dev-gguf/resolve/main/flux1-dev-q8_0.gguf" -o "stable-diffusion.cpp/models/flux/flux1-dev-q8_0.gguf"

# Download SDXL and VAE
curl -L "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" -o "stable-diffusion.cpp/models/sd_xl_base_1.0.safetensors"
curl -L "https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae-fp16-fix.safetensors" -o "stable-diffusion.cpp/models/sdxl_vae-fp16-fix.safetensors"

# Download SD15 and SD3
curl -L "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -o "stable-diffusion.cpp/models/v1-5-pruned-emaonly.safetensors"
curl -L "https://huggingface.co/leo009/stable-diffusion-3-medium/resolve/main/sd3_medium_incl_clips_t5xxlfp16.safetensors" -o "stable-diffusion.cpp/models/sd3_medium_incl_clips_t5xxlfp16.safetensors"
```

### Verifying Installation

After downloading, verify that all files are in their correct locations by running:

```bash
ls -la stable-diffusion.cpp/models/
ls -la stable-diffusion.cpp/models/flux/
```

The paths should match exactly what's specified in the `diffugen.py` file to ensure proper functionality.

7. Update file paths in configuration files:
   
   ```
   Edit diffugen.json, diffugen.sh, and diffugen.py to update paths
   ```

### Cross-Platform Considerations

#### Linux

- Ensure you have the appropriate development packages installed for your distribution

- For Debian/Ubuntu:
  
  ```bash
  sudo apt-get update
  sudo apt-get install -y git cmake make g++ curl python3 python3-venv python3-pip bc
  ```

#### macOS

- Install Homebrew if not already installed:
  
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- Install dependencies:
  
  ```bash
  brew install git cmake make gcc curl python3 bc
  ```

#### Windows

- Option 1: Use WSL (Windows Subsystem for Linux) and follow Linux instructions
- Option 2: Native Windows installation:
  - Install Git for Windows
  - Install Visual Studio with C++ development tools
  - Install CMake
  - Install Python 3.8+

## 🎮 Usage

### MCP Integration

To use DiffuGen with MCP-compatible IDEs (Cursor, Windsurf, etc.), add the following configuration to your MCP servers:

```json
{
  "mcpServers": {
    "diffugen": {
      "command": "/path/to/diffugen/diffugen.sh",
      "args": [],
      "env": {
        "DEFAULT_MODEL": "flux-schnell",
        "CUDA_VISIBLE_DEVICES": "0",
        "SD_CPP_PATH": "/path/to/diffugen/stable-diffusion.cpp"
      },
      "resources": {
        "models_dir": "/path/to/diffugen/stable-diffusion.cpp/models",
        "output_dir": "/path/to/diffugen/outputs",
        "vram_usage": "adaptive"
      },
      "metadata": {
        "name": "DiffuGen",
        "version": "1.0",
        "description": "Powerful image generation system leveraging multiple Stable Diffusion models (flux-schnell, flux-dev, sdxl, sd3, sd15). DiffuGen provides optimized performance with cross-platform compatibility and advanced parameter control for creating high-quality AI-generated images with precise customization. Supports various sampling methods and negative prompting for fine-tuned creative control.",
        "author": "CLOUDWERX LAB",
        "homepage": "https://github.com/CLOUDWERX-DEV/diffugen",
        "usage": "Generate images using two primary methods:\n1. Standard generation: 'generate an image of [description]' with optional parameters:\n   - model: Choose from flux-schnell (default), flux-dev, sdxl, sd3, sd15\n   - dimensions: width and height (default: 512x512)\n   - steps: Number of diffusion steps (default: 20, lower for faster generation)\n   - cfg_scale: Guidance scale (default: 7.0, lower for more creative freedom)\n   - seed: For reproducible results (-1 for random)\n   - sampling_method: euler, euler_a (default), heun, dpm2, dpm++2s_a, dpm++2m, dpm++2mv2, lcm\n   - negative_prompt: Specify elements to avoid in the image\n2. Quick Flux generation: 'generate a flux image of [description]' for faster results with fewer steps (default: 4)"
      },
      "cursorOptions": {
        "autoApprove": true,
        "category": "Image Generation",
        "icon": "🖼️",
        "displayName": "DiffuGen"
      },
      "windsurfOptions": {
        "displayName": "DiffuGen",
        "icon": "🖼️",
        "category": "Creative Tools"
      }
    }
  }
}
```

Replace `/path/to/diffugen/diffugen.sh` with the actual path to your DiffuGen installation.

### Command Line Usage

You can also use DiffuGen directly from the command line:

```python
./diffugen.sh "A beautiful sunset over mountains" --model flux-dev --width 1024 --height 768 --steps 30 --cfg-scale 7 --seed 42
```

Or using the Python script directly:

```python
source diffugen_env/bin/activate  # Activate virtual environment
python diffugen.py "A beautiful sunset over mountains" --model flux-dev --width 1024 --height 768 --steps 30 --cfg-scale 7 --seed 42
```

### Parameter Reference

| Parameter         | Description                        | Default           | Valid Values                                                                   |
| ----------------- | ---------------------------------- | ----------------- | ------------------------------------------------------------------------------ |
| `prompt`          | The image description to generate  | (Required)        | Any text                                                                       |
| `model`           | Model to use                       | `flux-schnell`    | `flux-schnell`, `flux-dev`, `sdxl`, `sd3`, `sd15`                              |
| `output_dir`      | Directory to save the image        | Current directory | Valid path                                                                     |
| `width`           | Image width in pixels              | 512               | 64-2048                                                                        |
| `height`          | Image height in pixels             | 512               | 64-2048                                                                        |
| `steps`           | Number of diffusion steps          | 20                | 1-100                                                                          |
| `cfg_scale`       | CFG scale parameter                | 7.0               | 0-20                                                                           |
| `seed`            | Seed for reproducibility           | -1 (random)       | Any integer, -1 for random                                                     |
| `sampling_method` | Sampling method                    | `euler_a`         | `euler`, `euler_a`, `heun`, `dpm2`, `dpm++2s_a`, `dpm++2m`, `dpm++2mv2`, `lcm` |
| `negative_prompt` | Negative prompt for SD Models only | `""`              | Any text                                                                       |

### Model Selection

DiffuGen supports the following models:

- **flux-schnell**: Fast generation model, good for quick iterations
- **flux-dev**: Development model with better quality
- **sdxl**: Stable Diffusion XL 1.0, high-quality model for detailed images
- **sd3**: Stable Diffusion 3 Medium, newer generation model
- **sd15**: Stable Diffusion 1.5, classic model with good performance

## 📝 Examples

### Basic Usage

```
generate an image of a cat in space
```

### Advanced Usage

```
generate an image of a cyberpunk city at night with neon lights using flux-dev, 1024x768, 30 steps, cfg 7, seed 42
```

```
generate an image of a beautiful landscape with mountains and lakes using sdxl, 1920x1080, 50 steps, cfg 8, negative: blurry, ugly, distorted
```

## ⚙️ Configuration

### Environment Variables

DiffuGen supports the following environment variables:

| Variable               | Description                  | Default                  |
| ---------------------- | ---------------------------- | ------------------------ |
| `DEFAULT_MODEL`        | Default model to use         | `flux-schnell`           |
| `CUDA_VISIBLE_DEVICES` | CUDA devices to use          | `0`                      |
| `SD_CPP_PATH`          | Path to stable-diffusion.cpp | `./stable-diffusion.cpp` |

### Resource Configuration

You can configure resource usage in the `diffugen.json` file:

```json
"resources": {
  "models_dir": "./stable-diffusion.cpp/models",
  "output_dir": "./outputs",
  "vram_usage": "adaptive"
}
```

- `models_dir`: Directory where models are stored
- `output_dir`: Directory where generated images are saved
- `vram_usage`: VRAM usage profile (`low`, `medium`, `high`, or `adaptive`)

## 🔧 Troubleshooting

### Common Issues

#### CUDA Out of Memory

- Reduce image dimensions
- Use a smaller model
- Set `vram_usage` to `low`
- Try using `--vae-tiling` and `--vae-on-cpu` options

#### Model Not Found

- Ensure models are downloaded to the correct location
- Check file paths in configuration files
- Verify model filenames match those in the code

#### Build Failures

- Ensure all dependencies are installed
- Check CMake version (3.18+ required)
- For CUDA builds, verify CUDA Toolkit is properly installed

### Error Messages

| Error                                                              | Solution                                               |
| ------------------------------------------------------------------ | ------------------------------------------------------ |
| `ModuleNotFoundError: No module named 'mcp'`                       | Activate virtual environment or reinstall requirements |
| `CUDA error: out of memory`                                        | Reduce dimensions or use a smaller model               |
| `No such file or directory: './stable-diffusion.cpp/build/bin/sd'` | Build stable-diffusion.cpp or check file paths         |
| `Failed to load model`                                             | Verify model files exist and are not corrupted         |

### Log Files

Logs are stored in the following locations:

- Build logs: `stable-diffusion.cpp/build/build.log`
- Runtime logs: `logs/diffugen.log`

## 🧠 Advanced Usage

### Custom Models

To use custom models:

1. Place your model files in the `stable-diffusion.cpp/models` directory
2. Modify `diffugen.py` to add your model configuration:

```python
elif model.lower() == "your-model-name":
    base_command.extend([
        "-m", "./stable-diffusion.cpp/models/your-model-file.safetensors",
        "--vae", "./stable-diffusion.cpp/models/your-vae-file.safetensors"
    ])
```

### Batch Processing

To generate multiple images with different prompts:

```bash
./batch_generate.sh prompts.txt --model flux-dev --width 512 --height 512
```

Where `prompts.txt` contains one prompt per line.

### Performance Tuning

For optimal performance:

- Use CUDA acceleration when available
- Adjust `vram_usage` based on your GPU
- For low VRAM GPUs, use the following options:
  - `--vae-tiling`
  - `--vae-on-cpu`
  - `--clip-on-cpu`
  - `--diffusion-fa`

## 🗑️ Uninstallation

To completely remove DiffuGen:

1. Remove the DiffuGen directory:
   
   ```bash
   rm -rf /path/to/diffugen
   ```

2. Remove MCP configuration from your IDE settings.

3. Optionally, remove downloaded models to free up space:
   
   ```bash
   rm -rf /path/to/diffugen/stable-diffusion.cpp/models
   ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

* This project is licensed under the Apache License - see the LICENSE file for details.

* All models are licensed under their respenctive distribution and are not in any way licensed or provided by CLOUDWERX.DEV

* HuggingFace.co is used to download models and is not affiliated in any way with CLOUDWERX.DEV

* Please include our LICENSE if you are planning on distributing or modifying to simply track the source, this work is fully open source and I hope you all make amazing things with this codebase!

## 🙏 Acknowledgments

- [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) for the optimized C++ implementation
- [Stability AI](https://stability.ai/) for Stable Diffusion models
- [Black Forest Labs ](https://blackforestlabs.ai/)for their Flux Models
- [Hugging Face](https://huggingface.co/) for the download links
- All contributors to the MCP protocol
- My Awesome Wifey for everything else ❤️

## 📬 Contact

- GitHub: [CLOUDWERX-DEV](https://github.com/CLOUDWERX-DEV)
- Website:[ [cloudwerx.dev]](http://cloudwerx.dev)
- Mail: ([sysop@cloudwerx.dev](mailto:sysop@cloudwerx.dev))

- Join our [Discord server](https://discord.gg/SvZFuufNTQ) for discussions
- Follow us on [X](https://twitter.com/cloudwerxlab) for updates
- Subscribe to our [newsletter](https://cloudwerx.dev/newsletter) for major announcements

```bash
         ______   __   ___   ___         _______              
        |   _  \ |__|.'  _|.'  _|.--.--.|   _   |.-----.-----.
        |.  |   \|  ||   _||   _||  |  ||.  |___||  -__|     |
        |.  |    \__||__|  |__|  |_____||.  |   ||_____|__|__|
        |:  1    /                      |:  1   |             
        |::.. . /                       |::.. . |             
        `------'                        `-------'             
                                                        
```

<p align="center">
  Made with ❤️ by CLOUDWERX LAB
</p>
<p align="center">
   <em> Developed on Linux Mint Cinnamon!
</p>
