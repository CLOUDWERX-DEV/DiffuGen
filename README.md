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
chmod +x setup_diffugen.sh
./setup_diffugen.sh
```

Follow the interactive prompts to complete the installation.

The setup script will:
- Install necessary dependencies
- Clone and build stable-diffusion.cpp
- Set up a Python virtual environment
- Download selected models
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

5. Update file paths in configuration:

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
      "command": "./diffugen.sh",
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
| `sampling_method` | Sampling method | `euler_a` | `euler`, `euler_a`, `heun`, `dpm2`, `dpm++2s_a`, `dpm++2m`, `dpm++2mv2`, `lcm` |
| `negative_prompt` | Elements to avoid | `""` | Any text |

## ⚙️ Configuration

### Environment Variables

DiffuGen supports the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SD_CPP_PATH` | Path to stable-diffusion.cpp | `./stable-diffusion.cpp` |
| `DIFFUGEN_OUTPUT_DIR` | Where images are saved | Current directory |
| `DEFAULT_MODEL` | Default model to use | `flux-schnell` |
| `CUDA_VISIBLE_DEVICES` | CUDA devices to use | `0` |

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

## 🔍 Troubleshooting

### Common Issues

#### MCP Server Not Connecting
- Check paths in your MCP configuration
- Ensure diffugen.sh has executable permissions
- Verify Python environment is correctly activated
- Check log files for detailed error information

#### CUDA Errors
- Verify CUDA installation with `nvidia-smi`
- Try reducing model size or using CPU-only mode
- For low VRAM GPUs, try using `--vae-tiling`, `--vae-on-cpu`, and `--clip-on-cpu` options

#### Missing Models
- Run the setup script again to download missing models
- Check that all required files are in the correct locations
- Verify model filenames match those expected in the code

#### Poor Image Quality
- Increase the number of steps (e.g., from 20 to 30 or 50)
- Try different sampling methods (e.g., dpm++2m often gives good results)
- Adjust the CFG scale (higher for more prompt adherence)
- Use a more detailed prompt with specific style references

### Log Files

Logs are stored in the following locations:
- Build logs: `stable-diffusion.cpp/build/build.log`
- Runtime logs: `diffugen_debug.log`

## 🔮 Advanced Usage

### Custom Model Integration

DiffuGen can be extended to support additional models:

1. Add your model file to the models directory
2. Modify the MODEL_PATHS dictionary in diffugen.py to include your new model
3. Add any supporting files (VAE, CLIP, etc.) needed for your model

Example modification to diffugen.py:

```python
MODEL_PATHS = {
    "flux-schnell": os.path.join(sd_cpp_path, "models", "flux", "flux-1-schnell.Q8_0.gguf"),
    "flux-dev": os.path.join(sd_cpp_path, "models", "flux", "flux-dev.Q8_0.gguf"),
    "sdxl": os.path.join(sd_cpp_path, "models", "sdxl-1.0-base.safetensors"),
    "sd3": os.path.join(sd_cpp_path, "models", "sd3-medium.safetensors"),
    "sd15": os.path.join(sd_cpp_path, "models", "v1-5-pruned-emaonly.safetensors"),
    "my-custom-model": os.path.join(sd_cpp_path, "models", "my-custom-model.safetensors")
}
```

### Command Line Usage

You can also use DiffuGen directly from the command line:

```bash
./diffugen.sh "A beautiful sunset over mountains" --model flux-dev --width 1024 --height 768 --steps 30 --cfg-scale 7 --seed 42
```

Or using the Python script directly:

```python
from diffugen import generate_stable_diffusion_image

result = generate_stable_diffusion_image(
    prompt="a beautiful sunset over mountains",
    model="flux-dev",
    width=1024,
    height=768,
    steps=30,
    cfg_scale=1.0,
    seed=42
)
print(f"Image generated at: {result['image_path']}")
```

### Performance Optimization

For optimal performance:

- Use CUDA acceleration when available
- Adjust `vram_usage` based on your GPU
- For low VRAM GPUs, use the following options:
  - `--vae-tiling`
  - `--vae-on-cpu`
  - `--clip-on-cpu`
  - `--diffusion-fa`

### Batch Processing

To generate multiple images with different prompts:

```bash
./batch_generate.sh prompts.txt --model flux-dev --width 512 --height 512
```

Where `prompts.txt` contains one prompt per line.

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
