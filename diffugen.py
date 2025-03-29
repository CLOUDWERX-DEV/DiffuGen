import sys
import os
import logging
import subprocess
import uuid
import re
import argparse
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

# Core path initialization
sd_cpp_path = os.path.normpath(os.environ.get("SD_CPP_PATH", os.path.join(os.getcwd(), "stable-diffusion.cpp")))
default_output_dir = os.path.normpath(os.environ.get("DIFFUGEN_OUTPUT_DIR", os.getcwd()))

# Try to read from MCP configuration if output dir not explicitly set
if "DIFFUGEN_OUTPUT_DIR" not in os.environ:
    try:
        cursor_mcp_path = os.path.join(os.getcwd(), ".cursor", "mcp.json")
        if os.path.exists(cursor_mcp_path):
            import json
            with open(cursor_mcp_path, 'r') as f:
                mcp_config = json.load(f)
                if ('mcpServers' in mcp_config and 
                    'diffugen' in mcp_config.get('mcpServers', {}) and 
                    'resources' in mcp_config.get('mcpServers', {}).get('diffugen', {}) and 
                    'output_dir' in mcp_config.get('mcpServers', {}).get('diffugen', {}).get('resources', {})):
                    
                    default_output_dir = os.path.normpath(
                        mcp_config['mcpServers']['diffugen']['resources']['output_dir']
                    )
    except Exception:
        pass  # Silently continue with default if config can't be read

# Create output directory
os.makedirs(default_output_dir, exist_ok=True)

# Lazy-loaded model paths - only resolved when needed
_model_paths = {}
_supporting_files = {}

def get_model_path(model_name):
    """Lazy-load model paths only when needed"""
    if not _model_paths:
        # Initialize paths only on first access
        _model_paths.update({
            "flux-schnell": os.path.join(sd_cpp_path, "models", "flux", "flux-1-schnell.Q8_0.gguf"),
            "flux-dev": os.path.join(sd_cpp_path, "models", "flux", "flux1-dev-Q8_0.gguf"),
            "sdxl": os.path.join(sd_cpp_path, "models", "sdxl-1.0-base.safetensors"),
            "sd3": os.path.join(sd_cpp_path, "models", "sd3-medium.safetensors"),
            "sd15": os.path.join(sd_cpp_path, "models", "sd15.safetensors"),
        })
    return _model_paths.get(model_name)

def get_supporting_file(file_name):
    """Lazy-load supporting file paths only when needed"""
    if not _supporting_files:
        # Initialize paths only on first access
        _supporting_files.update({
            "vae": os.path.join(sd_cpp_path, "models", "ae.sft"),
            "clip_l": os.path.join(sd_cpp_path, "models", "clip_l.safetensors"),
            "t5xxl": os.path.join(sd_cpp_path, "models", "t5xxl_fp16.safetensors"),
            "sdxl_vae": os.path.join(sd_cpp_path, "models", "sdxl_vae-fp16-fix.safetensors")
        })
    return _supporting_files.get(file_name)

# Minimal ready message
log_to_stderr("DiffuGen ready")

@mcp.tool()
def generate_stable_diffusion_image(prompt: str, model: str = "sd15", output_dir: str = None, 
                                   width: int = 512, height: int = 512, steps: int = 20, 
                                   cfg_scale: float = 7.0, seed: int = -1, 
                                   sampling_method: str = "euler_a", negative_prompt: str = "") -> dict:
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
                        sampling_method: str = "euler", steps: int = None,
                        model: str = "flux-schnell", width: int = 512, 
                        height: int = 512, seed: int = -1) -> dict:
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
    # Validate that only flux models are used with this tool
    if model.lower() not in ["flux-schnell", "flux-dev"]:
        return {
            "success": False,
            "error": f"Model {model} is not a Flux model. Only flux-schnell and flux-dev are supported by this tool."
        }
    
    # Set model-specific defaults if not provided
    if cfg_scale is None:
        cfg_scale = 1.0  # Same default for both models
    
    if steps is None:
        if model.lower() == "flux-schnell":
            steps = 8  # Default for flux-schnell
        else:  # flux-dev
            steps = 20  # Default for flux-dev
    
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
            parser.add_argument("--model", type=str, default="flux-schnell", help="Model to use (flux-schnell, flux-dev, sdxl, sd3, sd15)")
            parser.add_argument("--width", type=int, default=512, help="Image width in pixels")
            parser.add_argument("--height", type=int, default=512, help="Image height in pixels")
            parser.add_argument("--steps", type=int, default=8, help="Number of diffusion steps")
            parser.add_argument("--cfg-scale", type=float, dest="cfg_scale", default=1.0, help="CFG scale parameter")
            parser.add_argument("--seed", type=int, default=-1, help="Seed for reproducibility (-1 for random)")
            parser.add_argument("--sampling-method", type=str, dest="sampling_method", default="euler", help="Sampling method")
            parser.add_argument("--negative-prompt", type=str, dest="negative_prompt", default="", help="Negative prompt")
            parser.add_argument("--output-dir", type=str, dest="output_dir", default=None, help="Directory to save the image")
            
            # Parse arguments
            args, unknown = parser.parse_known_args()
            
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
