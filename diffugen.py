import sys
import os
import logging

# Set up logging to a file
logging.basicConfig(
    filename='diffugen_debug.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Log startup information
logging.debug("Starting diffugen.py")
logging.debug(f"Python version: {sys.version}")
logging.debug(f"Python executable: {sys.executable}")
logging.debug(f"Current working directory: {os.getcwd()}")
logging.debug(f"Environment variables: {dict(os.environ)}")
logging.debug(f"System path: {sys.path}")

# Add current directory to path if not already there
if os.getcwd() not in sys.path:
    sys.path.insert(0, os.getcwd())
    logging.debug(f"Added current directory to sys.path")

logging.debug(f"Final Python path: {sys.path}")
logging.debug("Starting to import modules...")

# Compatibility shim for exceptiongroup
try:
    import exceptiongroup
except ImportError:
    print("Creating exceptiongroup compatibility layer")
    import sys
    import builtins
    
    class ExceptionGroup(Exception):
        def __init__(self, message, exceptions):
            super().__init__(message)
            self.exceptions = exceptions
    
    class BaseExceptionGroup(BaseException):
        def __init__(self, message, exceptions):
            super().__init__(message)
            self.exceptions = exceptions
    
    sys.modules['exceptiongroup'] = type('exceptiongroup', (), {
        'ExceptionGroup': ExceptionGroup,
        'BaseExceptionGroup': BaseExceptionGroup
    })
    builtins.ExceptionGroup = ExceptionGroup
    builtins.BaseExceptionGroup = BaseExceptionGroup

# Handle anyio import if needed
try:
    import anyio
except ImportError:
    print("Creating extensive anyio compatibility layer")
    
    # Create a Mock module with all necessary submodules
    class MockModule:
        def __init__(self):
            pass
            
        def __getattr__(self, name):
            # Create submodules on demand
            print(f"Creating mock anyio.{name}")
            submodule = MockModule()
            setattr(self, name, submodule)
            return submodule
    
    anyio_mock = MockModule()
    # Add some basic functionality
    anyio_mock.run = lambda func, *args, **kwargs: None
    
    # Create the streams submodule
    streams_mock = MockModule()
    anyio_mock.streams = streams_mock
    
    # Register the module
    sys.modules['anyio'] = anyio_mock
    sys.modules['anyio.streams'] = streams_mock

# Define a fallback MCP class if imports fail
class FallbackMCP:
    def __init__(self, name):
        self.name = name
        print(f"Created fallback MCP server: {name}")
    
    def tool(self, *args, **kwargs):
        def decorator(func):
            print(f"Registered tool: {func.__name__}")
            return func
        return decorator
    
    def start(self):
        print(f"Started fallback MCP server: {self.name}")
        return True

# Try to import real FastMCP
mcp = None
try:
    from mcp.server.fastmcp import FastMCP
    logging.debug("Successfully imported FastMCP")
    # Create an MCP server with the real implementation
    logging.debug("Creating MCP server...")
    mcp = FastMCP("DiffuGen")
    logging.debug("MCP server created successfully")
except ImportError as e:
    logging.error(f"Error importing FastMCP: {e}")
    # Try alternative import
    try:
        logging.debug("Trying alternative import method...")
        import importlib.util
        import importlib.machinery
        
        # Try to locate mcp module
        for path in sys.path:
            mcp_init = os.path.join(path, 'mcp', '__init__.py')
            if os.path.exists(mcp_init):
                logging.debug(f"Found MCP module at {mcp_init}")
                break
        else:
            logging.error("Could not find mcp module in sys.path")
        
        logging.error("Alternative import failed")
        sys.exit(1)
    except Exception as e2:
        logging.error(f"Alternative import also failed: {e2}")
        sys.exit(1)
        
    logging.debug("Using fallback MCP implementation")
    mcp = FallbackMCP("DiffuGen")

if mcp is None:
    logging.error("Failed to create MCP server")
    sys.exit(1)

import subprocess
import uuid
import re
from pathlib import Path

# Get the path to the stable-diffusion.cpp directory from environment or use default
sd_cpp_path = os.environ.get("SD_CPP_PATH", "/path/to/DiffuGen/stable-diffusion.cpp")

# Define model paths based on the SD_CPP_PATH
MODEL_PATHS = {
    "flux-schnell": f"{sd_cpp_path}/models/flux/flux-1-schnell.Q8_0.gguf",
    "flux-dev": f"{sd_cpp_path}/models/flux/flux-dev.Q8_0.gguf",
    "sdxl": f"{sd_cpp_path}/models/sdxl-1.0-base.safetensors",
    "sd3": f"{sd_cpp_path}/models/sd3-medium.safetensors",
    "sd15": f"{sd_cpp_path}/models/v1-5-pruned-emaonly.safetensors"
}

# Define supporting files
SUPPORTING_FILES = {
    "vae": f"{sd_cpp_path}/models/ae.sft",
    "clip_l": f"{sd_cpp_path}/models/clip_l.safetensors",
    "t5xxl": f"{sd_cpp_path}/models/t5xxl_fp16.safetensors",
    "sdxl_vae": f"{sd_cpp_path}/models/sdxl_vae-fp16-fix.safetensors"
}

@mcp.tool()
def generate_stable_diffusion_image(prompt: str, model: str = "flux-schnell", output_dir: str = None, 
                                   width: int = 512, height: int = 512, steps: int = 20, 
                                   cfg_scale: float = 7.0, seed: int = -1, 
                                   sampling_method: str = "euler_a", negative_prompt: str = "") -> dict:
    """
    Generate an image using various Stable Diffusion models.
    
    Args:
        prompt: The image description to generate
        model: Model to use (flux-schnell, flux-dev, sdxl, sd3, sd15)
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
    # Sanitize the prompt to avoid command injection
    sanitized_prompt = re.sub(r'[^\w\s\-\.,;:!?()]', '', prompt)
    sanitized_negative = re.sub(r'[^\w\s\-\.,;:!?()]', '', negative_prompt) if negative_prompt else ""
    
    # Generate a unique filename for the output
    image_id = str(uuid.uuid4())[:8]
    safe_name = re.sub(r'\W+', '_', sanitized_prompt)[:30]
    filename = f"{model}_{safe_name}_{image_id}.png"
    
    # Determine output directory
    if not output_dir:
        output_dir = os.getcwd()
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, filename)
    
    # Log the SD_CPP_PATH for debugging
    logging.debug(f"Using SD_CPP_PATH: {sd_cpp_path}")
    
    # Base command with common arguments
    base_command = [
        f"{sd_cpp_path}/build/bin/sd",
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
    
    # Add model-specific arguments
    if model.lower() == "flux-schnell":
        base_command.extend([
            "--diffusion-model", MODEL_PATHS["flux-schnell"],
            "--vae", SUPPORTING_FILES["vae"],
            "--clip_l", SUPPORTING_FILES["clip_l"],
            "--t5xxl", SUPPORTING_FILES["t5xxl"]
        ])
    elif model.lower() == "flux-dev":
        base_command.extend([
            "--diffusion-model", MODEL_PATHS["flux-dev"],
            "--vae", SUPPORTING_FILES["vae"],
            "--clip_l", SUPPORTING_FILES["clip_l"],
            "--t5xxl", SUPPORTING_FILES["t5xxl"]
        ])
    elif model.lower() == "sdxl":
        base_command.extend([
            "-m", MODEL_PATHS["sdxl"],
            "--vae", SUPPORTING_FILES["sdxl_vae"]
        ])
    elif model.lower() == "sd3":
        base_command.extend([
            "-m", MODEL_PATHS["sd3"]
        ])
    elif model.lower() == "sd15":
        base_command.extend([
            "-m", MODEL_PATHS["sd15"]
        ])
    else:
        # Default to Flux Schnell if model not recognized
        base_command.extend([
            "--diffusion-model", MODEL_PATHS["flux-schnell"],
            "--vae", SUPPORTING_FILES["vae"],
            "--clip_l", SUPPORTING_FILES["clip_l"],
            "--t5xxl", SUPPORTING_FILES["t5xxl"]
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

# Keep the original function for backward compatibility
@mcp.tool()
def generate_flux_image(prompt: str, output_dir: str = None, cfg_scale: float = 1.0, 
                        sampling_method: str = "euler", steps: int = 4) -> dict:
    """
    Generate an image using Flux stable diffusion model.
    
    Args:
        prompt: The image description to generate
        output_dir: Directory to save the image (defaults to current directory)
        cfg_scale: CFG scale parameter (default: 1.0)
        sampling_method: Sampling method to use (default: euler)
        steps: Number of diffusion steps (default: 4)
        
    Returns:
        A dictionary containing the path to the generated image and the command used
    """
    return generate_stable_diffusion_image(
        prompt=prompt,
        model="flux-schnell",
        output_dir=output_dir,
        cfg_scale=cfg_scale,
        sampling_method=sampling_method,
        steps=steps
    )

if __name__ == "__main__":
    logging.debug("Starting MCP server with mcp.run()")
    try:
        mcp.run()
        logging.debug("MCP server run() method completed")
    except Exception as e:
        logging.error(f"Error running MCP server: {e}")
        import traceback
        logging.error(traceback.format_exc())
        sys.exit(1)
