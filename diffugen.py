from mcp.server.fastmcp import FastMCP
import subprocess
import os
import uuid
import re
from pathlib import Path

# Create an MCP server
mcp = FastMCP("Flux Image Generator")

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
    
    # Base command with common arguments
    base_command = [
        "./stable-diffusion.cpp/build/bin/sd",
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
    
    # Configure model-specific settings
    if model.lower() == "flux-schnell":
        base_command.extend([
            "--diffusion-model", "./stable-diffusion.cpp/models/flux/flux1-schnell-q8_0.gguf",
            "--vae", "./stable-diffusion.cpp/models/ae.sft",
            "--clip_l", "./stable-diffusion.cpp/models/clip_l.safetensors",
            "--t5xxl", "./stable-diffusion.cpp/models/t5xxl_fp16.safetensors"
        ])
    elif model.lower() == "flux-dev":
        base_command.extend([
            "--diffusion-model", "./stable-diffusion.cpp/models/flux/flux1-dev-q8_0.gguf",
            "--vae", "./stable-diffusion.cpp/models/ae.sft",
            "--clip_l", "./stable-diffusion.cpp/models/clip_l.safetensors",
            "--t5xxl", "./stable-diffusion.cpp/models/t5xxl_fp16.safetensors"
        ])
    elif model.lower() == "sdxl":
        base_command.extend([
            "-m", "./stable-diffusion.cpp/models/sd_xl_base_1.0.safetensors",
            "--vae", "./stable-diffusion.cpp/models/sdxl.vae.safetensors"
        ])
    elif model.lower() == "sd3":
        base_command.extend([
            "-m", "./stable-diffusion.cpp/models/sd3_medium_incl_clips_t5xxlfp16.safetensors"
        ])
    elif model.lower() == "sd15":
        base_command.extend([
            "-m", "./stable-diffusion.cpp/models/v1-5-pruned-emaonly.safetensors"
        ])
    else:
        # Default to Flux Schnell if model not recognized
        base_command.extend([
            "--diffusion-model", "./stable-diffusion.cpp/models/flux/flux1-schnell-q8_0.gguf",
            "--vae", "./stable-diffusion.cpp/models/ae.sft",
            "--clip_l", "./stable-diffusion.cpp/models/clip_l.safetensors",
            "--t5xxl", "./stable-diffusion.cpp/models/t5xxl_fp16.safetensors"
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
    mcp.run()
