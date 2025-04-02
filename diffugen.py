import sys
import os
import logging
import subprocess
import uuid
import re
import argparse
import json
from pathlib import Path
import random
import time
import threading
import atexit

# Simplified logging setup - log only essential info
logging.basicConfig(
    filename='diffugen_debug.log',
    level=logging.INFO,  # Changed from DEBUG to INFO
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Queue management system
class GenerationQueue:
    def __init__(self):
        self.lock = threading.Lock()
        self.is_busy = False
        self.lock_file = os.path.join(os.getcwd(), "diffugen.lock")
        # Clean up any stale lock on startup
        self._remove_lock_file()
        # Register cleanup on exit
        atexit.register(self._remove_lock_file)
    
    def acquire(self, timeout=0):
        """Try to acquire the lock for image generation.
        Returns True if successful, False if busy."""
        with self.lock:
            # First check local thread lock
            if self.is_busy:
                logging.info("Image generation already in progress (local lock)")
                return False
                
            # Then check file lock (for inter-process locking)
            if os.path.exists(self.lock_file):
                try:
                    # Check if the lock file is stale (older than 30 minutes)
                    lock_time = os.path.getmtime(self.lock_file)
                    if time.time() - lock_time > 1800:  # 30 minutes
                        logging.warning("Found stale lock file, removing it")
                        self._remove_lock_file()
                    else:
                        with open(self.lock_file, 'r') as f:
                            pid = f.read().strip()
                        logging.info(f"Image generation already in progress by process {pid}")
                        return False
                except Exception as e:
                    logging.error(f"Error checking lock file: {e}")
                    return False
            
            # If we got here, no active generation is running
            try:
                with open(self.lock_file, 'w') as f:
                    f.write(str(os.getpid()))
                self.is_busy = True
                logging.info(f"Acquired generation lock (PID: {os.getpid()})")
                return True
            except Exception as e:
                logging.error(f"Error creating lock file: {e}")
                return False
    
    def release(self):
        """Release the generation lock."""
        with self.lock:
            self.is_busy = False
            self._remove_lock_file()
            logging.info("Released generation lock")
    
    def _remove_lock_file(self):
        """Remove the lock file if it exists."""
        try:
            if os.path.exists(self.lock_file):
                os.remove(self.lock_file)
        except Exception as e:
            logging.error(f"Error removing lock file: {e}")

# Create global generation queue
generation_queue = GenerationQueue()

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
        config["sd_cpp_path"] = os.path.normpath(os.environ.get("SD_CPP_PATH", config["sd_cpp_path"]))
    
    if "DIFFUGEN_OUTPUT_DIR" in os.environ:
        config["output_dir"] = os.path.normpath(os.environ.get("DIFFUGEN_OUTPUT_DIR", config["output_dir"]))
    
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
            "flux-schnell": os.path.join(models_dir, "flux", "flux1-schnell-q8_0.gguf"),
            "flux-dev": os.path.join(models_dir, "flux", "flux1-dev-q8_0.gguf"),
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
    """Generate an image using standard Stable Diffusion models (SDXL, SD3 or SD1.5)
    
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
    logging.info(f"Generate stable diffusion image request: prompt={prompt}, model={model}")
    
    # Use the generation queue to prevent concurrent generation
    if not generation_queue.acquire():
        return {
            "success": False,
            "error": "Another image generation is already in progress. Please try again when the current generation completes."
        }
    
    try:
        # Sanitize prompt and negative prompt
        sanitized_prompt = re.sub(r'[^\w\s.,;:!?\'"-]+', '', prompt).strip()
        sanitized_negative_prompt = negative_prompt
        if negative_prompt:
            sanitized_negative_prompt = re.sub(r'[^\w\s.,;:!?\'"-]+', '', negative_prompt).strip()
            
        # Select appropriate model
        if not model:
            model = "sd15"  # Default to SD1.5
        
        model = model.lower()
        
        # Only allow SD models in this function
        if model.startswith("flux-"):
            error_msg = f"Please use generate_flux_image for Flux models (received {model})"
            logging.error(error_msg)
            return {"success": False, "error": error_msg}
            
        # Normalize model name
        if model in ["sdxl", "sdxl-1.0", "sdxl1.0"]:
            model = "sdxl"
        elif model in ["sd3", "sd3-medium"]:
            model = "sd3"
        elif model in ["sd15", "sd1.5", "sd-1.5"]:
            model = "sd15"
        
        # Use default parameters if not specified
        if width is None:
            width = config["default_params"]["width"]
        
        if height is None:
            height = config["default_params"]["height"]
            
        if steps is None:
            steps = get_default_steps(model)
            
        if cfg_scale is None:
            cfg_scale = get_default_cfg_scale(model)
            
        if sampling_method is None:
            sampling_method = get_default_sampling_method()
        
        if output_dir is None:
            output_dir = default_output_dir
            
        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)
            
        # Get model path
        model_path = get_model_path(model)
        if not model_path:
            error_msg = f"Model not found: {model}"
            logging.error(error_msg)
            return {"success": False, "error": error_msg}
        
        # Generate a random seed if not provided
        if seed == -1:
            seed = random.randint(1, 1000000000)
            
        # Create output filename
        sanitized_prompt_for_filename = re.sub(r'[^\w\s]+', '', sanitized_prompt).strip()
        sanitized_prompt_for_filename = re.sub(r'\s+', '_', sanitized_prompt_for_filename)
        truncated_prompt = sanitized_prompt_for_filename[:20].lower()  # Limit to 20 chars
        unique_id = uuid.uuid4().hex[:8]
        output_filename = f"{model}_{truncated_prompt}_{unique_id}.png"
        output_path = os.path.join(output_dir, output_filename)
            
        # Prepare command for sd.cpp
        bin_path = os.path.join(sd_cpp_path, "build", "bin", "sd")
        
        base_command = [
            bin_path,
            "-p", sanitized_prompt
        ]
        
        # Add negative prompt if provided
        if sanitized_negative_prompt:
            base_command.extend(["--negative-prompt", sanitized_negative_prompt])
            
        # Add remaining parameters
        base_command.extend([
            "--cfg-scale", str(cfg_scale),
            "--sampling-method", sampling_method,
            "--steps", str(steps),
            "-H", str(height),
            "-W", str(width),
            "-o", output_path,
            "--seed", str(seed)
        ])
        
        # Add model-specific paths
        base_command.extend(["--diffusion-model", model_path])
        
        # Get supporting files
        vae_path = get_supporting_file("vae")
        clip_path = get_supporting_file("clip")
        clip_l_path = get_supporting_file("clip_l")
        t5xxl_path = get_supporting_file("t5xxl")
        
        if vae_path:
            base_command.extend(["--vae", vae_path])
        
        if model == "sdxl":
            if clip_path and t5xxl_path:
                base_command.extend(["--clip", clip_path])
                base_command.extend(["--t5xxl", t5xxl_path])
        elif model == "sd15":
            if clip_path:
                base_command.extend(["--clip", clip_path])
                
        # Add GPU and memory usage settings
        if config["vram_usage"] != "adaptive":
            base_command.append(f"--{config['vram_usage']}")
            
        if config["gpu_layers"] != -1:
            base_command.extend(["--gpu-layer", str(config["gpu_layers"])])
        
        try:
            # Run the command
            logging.info(f"Running command: {' '.join(base_command)}")
            
            result = subprocess.run(
                base_command,
                check=True,
                capture_output=True,
                text=True
            )
            
            logging.info(f"Successfully generated image at: {output_path} (size: {os.path.getsize(output_path)} bytes)")
            
            # Format the response to match OpenAPI style
            image_description = "Image of " + sanitized_prompt[:50] + ("..." if len(sanitized_prompt) > 50 else "")
            
            markdown_response = f"Here's the image you requested:\n\n{image_description}\n\n**Generation Details:**\n\nModel: {model}\nResolution: {width}x{height} pixels\nSteps: {steps}\nCFG Scale: {cfg_scale}\nSampling Method: {sampling_method}\nSeed: {seed}\nThis image was generated based on your prompt {sanitized_prompt}. Let me know if you'd like adjustments!"
            
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
                "output": result.stdout,
                "markdown_response": markdown_response
            }
        
        except subprocess.CalledProcessError as e:
            error_msg = f"Process error (exit code {e.returncode}): {str(e)}"
            logging.error(f"Image generation failed: {error_msg}")
            logging.error(f"Command: {' '.join(base_command)}")
            if e.stderr:
                logging.error(f"Process stderr: {e.stderr}")
            
            return {
                "success": False,
                "error": error_msg,
                "stderr": e.stderr,
                "command": " ".join(base_command),
                "exit_code": e.returncode
            }
        except FileNotFoundError as e:
            error_msg = f"Binary not found at {base_command[0]}"
            logging.error(f"Image generation failed: {error_msg}")
            
            return {
                "success": False,
                "error": error_msg,
                "command": " ".join(base_command),
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logging.error(f"Image generation failed with unexpected error: {error_msg}")
            logging.error(f"Command: {' '.join(base_command)}")
            
            return {
                "success": False,
                "error": error_msg,
                "command": " ".join(base_command),
            }
    finally:
        # Always release the lock when done
        generation_queue.release()

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
    logging.info(f"Generate flux image request: prompt={prompt}, model={model}")
    
    # Use the generation queue to prevent concurrent generation
    if not generation_queue.acquire():
        return {
            "success": False,
            "error": "Another image generation is already in progress. Please try again when the current generation completes."
        }
    
    try:
        # Sanitize prompt
        sanitized_prompt = re.sub(r'[^\w\s.,;:!?\'"-]+', '', prompt).strip()
            
        # Select appropriate model
        if not model:
            model = "flux-schnell"  # Default to flux-schnell
        
        model = model.lower()
        
        # Only allow Flux models in this function
        if not model.startswith("flux-"):
            # If the user specified an SD model, suggest using the other function
            if model in ["sdxl", "sd3", "sd15", "sd1.5"]:
                error_msg = f"Please use generate_stable_diffusion_image for standard SD models (received {model})"
            else:
                error_msg = f"Invalid model: {model}. For Flux image generation, use 'flux-schnell' or 'flux-dev'"
            logging.error(error_msg)
            return {"success": False, "error": error_msg}
            
        # Normalize model name
        if model in ["flux-schnell", "flux_schnell", "fluxschnell", "flux1-schnell"]:
            model = "flux-schnell"
        elif model in ["flux-dev", "flux_dev", "fluxdev", "flux1-dev"]:
            model = "flux-dev"
        
        # Use default parameters if not specified
        if width is None:
            width = config["default_params"]["width"]
        
        if height is None:
            height = config["default_params"]["height"]
            
        if steps is None:
            steps = get_default_steps(model)
            
        if cfg_scale is None:
            cfg_scale = get_default_cfg_scale(model)
            
        if sampling_method is None:
            sampling_method = get_default_sampling_method()
        
        if output_dir is None:
            output_dir = default_output_dir
            
        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)
            
        # Get model path
        model_path = get_model_path(model)
        if not model_path:
            error_msg = f"Model not found: {model}"
            logging.error(error_msg)
            return {"success": False, "error": error_msg}
        
        # Generate a random seed if not provided
        if seed == -1:
            seed = random.randint(1, 1000000000)
            
        # Create output filename
        sanitized_prompt_for_filename = re.sub(r'[^\w\s]+', '', sanitized_prompt).strip()
        sanitized_prompt_for_filename = re.sub(r'\s+', '_', sanitized_prompt_for_filename)
        truncated_prompt = sanitized_prompt_for_filename[:20].lower()  # Limit to 20 chars
        unique_id = uuid.uuid4().hex[:8]
        output_filename = f"{model}_{truncated_prompt}_{unique_id}.png"
        output_path = os.path.join(output_dir, output_filename)
            
        # Prepare command for sd.cpp
        bin_path = os.path.join(sd_cpp_path, "build", "bin", "sd")
        
        base_command = [
            bin_path,
            "-p", sanitized_prompt,
            "--cfg-scale", str(cfg_scale),
            "--sampling-method", sampling_method,
            "--steps", str(steps),
            "-H", str(height),
            "-W", str(width),
            "-o", output_path,
            "--diffusion-fa",  # Add Flux-specific flag
            "--seed", str(seed)
        ]
        
        # Add model-specific paths
        base_command.extend(["--diffusion-model", model_path])
        
        # Get supporting files for Flux
        vae_path = get_supporting_file("vae")
        clip_l_path = get_supporting_file("clip_l")
        t5xxl_path = get_supporting_file("t5xxl")
        
        if vae_path:
            base_command.extend(["--vae", vae_path])
        
        if clip_l_path:
            base_command.extend(["--clip_l", clip_l_path])
            
        if t5xxl_path:
            base_command.extend(["--t5xxl", t5xxl_path])
        
        # Add GPU and memory usage settings
        if config["vram_usage"] != "adaptive":
            base_command.append(f"--{config['vram_usage']}")
            
        if config["gpu_layers"] != -1:
            base_command.extend(["--gpu-layer", str(config["gpu_layers"])])
        
        try:
            # Run the command
            logging.info(f"Running command: {' '.join(base_command)}")
            
            result = subprocess.run(
                base_command,
                check=True,
                capture_output=True,
                text=True
            )
            
            logging.info(f"Successfully generated image at: {output_path} (size: {os.path.getsize(output_path)} bytes)")
            
            # Format the response to match OpenAPI style
            image_description = "Image of " + sanitized_prompt[:50] + ("..." if len(sanitized_prompt) > 50 else "")
            
            markdown_response = f"Here's the image you requested:\n\n{image_description}\n\n**Generation Details:**\n\nModel: {model}\nResolution: {width}x{height} pixels\nSteps: {steps}\nCFG Scale: {cfg_scale}\nSampling Method: {sampling_method}\nSeed: {seed}\nThis image was generated based on your prompt {sanitized_prompt}. Let me know if you'd like adjustments!"
            
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
                "output": result.stdout,
                "markdown_response": markdown_response
            }
        
        except subprocess.CalledProcessError as e:
            error_msg = f"Process error (exit code {e.returncode}): {str(e)}"
            logging.error(f"Image generation failed: {error_msg}")
            logging.error(f"Command: {' '.join(base_command)}")
            if e.stderr:
                logging.error(f"Process stderr: {e.stderr}")
            
            return {
                "success": False,
                "error": error_msg,
                "stderr": e.stderr,
                "command": " ".join(base_command),
                "exit_code": e.returncode
            }
        except FileNotFoundError as e:
            error_msg = f"Binary not found at {base_command[0]}"
            logging.error(f"Image generation failed: {error_msg}")
            
            return {
                "success": False,
                "error": error_msg,
                "command": " ".join(base_command),
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logging.error(f"Image generation failed with unexpected error: {error_msg}")
            logging.error(f"Command: {' '.join(base_command)}")
            
            return {
                "success": False,
                "error": error_msg,
                "command": " ".join(base_command),
            }
    finally:
        # Always release the lock when done
        generation_queue.release()

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
