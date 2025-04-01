# DiffuGen - Advanced Stable Diffusion Image Generator with MCP Integration

<p align="center">
  <img src="diffugen.png" alt="DiffuGen Logo" width="200"/>
</p>

<p align="center">
  <em>Your AI art studio embedded directly in code. Generate, iterate, and perfect visual concepts through this powerful MCP server for Cursor, Windsurf, and other compatible IDEs, utilizing cutting-edge Flux and Stable Diffusion models without disrupting your development process.</em>
</p>

<p align="center">
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/stargazers"><img src="https://img.shields.io/github/stars/CLOUDWERX-DEV/diffugen" alt="Stars Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/network/members"><img src="https://img.shields.io/github/forks/CLOUDWERX-DEV/diffugen" alt="Forks Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/issues"><img src="https://img.shields.io/github/issues/CLOUDWERX-DEV/diffugen" alt="Issues Badge"/></a>
  <a href="https://github.com/CLOUDWERX-DEV/diffugen/blob/master/LICENSE"><img src="https://img.shields.io/github/license/CLOUDWERX-DEV/diffugen" alt="License Badge"/></a>
</p>

> ⭐ **New**: Now includes OpenAPI server support and OpenWebUI OpenAPI Tools (OWUI Version 0.60.0 Required) integration for seamless image generation and display in chat interfaces!

## 📃 Table of Contents

- [Introduction](#-introduction)
- [Understanding MCP and DiffuGen](#-understanding-mcp-and-diffugen)
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [IDE Setup Instructions](#-ide-setup-instructions)
- [Usage](#-usage)
  - [OpenAPI Server Usage](#openapi-server-usage)
  - [Default Parameters by Model](#default-parameters-by-model)
  - [Asking a LLM to Generate Images](#asking-a-llm-to-generate-images)
  - [Parameter Reference](#parameter-reference)
  - [Model-Specific Parameter Recommendations](#model-specific-parameter-recommendations)
  - [Default Parameter Changes](#default-parameter-changes)
  - [Command Line Usage Notes](#command-line-usage-notes)
- [Configuration](#️-configuration)
  - [OpenAPI Server Configuration](#openapi-server-configuration)
  - [MCP Configuration File Structure](#mcp-configuration-file-structure)
  - [Key Configuration Elements](#key-configuration-elements)
  - [IDE-Specific Options](#ide-specific-options)
  - [Configuration File Locations](#configuration-file-locations)
  - [Customizing Default Parameters](#customizing-default-parameters)
  - [Updating Configuration Files](#updating-configuration-files)
- [Advanced Usage](#-advanced-usage)
  - [Using the OpenAPI Server](#using-the-openapi-server)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Contact](#-contact)

## 🚀 Introduction

DiffuGen is a powerful MCP-based image generation system that brings cutting-edge AI models directly into your development workflow. It seamlessly integrates both Flux models (Flux Schnell, Flux Dev) and Stable Diffusion variants (SDXL, SD3, SD1.5) into a unified interface, allowing you to leverage the unique strengths of each model family without switching tools. With comprehensive parameter control and multi-GPU support, DiffuGen scales from rapid concept sketches on modest hardware to production-quality visuals on high-performance systems.

Built on top of the highly optimized [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) implementation, DiffuGen offers exceptional performance even on modest hardware while maintaining high-quality output.

## 🧠 Understanding MCP and DiffuGen

### What is MCP?

MCP (Model Context Protocol) is a protocol that enables LLMs (Large Language Models) to access custom tools and services. In simple terms, an MCP client (like Cursor, Windsurf, Roo Code, or Cline) can make requests to MCP servers to access tools that they provide.

### DiffuGen as an MCP Server

DiffuGen functions as an MCP server that provides text-to-image generation capabilities. It implements the MCP protocol to allow compatible IDEs to send generation requests and receive generated images.

The server exposes two main tools:
1. `generate_stable_diffusion_image`: Generate with Stable Diffusion models
2. `generate_flux_image`: Generate with Flux models

### Technical Architecture

DiffuGen consists of several key components:

- **setup-diffugen.sh**: The complete install utility and model downloader and manager
- **diffugen.py**: The core Python script that implements the MCP server functionality and defines the generation tools
- **diffugen.sh**: A shell script launcher that sets up the environment and launches the Python server
- **diffugen.json**: Template configuration file for MCP integration with various IDEs (to be copied into IDE's MCP configuration)
- **stable-diffusion.cpp**: The optimized C++ implementation of Stable Diffusion used for actual image generation

The system works by:
1. Receiving prompt and parameter data from an MCP client
2. Processing the request through the Python server
3. Calling the stable-diffusion.cpp binary with appropriate parameters
4. Saving the generated image to a configured output directory
5. Returning the path and metadata of the generated image to the client

### About stable-diffusion.cpp

[stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) is a highly optimized C++ implementation of the Stable Diffusion algorithm. Compared to the Python reference implementation, it offers:

- Significantly faster inference speed (up to 3-4x faster)
- Lower memory usage (works on GPUs with as little as 4GB VRAM)
- Optimized CUDA kernels for NVIDIA GPUs
- Support for various sampling methods and model formats
- Support for model quantization for better performance
- No Python dependencies for the core generation process

This allows DiffuGen to provide high-quality image generation with exceptional performance, even on modest hardware setups.

## ✨ Features

- **Multiple Model Support**: Generate images using various models including Flux Schnell, Flux Dev, SDXL, SD3, and SD1.5
- **MCP Integration**: Seamlessly integrates with IDEs that support MCP (Cursor, Windsurf, Roo Code, Cline, etc.)
- **OpenAPI Server**: Additional REST API interface for direct HTTP access to image generation capabilities
- **Cross-Platform**: Works on Linux, macOS, and Windows (via native or WSL)
- **Parameter Control**: Fine-tune your generations with controls for:
  - Image dimensions (width/height)
  - Sampling steps
  - CFG scale
  - Seed values
  - Negative prompts (for SD models only, Flux does not support negative prompts.)
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
- **RAM**: 8GB system memory
- **Storage**: 5GB free disk space (SSD preferred for faster model loading)
- **Python**: 3.8 or newer
- **GPU**: Integrated graphics or entry-level dedicated GPU (optional)
- **Network**: Broadband connection for model downloads (5+ Mbps)

### Recommended Requirements:

- **CPU**: 8+ core processor (Intel i7/i9 or AMD Ryzen 7/9)
- **RAM**: 16GB+ system memory
- **GPU**: NVIDIA GPU with 6GB+ VRAM (RTX 2060 or better for optimal performance)
- **Storage**: 20GB+ free SSD space
- **Python**: 3.10 or newer (3.11 offers best performance)
- **Network**: High-speed connection (20+ Mbps) for efficient model downloads

## 📥 Installation

### Automatic Installation (Recommended)

The easiest way to install DiffuGen is using the provided setup script:

```bash
git clone https://github.com/CLOUDWERX-DEV/diffugen.git
cd diffugen
chmod +x diffugen.sh
chmod +x setup_diffugen.sh
./setup_diffugen.sh
```

Follow the interactive prompts to complete the installation.

The setup script will:
- Install necessary dependencies
- Clone and build stable-diffusion.cpp
- Set up a Python virtual environment
- Download selected models (Note: Some models require Clip\VAE Models as well)
- Configure file paths for your system

### Manual Installation

If you prefer to install manually, follow these steps:

1. Clone the repositories:

```bash
git clone https://github.com/CLOUDWERX-DEV/diffugen.git
cd diffugen
git clone --recursive https://github.com/leejet/stable-diffusion.cpp
```

2. Build stable-diffusion.cpp:

```bash
cd stable-diffusion.cpp
mkdir -p build && cd build
```

With CUDA:
```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON
make -j$(nproc)
cd ../..
```

Without CUDA:
```bash
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ../..
```

3. Create and activate a Python virtual environment:

```bash
python3 -m venv diffugen_env
source diffugen_env/bin/activate  # On Windows: diffugen_env\Scripts\activate
pip install -r requirements.txt
```

4. Download required models (structure shown below):

```
stable-diffusion.cpp/models/
├── ae.sft                           # VAE model
├── clip_l.safetensors               # CLIP model
├── flux/
│   ├── flux-1-schnell.Q8_0.gguf     # Flux Schnell model (default)
│   └── flux-dev.Q8_0.gguf           # Flux Dev model
├── sd3-medium.safetensors           # SD3 model
├── sdxl-1.0-base.safetensors        # SDXL model
├── sdxl_vae-fp16-fix.safetensors    # SDXL VAE
├── t5xxl_fp16.safetensors           # T5 model
└── v1-5-pruned-emaonly.safetensors  # SD1.5 model
```

5. Update file paths in configuration: (this is fallback and you can always set ENV variable via the MCP json)

Set shell script as Executable

```
chmod +x diffugen.sh
```

Edit the `diffugen.py` script to update the `sd_cpp_path` variable to point to your stable-diffusion.cpp installation directory:

```python
# Example path update in diffugen.py
sd_cpp_path = os.path.normpath("/full/path/to/diffugen/stable-diffusion.cpp")
```

6. Create an MCP configuration file to use with your IDE:

```json
{
  "mcpServers": {
    "diffugen": {
      "command": "path/to/diffugen.sh",
      "args": [],
      "env": {
        "CUDA_VISIBLE_DEVICES": "0",
        "SD_CPP_PATH": "path/to/stable-diffusion.cpp"
      },
      "resources": {
        "models_dir": "path/to/stable-diffusion.cpp/models",
        "output_dir": "path/to/outputs",
        "vram_usage": "adaptive"
      },
      "metadata": {
        "name": "DiffuGen",
        "version": "1.0",
        "description": "Your AI art studio embedded directly in code. Generate, iterate, and perfect visual concepts through this powerful MCP server for Cursor, Windsurf, and other compatible IDEs, utilizing cutting-edge Flux and Stable Diffusion models without disrupting your development process.",
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
      },
      "default_params": {
        "steps": {
          "flux-schnell": 8,
          "flux-dev": 20,
          "sdxl": 20,
          "sd3": 20,
          "sd15": 20
        },
        "cfg_scale": {
          "flux-schnell": 1.0,
          "flux-dev": 1.0,
          "sdxl": 7.0,
          "sd3": 7.0, 
          "sd15": 7.0
        },
        "sampling_method": {
          "flux-schnell": "euler",
          "flux-dev": "euler",
          "sdxl": "euler",
          "sd3": "euler",
          "sd15": "euler"
        }
      }
    }
  }
}
```

## 🔧 IDE Setup Instructions

### Setting up with Cursor

1. Download and install [Cursor](https://cursor.sh)
2. Go to Cursor Settings > MCP and click "Add new global MCP server"
3. Add the DiffuGen configuration to your `~/.cursor/mcp.json` file (see the MCP configuration above)
4. Refresh MCP Servers in Settings > MCP
5. Use DiffuGen by opening the AI chat panel (Ctrl+K or Cmd+K) and requesting image generation

### Setting up with Windsurf

1. Download and install [Windsurf](https://codeium.com/windsurf)
2. Navigate to Windsurf > Settings > Advanced Settings or Command Palette > Open Windsurf Settings Page
3. Scroll down to the Cascade section and click "Add Server" > "Add custom server +"
4. Add the DiffuGen configuration to your `~/.codeium/windsurf/mcp_config.json` file
5. Use DiffuGen through the Cascade chat interface

### Setting up with Roo Code

1. Download and install [Roo Code](https://roo.ai)
2. Locate the MCP configuration file for Roo Code
3. Add the DiffuGen configuration, adjusting paths to match your installation
4. Use DiffuGen through the AI assistant feature

### Setting up with Cline

1. Download and install [Cline](https://cline.live)
2. Add the DiffuGen configuration to Cline's MCP settings
3. Use DiffuGen through the AI chat or command interface

### Setting up with Claude in Anthropic Console

Claude can use DiffuGen if you've set it up as an MCP server on your system. When asking Claude to generate images, be specific about using DiffuGen and provide the parameters you want to use.

## 🎮 Usage

To start the DiffuGen server manually:

```bash
cd /path/to/diffugen
./diffugen.sh
```

Or using Python directly:

```bash
cd /path/to/diffugen
python -m diffugen
```

You should see: `DiffuGen ready` when the server is successfully started.

### OpenAPI Server Usage

The OpenAPI server provides a REST API interface for direct HTTP access to DiffuGen's image generation capabilities. This is in addition to the MCP integration and can be useful for:
- Direct HTTP API access
- Integration with other tools that don't support MCP
- Custom applications that need programmatic access

For detailed setup instructions and advanced configuration options, see the [OpenAPI Integration Guide](OPENAPI_SETUP.md).

To start the OpenAPI server:
```bash
python diffugen_openapi.py
```

The server can be configured to use a different host or port if needed. By default, it runs on:
- Host: 0.0.0.0
- Port: 8080

The server will be available at http://0.0.0.0:8080 with interactive documentation at http://0.0.0.0:8080/docs.

Generated images are saved to the `/output` directory by default. If this directory is not accessible, the server will automatically create an `output` directory in the current working directory. Images are served through the `/images` endpoint.

#### OpenWebUI Integration

1. Open OpenWebUI Settings (gear icon)
2. Navigate to the "Tools" section
3. Click the "+" button to add a new tool server
4. Enter the following details:
   - URL: http://0.0.0.0:5199
   - API Key: (leave empty)
5. Click "Save"

Once added, DiffuGen will appear in the available tools list when clicking the tools icon in the chat interface. The following endpoints will be available:
- `generate_stable_image_generate_stable_post`: Generate with Stable Diffusion
- `generate_flux_image_endpoint_generate_flux_post`: Generate with Flux Models
- `list_models_models_get`: List Available Models

Example using curl:
```bash
curl -X POST "http://0.0.0.0:5199/generate/flux" \
     -H "Content-Type: application/json" \
     -d '{"prompt": "A beautiful sunset", "model": "flux-schnell"}'
```

Example using Python requests:
```python
import requests

response = requests.post(
    "http://0.0.0.0:5199/generate/flux",
    json={
        "prompt": "A beautiful sunset",
        "model": "flux-schnell"
    }
)
result = response.json()
```

### Default Parameters by Model

Each model has specific default parameters optimized for best results:

| Model | Default Steps | Default CFG Scale | Best For |
|-------|--------------|-----------------|----------|
| flux-schnell | 8 | 1.0 | Fast drafts, conceptual images |
| flux-dev | 20 | 1.0 | Better quality flux generations |
| sdxl | 20 | 7.0 | High-quality detailed images |
| sd3 | 20 | 7.0 | Latest generation with good quality |
| sd15 | 20 | 7.0 | Classic baseline model |

These default parameters can be customized by adding a `default_params` section to your IDE's MCP configuration file:

```json
"default_params": {
  "steps": {
    "flux-schnell": 12,  // Customize steps for better quality
    "sdxl": 30           // Increase steps for more detailed SDXL images
  },
  "cfg_scale": {
    "sd15": 9.0          // Higher cfg_scale for stronger prompt adherence
  }
}
```

You only need to specify the parameters you want to override - any unspecified values will use the built-in defaults.

> **Note**: For model-specific command line examples and recommendations, see [Model-Specific Parameter Recommendations](#model-specific-parameter-recommendations) section.

### Asking a LLM to Generate Images

Here are examples of how to ask an AI assistant to generate images with DiffuGen:

#### Basic Requests:

```
Generate an image of a cat playing with yarn
```

```
Create a picture of a futuristic cityscape with flying cars
```

#### With Model Specification:

```
Generate an image of a medieval castle using the sdxl model
```

```
Create a flux image of a sunset over mountains
```

#### With Advanced Parameters:

```
Generate an image of a cyberpunk street scene, model=flux-dev, width=768, height=512, steps=25, cfg_scale=1.0, seed=42
```

```
Create an illustration of a fantasy character with model=sd15, width=512, height=768, steps=30, cfg_scale=7.5, sampling_method=dpm++2m, negative_prompt=blurry, low quality, distorted
```

### Parameter Reference

DiffuGen can be used from the command line with the following basic syntax:

```bash
./diffugen.sh "Your prompt here" [options]
```

Example:
```bash
./diffugen.sh "A futuristic cityscape with flying cars"
```

This command generates an image using default parameters (flux-schnell model, 512x512 resolution, etc.) and saves it to the configured output directory.

Below are the parameters that can be used with DiffuGen (applicable to both MCP interface and command line):

| Parameter | Description | Default | Valid Values | Command Line Flag |
|-----------|-------------|---------|-------------|-------------------|
| model | The model to use for generation | flux-schnell/sd15 | flux-schnell, flux-dev, sdxl, sd3, sd15 | --model |
| width | Image width in pixels | 512 | 256-2048 | --width |
| height | Image height in pixels | 512 | 256-2048 | --height |
| steps | Number of diffusion steps | model-specific | 1-100 | --steps |
| cfg_scale | Classifier-free guidance scale | model-specific | 0.1-30.0 | --cfg-scale |
| seed | Random seed for reproducibility | -1 (random) | -1 or any integer | --seed |
| sampling_method | Diffusion sampling method | euler | euler, euler_a, heun, dpm2, dpm++2s_a, dpm++2m, dpm++2mv2, lcm | --sampling-method |
| negative_prompt | Elements to avoid in the image | "" (empty) | Any text string | --negative-prompt |
| output_dir | Directory to save images | Config-defined | Valid path | --output-dir |

These parameters can be specified when asking an AI assistant to generate images or when using the command line interface. Parameters are passed in different formats depending on the interface:

- **In MCP/AI Assistant**: `parameter=value` (e.g., `model=sdxl, width=768, height=512`)
- **In Command Line**: `--parameter value` (e.g., `--model sdxl --width 768 --height 512`)

The default values are chosen to provide good results out-of-the-box with minimal waiting time. For higher quality images, consider increasing steps or switching to models like sdxl.

### Model-Specific Parameter Recommendations

> **Note**: These recommendations build on the [Default Parameters by Model](#default-parameters-by-model) section and provide practical examples.

For best results when using specific models via command line:

#### Flux Models (flux-schnell, flux-dev)
```bash
# Flux-Schnell (fastest)
./diffugen.sh "Vibrant colorful abstract painting" \
  --model flux-schnell \
  --cfg-scale 1.0 \
  --sampling-method euler \
  --steps 8

# Flux-Dev (better quality)
./diffugen.sh "Detailed fantasy landscape with mountains and castles" \
  --model flux-dev \
  --cfg-scale 1.0 \
  --sampling-method euler \
  --steps 20
```

#### Standard SD Models (sdxl, sd3, sd15)
```bash
# SDXL (highest quality)
./diffugen.sh "Hyperrealistic portrait of a Celtic warrior" \
  --model sdxl \
  --cfg-scale 7.0 \
  --sampling-method dpm++2m \
  --steps 30

# SD15 (classic model)
./diffugen.sh "Photorealistic landscape at sunset" \
  --model sd15 \
  --cfg-scale 7.0 \
  --sampling-method euler_a \
  --steps 20
```

### Default Parameter Changes

The command-line interface of DiffuGen uses the following defaults if not otherwise specified in configuration:

- Default Model: If not specified, function-appropriate models are used (flux-schnell for Flux functions, sd15 for SD functions)
- Default Sampling Method: `euler` (best for Flux models)
- Default CFG Scale: `1.0` for Flux models, `7.0` for standard SD models
- Default Steps: `8` for flux-schnell, `20` for other models
- Default Dimensions: 512x512 pixels

When using the command line, you don't need to specify these parameters unless you want to override the defaults. If you frequently use specific parameters, consider adding them to your configuration file rather than specifying them on each command line.

### Command Line Usage Notes

- Generated images are saved to the configured output directory with filenames based on timestamp and parameters
- You can generate multiple images in sequence by running the command multiple times
- For batch processing, consider creating a shell script that calls DiffuGen with different parameters
- To see all available command-line options, run `./diffugen.sh --help`
- The same engine powers both the MCP interface and command-line tool, so quality and capabilities are identical

## ⚙️ Configuration

DiffuGen provides a template JSON configuration file (`diffugen.json`) that defines server settings, environment variables, and resource paths. This template should be copied into your IDE's MCP configuration file. This section explains the various configuration options available.

### OpenAPI Server Configuration

The OpenAPI server uses the same configuration as the main DiffuGen server, but with additional options:
- Port configuration (default: 5199)
- CORS settings
- Rate limiting

### MCP Configuration File Structure

The MCP configuration file has the following structure:

```json
{
  "mcpServers": {
    "diffugen": {
      "command": "/path/to/diffugen.sh",
      "args": [],
      "env": {
        "CUDA_VISIBLE_DEVICES": "0",
        "SD_CPP_PATH": "/path/to/stable-diffusion.cpp"
      },
      "resources": {
        "models_dir": "/path/to/stable-diffusion.cpp/models",
        "output_dir": "/path/to/outputs",
        "vram_usage": "adaptive"
      },
      "metadata": {
        // metadata fields
      },
      "cursorOptions": {
        // Cursor-specific options
      },
      "windsurfOptions": {
        // Windsurf-specific options
      }
    }
  }
}
```

### Key Configuration Elements

#### Command and Arguments

- **command**: Full path to the `diffugen.sh` script
- **args**: Additional command-line arguments to pass to the script (usually left empty)

#### Environment Variables

- **CUDA_VISIBLE_DEVICES**: Controls which GPUs are used for generation
  - `"0"`: Use only the first GPU
  - `"1"`: Use only the second GPU
  - `"0,1"`: Use both first and second GPUs
  - `"-1"`: Disable CUDA and use CPU only

- **SD_CPP_PATH**: Path to the stable-diffusion.cpp installation directory
  - This is used to locate the stable-diffusion.cpp binary and models

#### Resource Configuration

- **models_dir**: Directory containing the model files
  - Should point to the `models` directory inside your stable-diffusion.cpp installation

- **output_dir**: Directory where generated images will be saved
  - Must be writable by the user running DiffuGen

- **vram_usage**: Controls VRAM usage strategy
  - `"adaptive"`: Automatically adjust memory usage based on available VRAM
  - `"minimal"`: Use minimal VRAM at the cost of speed
  - `"balanced"`: Balance memory usage and speed (default)
  - `"maximum"`: Use maximum available VRAM for best performance

### IDE-Specific Options

#### Cursor Options

```json
"cursorOptions": {
  "autoApprove": true,
  "category": "Image Generation",
  "icon": "🖼️",
  "displayName": "DiffuGen"
}
```

- **autoApprove**: Whether to automatically approve tool use without user confirmation
- **category**: Category for grouping in the Cursor MCP tools list
- **icon**: Emoji icon to display in the UI
- **displayName**: Display name in the Cursor UI

#### Windsurf Options

```json
"windsurfOptions": {
  "displayName": "DiffuGen",
  "icon": "🖼️",
  "category": "Creative Tools"
}
```

- **displayName**: Display name in the Windsurf UI
- **icon**: Emoji icon to display in the UI
- **category**: Category for grouping in the Windsurf tools list

### Configuration File Locations

There are two ways DiffuGen uses configuration:

1. **Primary Method**: Copy the diffugen.json template into your IDE's MCP configuration file:
   - Cursor: `~/.cursor/mcp.json`
   - Windsurf: `~/.codeium/windsurf/mcp_config.json`
   - Roo Code and Cline: Check IDE documentation for specific paths

2. **Fallback Method**: DiffuGen will also look for configuration in these locations (in order):
   - Environment variables (SD_CPP_PATH, DIFFUGEN_OUTPUT_DIR)
   - Local `./diffugen.json` in the DiffuGen directory (as a fallback)
   - IDE-specific MCP configuration files

The recommended approach is to add DiffuGen's configuration to your IDE's MCP configuration file, as this is how the IDE will know how to launch and communicate with DiffuGen.

### Customizing Default Parameters

You can customize default parameters for each model by adding a `default_params` section to your configuration:

```json
"default_params": {
  "steps": {
    "flux-schnell": 12,
    "sdxl": 30
  },
  "cfg_scale": {
    "sd15": 9.0
  },
  "sampling_method": {
    "flux-schnell": "euler",
    "sdxl": "dpm++2m"
  }
}
```

This allows you to override the built-in defaults for specific models.

### Updating Configuration Files

When using the automatic setup script, a template configuration file (diffugen.json) is created automatically with proper paths for your system. To integrate DiffuGen with your IDE:

1. Copy the contents of the generated `diffugen.json` file
2. Paste it into your IDE's MCP configuration file (e.g., `~/.cursor/mcp.json`)
3. Verify that paths match your installation
4. Restart your IDE to apply changes

While DiffuGen can read from a local diffugen.json file as a fallback, the proper way to use DiffuGen is through your IDE's MCP integration, which requires adding the configuration to your IDE's MCP config file.

## 📃 Advanced Usage

The DiffuGen Python module can be imported and used programmatically in your own Python scripts:

```python
from diffugen import generate_image

# Generate an image programmatically
result = generate_image(
    prompt="A starry night over a quiet village",
    model="sdxl",
    width=1024,
    height=768,
    steps=30,
    cfg_scale=7.0,
    seed=42,
    sampling_method="dpm++2m",
    negative_prompt="blurry, low quality"
)

print(f"Image saved to: {result['file_path']}")
```

### Using the OpenAPI Server

You can also use the OpenAPI server programmatically in your applications:

```python
import requests

def generate_image_via_api(prompt, model="flux-schnell", width=512, height=512):
    response = requests.post(
        "http://0.0.0.0:5199/generate/flux",
        json={
            "prompt": prompt,
            "model": model,
            "width": width,
            "height": height
        }
    )
    return response.json()

# Example usage
result = generate_image_via_api(
    prompt="A magical forest at night",
    model="flux-schnell",
    width=768,
    height=512
)
print(f"Generated image: {result['file_path']}")
```

## 🔍 Troubleshooting

### Common Issues and Solutions

1. **Missing models or incorrect paths**
   - Ensure all model files are downloaded and placed in the correct directories
   - Check that paths in the configuration file are correctly set
   - Verify file permissions allow read access to model files

2. **CUDA/GPU issues**
   - Make sure your NVIDIA drivers are up-to-date
   - Set `CUDA_VISIBLE_DEVICES` to target a specific GPU
   - If running out of VRAM, try using a smaller model or reducing dimensions

3. **Image quality issues**
   - Increase steps for better quality (at the cost of generation time)
   - Adjust CFG scale: higher for more prompt adherence, lower for creativity
   - Try different sampling methods (dpm++2m often provides good results)
   - Use more detailed prompts with specific style descriptions

4. **File permission errors**
   - Ensure the output directory is writable by the user running DiffuGen
   - Check that all scripts have execution permissions (`chmod +x diffugen.sh`)

### Getting Help

If you encounter issues not covered here, you can:
- Check the GitHub repository for issues and solutions
- Run with debug logging enabled: `DEBUG=1 ./diffugen.sh "your prompt"`
- Contact the developers via GitHub issues

## 🌟 Contributing

Contributions to DiffuGen are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please ensure your code follows the project's coding standards and includes appropriate tests.

## 📄 License

This project is licensed under the Apache License - see the LICENSE file for details.

* All models are licensed under their respective distribution and are not in any way licensed or provided by CLOUDWERX.DEV
* HuggingFace.co is used to download models and is not affiliated in any way with CLOUDWERX.DEV

## 🙏 Acknowledgments

- [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) for the optimized C++ implementation
- [Stability AI](https://stability.ai/) for Stable Diffusion models
- [Black Forest Labs](https://blackforestlabs.ai/) for their Flux Models
- [Hugging Face](https://huggingface.co/) for the download links
- All contributors to the MCP protocol

## 📬 Contact

- GitHub: [CLOUDWERX-DEV](https://github.com/CLOUDWERX-DEV)
- Website: [cloudwerx.dev](http://cloudwerx.dev)
- Mail: [sysop@cloudwerx.dev](mailto:sysop@cloudwerx.dev)
- Discord: [Join our server](https://discord.gg/SvZFuufNTQ)

```
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
