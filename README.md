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
</p>

## 📋 Table of Contents

- [Introduction](#-introduction)
- [Understanding MCP and DiffuGen](#-understanding-mcp-and-diffugen)
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [IDE Setup Instructions](#-ide-setup-instructions)
- [Usage](#-usage)
  - [Default Parameters by Model](#default-parameters-by-model)
  - [Asking a LLM to Generate Images](#asking-a-llm-to-generate-images)
  - [Parameter Reference](#parameter-reference)
- [Command Line Usage](#-command-line-usage)
  - [Basic Command Line Syntax](#basic-command-line-syntax)
  - [Command Line Parameters](#command-line-parameters)
  - [Command Line Examples](#command-line-examples)
  - [Model-Specific Parameter Recommendations](#model-specific-parameter-recommendations)
  - [Default Parameter Changes](#default-parameter-changes)
  - [Command Line Usage Notes](#command-line-usage-notes)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Advanced Usage](#-advanced-usage)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Contact](#-contact)

## 🚀 Introduction

DiffuGen is an advanced image generation tool powered by Stable Diffusion, designed to seamlessly integrate with modern development environments through the MCP (Model Context Protocol) interface. It supports multiple Stable Diffusion models including Flux Schnell, Flux Dev, SDXL, and SD3, allowing for high-quality image generation with precise control over parameters.

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
- **diffugen.json**: Configuration file for MCP integration with various IDEs
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

### Default Parameters by Model

Each model has specific default parameters optimized for best results:

| Model | Default Steps | Default CFG Scale | Best For |
|-------|--------------|-----------------|----------|
| flux-schnell | 8 | 1.0 | Fast drafts, conceptual images |
| flux-dev | 20 | 1.0 | Better quality flux generations |
| sdxl | 20 | 7.0 | High-quality detailed images |
| sd3 | 20 | 7.0 | Latest generation with good quality |
| sd15 | 20 | 7.0 | Classic baseline model |

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
## 📝 Configuration

DiffuGen can be configured via the `diffugen.json` file in the root directory:

```json
{
  "sd_cpp_path": "/path/to/stable-diffusion.cpp",
  "models_dir": "/path/to/stable-diffusion.cpp/models",
  "output_dir": "/path/to/outputs",
  "default_model": "flux-schnell",
  "vram_usage": "adaptive",
  "gpu_layers": -1,
  "default_params": {
    "width": 512,
    "height": 512,
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
    "sampling_method": "euler"
  }
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `sd_cpp_path` | Path to stable-diffusion.cpp directory | Required |
| `models_dir` | Path to models directory | `${sd_cpp_path}/models` |
| `output_dir` | Path where generated images are saved | `./outputs` |
| `default_model` | Default model to use when not specified | `flux-schnell` |
| `vram_usage` | VRAM usage policy | `adaptive` |
| `gpu_layers` | Number of layers to offload to GPU (-1 for auto) | `-1` |
| `default_params` | Default parameters for image generation | See above |


### Parameter Reference

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|-------------|
| `prompt` | The image description | (Required) | Any text |
| `model` | Model to use | `flux-schnell` | `flux-schnell`, `flux-dev`, `sdxl`, `sd3`, `sd15` |
| `width` | Image width in pixels | 512 | 64-2048 |
| `height` | Image height in pixels | 512 | 64-2048 |
| `steps` | Number of diffusion steps | Model-specific | 1-100 |
| `cfg_scale` | CFG scale parameter | Model-specific | 0-20 |
| `seed` | Seed for reproducibility | -1 (random) | Any integer, -1 for random |
| `sampling_method` | Sampling method | `euler` | `euler`, `euler_a`, `heun`, `dpm2`, `dpm++2s_a`, `dpm++2m`, `dpm++2mv2`, `lcm` |
| `negative_prompt` | Elements to avoid | `""` | Any text |

## 🖥️ Command Line Usage

DiffuGen can be used directly from the command line to generate images without needing to interact with an MCP client. This is useful for scripting, batch processing, or when you want to quickly generate images without opening an IDE.

### Basic Command Line Syntax

The basic syntax for generating images from the command line is:

```bash
./diffugen.sh "Your prompt here" [options]
```

For example:
```bash
./diffugen.sh "A futuristic cityscape with flying cars"
```

This will generate an image using the default parameters (flux-schnell model, 512x512 resolution, etc.) and save it to the configured output directory.

### Command Line Parameters

All the parameters available in the MCP interface can also be specified on the command line:

| Parameter | Command Line Flag | Example |
|-----------|------------------|---------|
| Model | `--model` | `--model sdxl` |
| Width | `--width` | `--width 1024` |
| Height | `--height` | `--height 768` |
| Steps | `--steps` | `--steps 30` |
| CFG Scale | `--cfg-scale` | `--cfg-scale 7.0` |
| Seed | `--seed` | `--seed 42` |
| Sampling Method | `--sampling-method` | `--sampling-method dpm++2m` |
| Negative Prompt | `--negative-prompt` | `--negative-prompt "blurry, low quality"` |
| Output Directory | `--output-dir` | `--output-dir "./my_images"` |

### Command Line Examples

#### Generate an image with default settings:
```bash
./diffugen.sh "A beautiful mountain landscape"
```

#### Generate an image with a specific model:
```bash
./diffugen.sh "A medieval castle with dragons" --model sdxl
```

#### Generate with custom dimensions:
```bash
./diffugen.sh "A portrait of a cyberpunk character" --width 768 --height 1024
```

#### Generate with full parameter control:
```bash
./diffugen.sh "A steampunk airship floating above Victorian London" \
  --model sd15 \
  --width 1024 \
  --height 512 \
  --steps 30 \
  --cfg-scale 7.5 \
  --sampling-method dpm++2m \
  --seed 12345 \
  --negative-prompt "blurry, low quality, distorted"
```

### Model-Specific Parameter Recommendations

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

The command-line interface of DiffuGen has been optimized with sensible defaults:

- Default Model: `flux-schnell` (fastest model)
- Default Sampling Method: `euler` (best for Flux models)
- Default CFG Scale: `1.0` (optimal for Flux models)
- Default Steps: `8` for flux-schnell, `20` for other models
- Default Dimensions: 512x512 pixels

### Command Line Usage Notes

- Generated images are saved to the configured output directory with filenames based on timestamp and parameters
- You can generate multiple images in sequence by running the command multiple times
- For batch processing, consider creating a shell script that calls DiffuGen with different parameters
- To see all available command-line options, run `./diffugen.sh --help`
- The same engine powers both the MCP interface and command-line tool, so quality and capabilities are identical

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
