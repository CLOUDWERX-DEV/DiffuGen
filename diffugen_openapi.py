from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Union
import os
import sys
import argparse
from pathlib import Path
from datetime import datetime

# Import DiffuGen functions
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from diffugen import generate_stable_diffusion_image, generate_flux_image, load_config, sd_cpp_path, _model_paths

# Convert paths to Path objects for better cross-platform compatibility
SD_CPP_PATH = Path(sd_cpp_path)

# Set default output directory
DEFAULT_OUTPUT_DIR = Path("/output")

# Try to create output directory with better error handling
try:
    os.makedirs(DEFAULT_OUTPUT_DIR, exist_ok=True)
except PermissionError:
    print(f"Warning: Could not create output directory at {DEFAULT_OUTPUT_DIR} due to permission error")
    print("Falling back to creating 'output' directory in current working directory")
    DEFAULT_OUTPUT_DIR = Path.cwd() / "output"
    try:
        os.makedirs(DEFAULT_OUTPUT_DIR, exist_ok=True)
    except Exception as e:
        print(f"Error: Could not create fallback output directory: {e}")
        print("Please ensure you have write permissions in the current directory")
        sys.exit(1)
except Exception as e:
    print(f"Error: Could not create output directory: {e}")
    print("Please check your system permissions and try again")
    sys.exit(1)

# Set environment variable for DiffuGen functions
os.environ["DIFFUGEN_OUTPUT_DIR"] = str(DEFAULT_OUTPUT_DIR)

app = FastAPI(
    title="DiffuGen",
    description="AI Image Generation API using Stable Diffusion and Flux models",
    version="1.0.0",
    terms_of_service="http://example.com/terms/",
    contact={
        "name": "DiffuGen Support",
        "url": "https://github.com/yourusername/diffugen",
        "email": "support@example.com",
    },
    license_info={
        "name": "Apache 2.0",
        "url": "https://www.apache.org/licenses/LICENSE-2.0.html",
    },
    openapi_tags=[
        {
            "name": "Image Generation",
            "description": "Generate images using various AI models"
        },
        {
            "name": "System",
            "description": "System information and health checks"
        },
        {
            "name": "Images",
            "description": "Manage generated images"
        }
    ]
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Mount the output directory for serving generated images
app.mount("/images", StaticFiles(directory=str(DEFAULT_OUTPUT_DIR)), name="images")

# Error response model
class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())

# Health check endpoint
@app.get("/health", tags=["System"], response_model=Dict[str, str])
async def health_check():
    """Check the health status of the API server"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

# System info endpoint
@app.get("/system", tags=["System"], response_model=Dict[str, Union[str, List[str]]])
async def system_info():
    """Get system information and configuration"""
    return {
        "python_version": sys.version,
        "sd_cpp_path": str(SD_CPP_PATH),
        "output_dir": str(DEFAULT_OUTPUT_DIR),
        "available_models": list(_model_paths.keys()),
        "timestamp": datetime.now().isoformat(),
        "platform": sys.platform
    }

# List images endpoint
@app.get("/images", tags=["Images"], response_model=Dict[str, List[Dict[str, str]]])
async def list_images():
    """List all generated images"""
    try:
        images = []
        for file in DEFAULT_OUTPUT_DIR.glob("*.[jp][pn][g]") + DEFAULT_OUTPUT_DIR.glob("*.jpeg"):
            images.append({
                "filename": file.name,
                "path": f"/images/{file.name}",
                "created": datetime.fromtimestamp(file.stat().st_ctime).isoformat()
            })
        return {"images": images}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# OpenAPI Tags Metadata
tags_metadata = [
    {
        "name": "generation",
        "description": "Image generation endpoints for both Stable Diffusion and Flux models",
    },
    {
        "name": "models",
        "description": "Model information and configuration endpoints",
    },
]

class ImageGenerationRequest(BaseModel):
    prompt: str = Field(..., description="Text prompt for image generation")
    model: Optional[str] = Field(None, description="Model to use for generation (e.g., 'sdxl', 'flux-schnell')")
    width: Optional[int] = Field(None, description="Image width in pixels", ge=64, le=2048)
    height: Optional[int] = Field(None, description="Image height in pixels", ge=64, le=2048)
    steps: Optional[int] = Field(None, description="Number of inference steps", ge=1, le=150)
    cfg_scale: Optional[float] = Field(None, description="Classifier-free guidance scale", ge=1.0, le=20.0)
    seed: Optional[int] = Field(-1, description="Random seed for generation (-1 for random)")
    sampling_method: Optional[str] = Field(None, description="Sampling method to use")
    negative_prompt: Optional[str] = Field("", description="Negative prompt for generation")
    output_dir: Optional[str] = Field(None, description="Output directory for generated images")

    class Config:
        json_schema_extra = {
            "example": {
                "prompt": "a beautiful sunset over mountains",
                "model": "sdxl",
                "width": 1024,
                "height": 1024,
                "steps": 30,
                "cfg_scale": 7.5,
                "seed": -1,
                "sampling_method": "euler_a",
                "negative_prompt": "blur, low quality"
            }
        }

class ImageGenerationResponse(BaseModel):
    success: bool
    image_path: Optional[str] = None
    image_url: Optional[str] = None
    error: Optional[str] = None
    model: Optional[str] = None
    prompt: Optional[str] = None
    parameters: Optional[dict] = None
    markdown_response: Optional[str] = None  # This will be the primary way to display the image

@app.post("/generate/stable", 
    response_model=ImageGenerationResponse, 
    tags=["Image Generation"],
    summary="Generate with Stable Diffusion",
    description="Generate images using standard Stable Diffusion models (SDXL, SD3, SD15)")
async def generate_stable_image(request: ImageGenerationRequest, req: Request):
    """Generate an image using standard Stable Diffusion models (SDXL, SD3, SD15)"""
    try:
        # If no model specified, use flux-schnell instead of defaulting to SD
        if not request.model:
            return await generate_flux_image_endpoint(request, req)
            
        result = generate_stable_diffusion_image(
            prompt=request.prompt,
            model=request.model,
            width=request.width,
            height=request.height,
            steps=request.steps,
            cfg_scale=request.cfg_scale,
            seed=request.seed,
            sampling_method=request.sampling_method,
            negative_prompt=request.negative_prompt,
            output_dir=str(DEFAULT_OUTPUT_DIR)
        )
        
        if not result.get("success", False):
            error_msg = result.get("error", "Unknown error")
            return ImageGenerationResponse(
                success=False,
                error=error_msg,
                markdown_response=f"Error generating image: {error_msg}"
            )
            
        # Create full image URL including host
        image_path = Path(result["image_path"])
        base_url = str(req.base_url).rstrip('/')
        image_url = f"{base_url}/images/{image_path.name}"
        
        # Create markdown-formatted response
        markdown_response = f"Here's the image you requested:\n\n![Image]({image_url})\n\n**Generation Details:**\n- Model: {result['model']}\n- Prompt: {result['prompt']}\n- Resolution: {result['width']}x{result['height']} pixels\n- Steps: {result['steps']}\n- CFG Scale: {result['cfg_scale']}\n- Sampling Method: {result['sampling_method']}\n- Seed: {result['seed'] if result['seed'] != -1 else 'random'}"
            
        return ImageGenerationResponse(
            success=True,
            image_path=str(image_path),
            markdown_response=markdown_response,
            model=result["model"],
            prompt=result["prompt"],
            parameters={
                "width": result["width"],
                "height": result["height"],
                "steps": result["steps"],
                "cfg_scale": result["cfg_scale"],
                "seed": result["seed"],
                "sampling_method": result["sampling_method"],
                "negative_prompt": result["negative_prompt"]
            }
        )
    except Exception as e:
        error_msg = str(e)
        return ImageGenerationResponse(
            success=False,
            error=error_msg,
            markdown_response=f"Error generating image: {error_msg}"
        )

@app.post("/generate/flux", 
    response_model=ImageGenerationResponse, 
    tags=["Image Generation"],
    summary="Generate with Flux Models",
    description="Generate images using Flux models (flux-schnell, flux-dev)")
async def generate_flux_image_endpoint(request: ImageGenerationRequest, req: Request):
    """Generate an image using Flux models (flux-schnell, flux-dev)"""
    try:
        # Set default model to flux-schnell if not specified
        if not request.model:
            request.model = "flux-schnell"
            
        result = generate_flux_image(
            prompt=request.prompt,
            model=request.model,
            width=request.width,
            height=request.height,
            steps=request.steps,
            cfg_scale=request.cfg_scale,
            seed=request.seed,
            sampling_method=request.sampling_method,
            output_dir=str(DEFAULT_OUTPUT_DIR)
        )
        
        if not result.get("success", False):
            error_msg = result.get("error", "Unknown error")
            return ImageGenerationResponse(
                success=False,
                error=error_msg,
                markdown_response=f"Error generating image: {error_msg}"
            )
            
        # Create full image URL including host
        image_path = Path(result["image_path"])
        base_url = str(req.base_url).rstrip('/')
        image_url = f"{base_url}/images/{image_path.name}"
        
        # Create markdown-formatted response
        markdown_response = f"Here's the image you requested:\n\n![Image]({image_url})\n\n**Generation Details:**\n- Model: {result['model']}\n- Prompt: {result['prompt']}\n- Resolution: {result['width']}x{result['height']} pixels\n- Steps: {result['steps']}\n- CFG Scale: {result['cfg_scale']}\n- Sampling Method: {result['sampling_method']}\n- Seed: {result['seed'] if result['seed'] != -1 else 'random'}"
            
        return ImageGenerationResponse(
            success=True,
            image_path=str(image_path),
            markdown_response=markdown_response,
            model=result["model"],
            prompt=result["prompt"],
            parameters={
                "width": result["width"],
                "height": result["height"],
                "steps": result["steps"],
                "cfg_scale": result["cfg_scale"],
                "seed": result["seed"],
                "sampling_method": result["sampling_method"]
            }
        )
    except Exception as e:
        error_msg = str(e)
        return ImageGenerationResponse(
            success=False,
            error=error_msg,
            markdown_response=f"Error generating image: {error_msg}"
        )

@app.get("/models", 
    tags=["Models"],
    summary="List Available Models",
    response_model=Dict[str, Dict[str, List[str]]])
async def list_models():
    """List available models and their default parameters"""
    config = load_config()
    return {
        "models": {
            "flux": ["flux-schnell", "flux-dev"],
            "stable": ["sdxl", "sd3", "sd15"]
        },
        "default_params": config["default_params"]
    }

@app.get("/openapi.json", include_in_schema=False)
async def get_openapi_schema():
    """Get OpenAPI schema with CORS support"""
    return app.openapi()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DiffuGen OpenAPI Server")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Host to bind to (default: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8080, help="Port to bind to (default: 8080)")
    args = parser.parse_args()
    
    import uvicorn
    print(f"Starting DiffuGen OpenAPI server on {args.host}:{args.port}")
    uvicorn.run(app, host=args.host, port=args.port) 