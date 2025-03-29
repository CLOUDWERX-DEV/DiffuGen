import sys
import os
import logging
import subprocess
import uuid
import re
import argparse
import json
from pathlib import Path

# Simplified logging setup - log only essential info
logging.basicConfig(
    filename='diffugen_debug.log',
    level=logging.INFO,  # Changed from DEBUG to INFO
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Helper function to print to stderr
def log_to_stderr(message):
    print(message, file=sys.stderr, flush=True)

# Try to import real FastMCP with minimal error handling
mcp = None
try:
    from mcp.server.fastmcp import FastMCP
    mcp = FastMCP("DiffuGen")
except ImportError as e:
    log_to_stderr(f"Error importing FastMCP: {e}")
    
    # Simple fallback MCP implementation
    class FallbackMCP:
        def __init__(self, name):
            self.name = name
            log_to_stderr(f"Using fallback MCP server: {name}")
        
        def tool(self, *args, **kwargs):
            def decorator(func): return func
            return decorator
        
        def start(self): return True
    
    mcp = FallbackMCP("DiffuGen")

if mcp is None:
    log_to_stderr("Failed to create MCP server")
    sys.exit(1)

# Function to load configuration
def load_config():
    config = {
        "sd_cpp_path": os.path.join(os.getcwd(), "stable-diffusion.cpp"),
        "models_dir": None,  # Will be set based on sd_cpp_path if not provided
        "output_dir": os.getcwd(),
        "default_model": None,  # No default model, will be determined by function
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
    
    # Try to read from environment variables first
    if "SD_CPP_PATH" in os.environ:
        config["sd_cpp_path"] = os.path.normpath(os.environ["SD_CPP_PATH"])
    
    if "DIFFUGEN_OUTPUT_DIR" in os.environ:
        config["output_dir"] = os.path.normpath(os.environ["DIFFUGEN_OUTPUT_DIR"])
    
    # Try to read from diffugen.json configuration
    try:
        diffugen_json_path = os.path.join(os.getcwd(), "diffugen.json")
        if os.path.exists(diffugen_json_path):
            logging.info(f"Loading configuration from {diffugen_json_path}")
            with open(diffugen_json_path, 'r') as f:
                diffugen_config = json.load(f)
                # Update our config with values from diffugen.json config
                for key, value in diffugen_config.items():
                    config[key] = value
                    logging.info(f"Loaded config setting from diffugen.json: {key}")
    except Exception as e:
        logging.warning(f"Error loading diffugen.json configuration: {e}")
    
    # Also check for Cursor MCP config
    try:
        cursor_mcp_path = os.path.join(os.getcwd(), ".cursor", "mcp.json")
        if os.path.exists(cursor_mcp_path):
            logging.info(f"Loading configuration from {cursor_mcp_path}")
            with open(cursor_mcp_path, 'r') as f:
                cursor_config = json.load(f)
                if ('mcpServers' in cursor_config and 
                    'diffugen' in cursor_config.get('mcpServers', {}) and 
                    'resources' in cursor_config.get('mcpServers', {}).get('diffugen', {})):
                    
                    resources = cursor_config['mcpServers']['diffugen']['resources']
                    if 'output_dir' in resources:
                        config['output_dir'] = os.path.normpath(resources['output_dir'])
                        logging.info(f"Using output_dir from MCP config: {config['output_dir']}")
                    if 'models_dir' in resources:
                        config['models_dir'] = os.path.normpath(resources['models_dir'])
                        logging.info(f"Using models_dir from MCP config: {config['models_dir']}")
                    if 'SD_CPP_PATH' in resources:
                        config['sd_cpp_path'] = os.path.normpath(resources['SD_CPP_PATH'])
                        logging.info(f"Using sd_cpp_path from MCP config: {config['sd_cpp_path']}")
                    if 'vram_usage' in resources:
                        config['vram_usage'] = resources['vram_usage']
                        logging.info(f"Using vram_usage from MCP config: {config['vram_usage']}")
                    if 'gpu_layers' in resources:
                        config['gpu_layers'] = resources['gpu_layers']
                        logging.info(f"Using gpu_layers from MCP config: {config['gpu_layers']}")
                    # Look for default_model in environment variables section
                    if 'env' in cursor_config.get('mcpServers', {}).get('diffugen', {}) and 'default_model' in cursor_config['mcpServers']['diffugen']['env']:
                        config['default_model'] = cursor_config['mcpServers']['diffugen']['env']['default_model']
                        logging.info(f"Using default_model from MCP config: {config['default_model']}")
    except Exception as e:
        logging.warning(f"Error loading MCP configuration: {e}")
    
    # If models_dir wasn't set, use sd_cpp_path/models
    if not config["models_dir"]:
        config["models_dir"] = os.path.join(config["sd_cpp_path"], "models")
    
    return config

# Load the configuration
config = load_config()

# Core path initialization (using the config we loaded)
sd_cpp_path = os.path.normpath(config["sd_cpp_path"])
default_output_dir = os.path.normpath(config["output_dir"])

# Create output directory
os.makedirs(default_output_dir, exist_ok=True)

# Helper functions to get model-specific parameters from config
def get_default_steps(model):
    """Get default steps for a model"""
    model = model.lower()
    return config["default_params"]["steps"].get(model, 20)

def get_default_cfg_scale(model):
    """Get default CFG scale for a model"""
    model = model.lower()
    return config["default_params"]["cfg_scale"].get(model, 7.0)

def get_default_sampling_method():
    """Get default sampling method"""
    return config["default_params"]["sampling_method"]

# Lazy-loaded model paths - only resolved when needed
_model_paths = {}
_supporting_files = {}

def get_model_path(model_name):
    """Lazy-load model paths only when needed"""
    if not _model_paths:
        # Initialize paths only on first access
        models_dir = config["models_dir"]
        _model_paths.update({
            "flux-schnell": os.path.join(models_dir, "flux", "flux-1-schnell.Q8_0.gguf"),
            "flux-dev": os.path.join(models_dir, "flux", "flux1-dev-Q8_0.gguf"),
            "sdxl": os.path.join(models_dir, "sdxl-1.0-base.safetensors"),
            "sd3": os.path.join(models_dir, "sd3-medium.safetensors"),
            "sd15": os.path.join(models_dir, "sd15.safetensors"),
        })
    return _model_paths.get(model_name)

def get_supporting_file(file_name):
    """Lazy-load supporting file paths only when needed"""
    if not _supporting_files:
        # Initialize paths only on first access
        models_dir = config["models_dir"]
        _supporting_files.update({
            "vae": os.path.join(models_dir, "ae.sft"),
            "clip_l": os.path.join(models_dir, "clip_l.safetensors"),
            "t5xxl": os.path.join(models_dir, "t5xxl_fp16.safetensors"),
            "sdxl_vae": os.path.join(models_dir, "sdxl_vae-fp16-fix.safetensors")
        })
    return _supporting_files.get(file_name)

# Minimal ready message
log_to_stderr("DiffuGen ready")

@mcp.tool()
def generate_stable_diffusion_image(prompt: str, model: str = None, output_dir: str = None, 
                                   width: int = None, height: int = None, steps: int = None, 
                                   cfg_scale: float = None, seed: int = -1, 
                                   sampling_method: str = None, negative_prompt: str = "") -> dict:
    """
    Generate an image using standard Stable Diffusion models (NOT Flux).
    For Flux models (flux-schnell, flux-dev), use generate_flux_image instead.
    
    Args:
        prompt: The image description to generate
        model: Model to use (sdxl, sd3, sd15 only - NOT flux models)
        output_dir: Directory to save the image (defaults to current directory)
        width: Image width in pixels
        height: Image height in pixels
        steps: Number of diffusion steps
        cfg_scale: CFG scale parameter
        seed: Seed for reproducibility (-1 for random)
        sampling_method: Sampling method (euler, euler_a, heun, dpm2, dpm++2s_a, dpm++2m, dpm++2mv2, lcm)
        negative_prompt: Negative prompt (for supported models)
        
    Returns:
        A dictionary containing the path to the generated image and the command used
    """
    # Use configuration defaults if not provided, with sd15 as default for SD models
    model = model or config["default_model"] or "sd15"
    
    # For SD models, don't use flux models
    if model.lower().startswith("flux-"):
        model = "sd15"  # Default to sd15 if a flux model was selected
    
    width = width or config["default_params"]["width"]
    height = height or config["default_params"]["height"]
    sampling_method = sampling_method or get_default_sampling_method()
    cfg_scale = cfg_scale or get_default_cfg_scale(model)
    steps = steps or get_default_steps(model)
    
    # Validate that flux models are not used with this tool
    if model.lower().startswith("flux-"):
        return {
            "success": False,
            "error": f"Model {model} is a Flux model. Use generate_flux_image for Flux models."
        }
        
    # Sanitize the prompt to avoid command injection
    sanitized_prompt = re.sub(r'[^\w\s\-\.,;:!?()]', '', prompt)
    sanitized_negative = re.sub(r'[^\w\s\-\.,;:!?()]', '', negative_prompt) if negative_prompt else ""
    
    # Generate a unique filename for the output
    image_id = str(uuid.uuid4())[:8]
    safe_name = re.sub(r'\W+', '_', sanitized_prompt)[:30]
    filename = f"{model}_{safe_name}_{image_id}.png"
    
    # Determine output directory
    if not output_dir:
        output_dir = default_output_dir
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.normpath(os.path.join(output_dir, filename))
    
    # Base command with common arguments
    base_command = [
        os.path.normpath(os.path.join(sd_cpp_path, "build", "bin", "sd")),
        "-p", sanitized_prompt,
        "--cfg-scale", str(cfg_scale),
        "--sampling-method", sampling_method,
        "--steps", str(steps),
        "-H", str(height),
        "-W", str(width),
        "-o", output_path,
        "--diffusion-fa"
    ]
    
    # Add seed if specified
    if seed >= 0:
        base_command.extend(["--seed", str(seed)])
    
    # Add negative prompt if provided
    if negative_prompt:
        base_command.extend(["-n", sanitized_negative])
    
    # Add model-specific arguments using lazy-loaded paths
    if model.lower() == "sdxl":
        base_command.extend([
            "-m", get_model_path("sdxl"),
            "--vae", get_supporting_file("sdxl_vae")
        ])
    elif model.lower() == "sd3":
        base_command.extend([
            "-m", get_model_path("sd3")
        ])
    elif model.lower() == "sd15":
        base_command.extend([
            "-m", get_model_path("sd15")
        ])
    else:
        # Default to SD15 if model not recognized
        base_command.extend([
            "-m", get_model_path("sd15")
        ])
    
    # Detect platform and adjust paths if needed
    if os.name == 'nt':  # Windows
        base_command[0] = base_command[0].replace('/', '\\')
        for i in range(len(base_command)):
            if isinstance(base_command[i], str):
                base_command[i] = base_command[i].replace('/', '\\')
    
    try:
        # Execute the command
        result = subprocess.run(
            base_command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        return {
            "success": True,
            "image_path": output_path,
            "prompt": sanitized_prompt,
            "model": model,
            "width": width,
            "height": height,
            "steps": steps,
            "cfg_scale": cfg_scale,
            "seed": seed,
            "sampling_method": sampling_method,
            "negative_prompt": sanitized_negative if negative_prompt else None,
            "command": " ".join(base_command),
            "output": result.stdout
        }
        
    except subprocess.CalledProcessError as e:
        return {
            "success": False,
            "error": str(e),
            "stderr": e.stderr,
            "command": " ".join(base_command)
        }

@mcp.tool()
def generate_flux_image(prompt: str, output_dir: str = None, cfg_scale: float = None, 
                        sampling_method: str = None, steps: int = None,
                        model: str = None, width: int = None, 
                        height: int = None, seed: int = -1) -> dict:
    """
    Generate an image using Flux stable diffusion models ONLY.
    Use this tool for any request involving flux-schnell or flux-dev models.
    
    Args:
        prompt: The image description to generate
        model: Flux model to use (only "flux-schnell" or "flux-dev" are supported)
        output_dir: Directory to save the image (defaults to current directory)
        cfg_scale: CFG scale parameter (default: 1.0 for all flux models)
        sampling_method: Sampling method to use (default: euler)
        steps: Number of diffusion steps (default: 8 for flux-schnell, 20 for flux-dev)
        width: Image width in pixels (default: 512)
        height: Image height in pixels (default: 512)
        seed: Seed for reproducibility (-1 for random)
        
    Returns:
        A dictionary containing the path to the generated image and the command used
    """
    # Use configuration defaults if not provided, with flux-schnell as fallback for Flux models
    model = model or config["default_model"] or "flux-schnell"
    
    # If a non-flux model was specified, default to flux-schnell
    if not model.lower().startswith("flux-"):
        model = "flux-schnell"
        
    width = width or config["default_params"]["width"]
    height = height or config["default_params"]["height"]
    sampling_method = sampling_method or get_default_sampling_method()
    cfg_scale = cfg_scale or get_default_cfg_scale(model)
    steps = steps or get_default_steps(model)
    
    # Validate that only flux models are used with this tool
    if model.lower() not in ["flux-schnell", "flux-dev"]:
        return {
            "success": False,
            "error": f"Model {model} is not a Flux model. Only flux-schnell and flux-dev are supported by this tool."
        }
    
    # If output_dir is None, use the default_output_dir
    if output_dir is None:
        output_dir = default_output_dir
        
    # Sanitize the prompt to avoid command injection
    sanitized_prompt = re.sub(r'[^\w\s\-\.,;:!?()]', '', prompt)
    
    # Generate a unique filename for the output
    image_id = str(uuid.uuid4())[:8]
    safe_name = re.sub(r'\W+', '_', sanitized_prompt)[:30]
    filename = f"{model}_{safe_name}_{image_id}.png"
    
    # Determine output directory
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.normpath(os.path.join(output_dir, filename))
    
    # Base command with common arguments
    base_command = [
        os.path.normpath(os.path.join(sd_cpp_path, "build", "bin", "sd")),
        "-p", sanitized_prompt,
        "--cfg-scale", str(cfg_scale),
        "--sampling-method", sampling_method,
        "--steps", str(steps),
        "-H", str(height),
        "-W", str(width),
        "-o", output_path,
        "--diffusion-fa"
    ]
    
    # Add seed if specified
    if seed >= 0:
        base_command.extend(["--seed", str(seed)])
    
    # Add model-specific arguments - lazy-loaded
    if model.lower() == "flux-schnell":
        base_command.extend([
            "--diffusion-model", get_model_path("flux-schnell"),
            "--vae", get_supporting_file("vae"),
            "--clip_l", get_supporting_file("clip_l"),
            "--t5xxl", get_supporting_file("t5xxl")
        ])
    elif model.lower() == "flux-dev":
        base_command.extend([
            "--diffusion-model", get_model_path("flux-dev"),
            "--vae", get_supporting_file("vae"),
            "--clip_l", get_supporting_file("clip_l"),
            "--t5xxl", get_supporting_file("t5xxl")
        ])
    
    # Detect platform and adjust paths if needed
    if os.name == 'nt':  # Windows
        base_command[0] = base_command[0].replace('/', '\\')
        for i in range(len(base_command)):
            if isinstance(base_command[i], str):
                base_command[i] = base_command[i].replace('/', '\\')
    
    try:
        # Execute the command
        result = subprocess.run(
            base_command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        return {
            "success": True,
            "image_path": output_path,
            "prompt": sanitized_prompt,
            "model": model,
            "width": width,
            "height": height,
            "steps": steps,
            "cfg_scale": cfg_scale,
            "seed": seed,
            "sampling_method": sampling_method,
            "command": " ".join(base_command),
            "output": result.stdout
        }
        
    except subprocess.CalledProcessError as e:
        return {
            "success": False,
            "error": str(e),
            "stderr": e.stderr,
            "command": " ".join(base_command)
        }

if __name__ == "__main__":
    try:
        # Check if command line arguments are provided for direct image generation
        if len(sys.argv) > 1:
            # Parse command line arguments
            parser = argparse.ArgumentParser(description="Generate images using Stable Diffusion")
            parser.add_argument("prompt", type=str, help="The image description to generate")
            parser.add_argument("--model", type=str, 
                                help="Model to use (flux-schnell, flux-dev, sdxl, sd3, sd15)")
            parser.add_argument("--width", type=int, default=config["default_params"]["width"], 
                                help="Image width in pixels")
            parser.add_argument("--height", type=int, default=config["default_params"]["height"], 
                                help="Image height in pixels")
            # For steps and cfg_scale, we'll determine the default based on the model after parsing
            parser.add_argument("--steps", type=int, default=None, 
                                help="Number of diffusion steps")
            parser.add_argument("--cfg-scale", type=float, dest="cfg_scale", default=None, 
                                help="CFG scale parameter")
            parser.add_argument("--seed", type=int, default=-1, 
                                help="Seed for reproducibility (-1 for random)")
            parser.add_argument("--sampling-method", type=str, dest="sampling_method", 
                                default=get_default_sampling_method(), 
                                help="Sampling method")
            parser.add_argument("--negative-prompt", type=str, dest="negative_prompt", default="", 
                                help="Negative prompt")
            parser.add_argument("--output-dir", type=str, dest="output_dir", default=None, 
                                help="Directory to save the image")
            
            # Parse arguments
            args, unknown = parser.parse_known_args()
            
            # Determine model - use from args, config, or choose appropriate default
            if args.model is None:
                args.model = config["default_model"]
                # If still None, prompt the user to specify a model
                if args.model is None:
                    log_to_stderr("Model not specified. Please specify a model using --model. Available options:")
                    log_to_stderr("  Flux models: flux-schnell, flux-dev")
                    log_to_stderr("  SD models: sdxl, sd3, sd15")
                    sys.exit(1)
                    
            # Set model-specific defaults if not provided
            if args.steps is None:
                args.steps = get_default_steps(args.model)
            if args.cfg_scale is None:
                args.cfg_scale = get_default_cfg_scale(args.model)
            
            # Determine which generation function to use based on model
            if args.model.lower().startswith("flux-"):
                log_to_stderr(f"Generating Flux image with model: {args.model}")
                result = generate_flux_image(
                    prompt=args.prompt,
                    model=args.model,
                    width=args.width,
                    height=args.height,
                    steps=args.steps,
                    cfg_scale=args.cfg_scale,
                    seed=args.seed,
                    sampling_method=args.sampling_method,
                    output_dir=args.output_dir
                )
            else:
                log_to_stderr(f"Generating standard image with model: {args.model}")
                result = generate_stable_diffusion_image(
                    prompt=args.prompt,
                    model=args.model,
                    width=args.width,
                    height=args.height,
                    steps=args.steps,
                    cfg_scale=args.cfg_scale,
                    seed=args.seed,
                    sampling_method=args.sampling_method,
                    negative_prompt=args.negative_prompt,
                    output_dir=args.output_dir
                )
            
            # Print the result path
            if result.get("success", False):
                print(f"Image generated successfully: {result['image_path']}")
                sys.exit(0)
            else:
                log_to_stderr(f"Image generation failed: {result.get('error', 'Unknown error')}")
                sys.exit(1)
        else:
            # No arguments provided, start the MCP server
            mcp.run()
    except Exception as e:
        logging.error(f"Error running DiffuGen: {e}")
        sys.exit(1)
