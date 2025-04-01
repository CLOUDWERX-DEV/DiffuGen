from fastapi import FastAPI, HTTPException, Request, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware import Middleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Union, Callable
import os
import sys
import json
import time
import re
import argparse
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from itertools import chain

# Import DiffuGen functions
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from diffugen import generate_stable_diffusion_image, generate_flux_image, load_config as load_diffugen_config, sd_cpp_path as default_sd_cpp_path, _model_paths

# Load OpenAPI configuration
def load_openapi_config():
    """Load the OpenAPI server configuration from openapi_config.json."""
    config = {}
    config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "openapi_config.json")
    
    try:
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
                print(f"Loaded OpenAPI configuration from {config_file}")
        else:
            print(f"OpenAPI configuration file not found at {config_file}, using defaults")
    except Exception as e:
        print(f"Error loading OpenAPI configuration: {e}")
        print("Using default configuration")
    
    # Set defaults for missing values
    if "server" not in config:
        config["server"] = {"host": "0.0.0.0", "port": 5199, "debug": False}
    if "paths" not in config:
        config["paths"] = {
            "sd_cpp_path": default_sd_cpp_path,
            "models_dir": None,
            "output_dir": "outputs"
        }
    if "cors" not in config:
        config["cors"] = {
            "allow_origins": ["*"],
            "allow_methods": ["GET", "POST", "OPTIONS"],
            "allow_headers": ["*"]
        }
    if "rate_limiting" not in config:
        config["rate_limiting"] = {"rate": "60/minute", "enabled": True}
    if "images" not in config:
        config["images"] = {"serve_path": "/images", "cache_control": "max-age=3600"}
    
    # Apply any environment variable overrides
    if "DIFFUGEN_OPENAPI_PORT" in os.environ:
        try:
            config["server"]["port"] = int(os.environ["DIFFUGEN_OPENAPI_PORT"])
        except ValueError:
            print(f"Invalid port in DIFFUGEN_OPENAPI_PORT: {os.environ['DIFFUGEN_OPENAPI_PORT']}")
    
    if "SD_CPP_PATH" in os.environ:
        config["paths"]["sd_cpp_path"] = os.environ["SD_CPP_PATH"]
    
    if "DIFFUGEN_OUTPUT_DIR" in os.environ:
        config["paths"]["output_dir"] = os.environ["DIFFUGEN_OUTPUT_DIR"]
    
    if "DIFFUGEN_CORS_ORIGINS" in os.environ:
        config["cors"]["allow_origins"] = os.environ["DIFFUGEN_CORS_ORIGINS"].split(",")
    
    if "DIFFUGEN_RATE_LIMIT" in os.environ:
        config["rate_limiting"]["rate"] = os.environ["DIFFUGEN_RATE_LIMIT"]
    
    if "CUDA_VISIBLE_DEVICES" in os.environ:
        config["env"]["CUDA_VISIBLE_DEVICES"] = os.environ["CUDA_VISIBLE_DEVICES"]
    
    if "VRAM_USAGE" in os.environ:
        config["hardware"]["vram_usage"] = os.environ["VRAM_USAGE"]
    
    if "GPU_LAYERS" in os.environ:
        try:
            config["hardware"]["gpu_layers"] = int(os.environ["GPU_LAYERS"])
        except ValueError:
            print(f"Invalid GPU_LAYERS value: {os.environ['GPU_LAYERS']}")
    
    # Apply environment variables from config
    if "env" in config:
        for key, value in config["env"].items():
            os.environ[key] = str(value)
            print(f"Set environment variable {key}={value}")
    
    return config

# Load the OpenAPI configuration
config = load_openapi_config()

# Convert paths to Path objects for better cross-platform compatibility
SD_CPP_PATH = Path(config["paths"]["sd_cpp_path"])

# Set default output directory
DEFAULT_OUTPUT_DIR = Path(config["paths"]["output_dir"])

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

# Rate limiting middleware
class RateLimitMiddleware:
    def __init__(
        self,
        app,
        rate_limit: str = "60/minute",
        enabled: bool = True,
        rate_limit_by_key: Optional[Callable] = None,
    ):
        self.app = app
        self.enabled = enabled
        self.rate_limit_by_key = rate_limit_by_key or (lambda request: request.client.host)
        
        # Parse rate limit (format: number/timeunit)
        match = re.match(r"(\d+)/(\w+)", rate_limit)
        if not match:
            raise ValueError(f"Invalid rate limit format: {rate_limit}")
        
        self.max_requests = int(match.group(1))
        timeunit = match.group(2).lower()
        
        # Convert time unit to seconds
        if timeunit == "second":
            self.window_seconds = 1
        elif timeunit == "minute":
            self.window_seconds = 60
        elif timeunit == "hour":
            self.window_seconds = 3600
        elif timeunit == "day":
            self.window_seconds = 86400
        else:
            raise ValueError(f"Invalid time unit: {timeunit}")
        
        # Rate limit storage
        self.requests = defaultdict(list)
    
    async def __call__(self, scope, receive, send):
        if not self.enabled or scope["type"] != "http":
            return await self.app(scope, receive, send)
            
        # Create a request object to get client information
        request = Request(scope=scope, receive=receive)
        # Get the rate limit key (client IP by default)
        key = self.rate_limit_by_key(request)
        
        # Clean up old requests
        now = time.time()
        self.requests[key] = [req_time for req_time in self.requests[key] 
                              if now - req_time < self.window_seconds]
        
        # Check if rate limit is exceeded
        if len(self.requests[key]) >= self.max_requests:
            # Create a response for rate limit exceeded
            headers = [
                (b"content-type", b"application/json"),
                (b"x-rate-limit-limit", str(self.max_requests).encode()),
                (b"x-rate-limit-remaining", b"0"),
                (b"x-rate-limit-reset", str(int(now + self.window_seconds)).encode()),
            ]
            
            response = {
                "error": "Rate limit exceeded",
                "detail": f"Maximum {self.max_requests} requests per {self.window_seconds} seconds",
                "timestamp": datetime.now().isoformat()
            }
            
            await send({
                "type": "http.response.start",
                "status": 429,
                "headers": headers
            })
            await send({
                "type": "http.response.body",
                "body": json.dumps(response).encode()
            })
            return
        
        # Record the request
        self.requests[key].append(now)
        
        # Add rate limit headers to responses
        original_send = send
        
        async def wrapped_send(message):
            if message["type"] == "http.response.start":
                message.setdefault("headers", [])
                message["headers"].append(
                    (b"x-rate-limit-limit", str(self.max_requests).encode())
                )
                message["headers"].append(
                    (b"x-rate-limit-remaining", str(self.max_requests - len(self.requests[key])).encode())
                )
                message["headers"].append(
                    (b"x-rate-limit-reset", str(int(now + self.window_seconds)).encode())
                )
            await original_send(message)
        
        await self.app(scope, receive, wrapped_send)

# Create FastAPI app with middlewares
middlewares = [
    Middleware(
        CORSMiddleware,
        allow_origins=config["cors"]["allow_origins"],
        allow_credentials=True,
        allow_methods=config["cors"]["allow_methods"],
        allow_headers=config["cors"]["allow_headers"],
    )
]

# Add rate limiting middleware if enabled
if config.get("rate_limiting", {}).get("enabled", True):
    middlewares.append(
        Middleware(
            RateLimitMiddleware,
            rate_limit=config.get("rate_limiting", {}).get("rate", "60/minute"),
            enabled=config.get("rate_limiting", {}).get("enabled", True),
        )
    )

app = FastAPI(
    title="DiffuGen",
    description="AI Image Generation API using Stable Diffusion and Flux models",
    version="1.0.0",
    terms_of_service="http://example.com/terms/",
    contact={
        "name": "DiffuGen Support",
        "url": "https://github.com/CLOUDWERX-DEV/diffugen",
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
    ],
    middleware=middlewares
)

# Mount the output directory for serving generated images
app.mount(config["images"]["serve_path"], StaticFiles(directory=str(DEFAULT_OUTPUT_DIR)), name="images")

# API Key security
async def verify_api_key(x_api_key: Optional[str] = Header(None)):
    """Verify the API key if API key security is enabled"""
    # Check if API key security is enabled
    if config.get("security", {}).get("api_key_required", False):
        if not x_api_key:
            raise HTTPException(
                status_code=401,
                detail="API key is required",
                headers={"WWW-Authenticate": "ApiKey"},
            )
        
        # Check if the provided API key is valid
        valid_keys = config.get("security", {}).get("api_keys", [])
        if x_api_key not in valid_keys:
            raise HTTPException(
                status_code=403,
                detail="Invalid API key",
                headers={"WWW-Authenticate": "ApiKey"},
            )
    return x_api_key

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

# Configuration endpoint
@app.get("/config", tags=["System"], response_model=Dict[str, object])
async def get_config():
    """Get the current server configuration (excluding sensitive information)"""
    # Create a sanitized config (remove security info)
    safe_config = config.copy()
    if "security" in safe_config:
        if "api_keys" in safe_config["security"]:
            # Remove actual keys but keep the count
            safe_config["security"] = {
                "api_key_required": safe_config["security"].get("api_key_required", False),
                "api_key_count": len(safe_config["security"].get("api_keys", []))
            }
    return safe_config

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
        for file in chain(DEFAULT_OUTPUT_DIR.glob("*.[jp][pn][g]"), DEFAULT_OUTPUT_DIR.glob("*.jpeg")):
            images.append({
                "filename": file.name,
                "path": f"{config['images']['serve_path']}/{file.name}",
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
async def generate_stable_image(request: ImageGenerationRequest, req: Request, api_key: str = Depends(verify_api_key)):
    """Generate an image using standard Stable Diffusion models (SDXL, SD3, SD15)"""
    try:
        # If no model specified or the request came directly to this endpoint without a model,
        # redirect to flux endpoint to ensure we generate only one image
        if not request.model:
            # Check if this was a direct request to the stable endpoint
            # If so, default to SD15 instead of going to flux endpoint
            # Otherwise, redirect to flux endpoint
            referer = req.headers.get("referer", "")
            user_agent = req.headers.get("user-agent", "")
            
            # If it looks like a direct API call from OpenWebUI tools
            if "openwebui" in user_agent.lower() or "openwebui" in referer.lower():
                request.model = "sd15"  # Default to SD15 for stable endpoint
            else:
                # Otherwise, follow the original behavior of redirecting to flux
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
        image_url = f"{base_url}{config['images']['serve_path']}/{image_path.name}"
        
        # Create markdown-formatted response
        markdown_response = f"Here's the image you requested:\n\n![Image]({image_url})\n\n**Generation Details:**\n- Model: {result['model']}\n- Prompt: {result['prompt']}\n- Resolution: {result['width']}x{result['height']} pixels\n- Steps: {result['steps']}\n- CFG Scale: {result['cfg_scale']}\n- Sampling Method: {result['sampling_method']}\n- Seed: {result['seed'] if result['seed'] != -1 else 'random'}"
            
        return ImageGenerationResponse(
            success=True,
            image_path=str(image_path),
            image_url=image_url,
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
async def generate_flux_image_endpoint(request: ImageGenerationRequest, req: Request, api_key: str = Depends(verify_api_key)):
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
        image_url = f"{base_url}{config['images']['serve_path']}/{image_path.name}"
        
        # Create markdown-formatted response
        markdown_response = f"Here's the image you requested:\n\n![Image]({image_url})\n\n**Generation Details:**\n- Model: {result['model']}\n- Prompt: {result['prompt']}\n- Resolution: {result['width']}x{result['height']} pixels\n- Steps: {result['steps']}\n- CFG Scale: {result['cfg_scale']}\n- Sampling Method: {result['sampling_method']}\n- Seed: {result['seed'] if result['seed'] != -1 else 'random'}"
            
        return ImageGenerationResponse(
            success=True,
            image_path=str(image_path),
            image_url=image_url,
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
    response_model=Dict[str, Dict[str, Union[List[str], Dict]]])
async def list_models():
    """List available models and their default parameters"""
    try:
        # Use models from the OpenAPI config if available, otherwise load from diffugen config
        if "models" in config and config["models"]:
            models = config["models"]
        else:
            diffugen_config = load_diffugen_config()
            models = {
                "flux": ["flux-schnell", "flux-dev"],
                "stable_diffusion": ["sdxl", "sd3", "sd15"]
            }
        
        # Use default parameters from OpenAPI config if available
        if "default_params" in config:
            default_params = config["default_params"]
        else:
            diffugen_config = load_diffugen_config()
            default_params = diffugen_config.get("default_params", {})
        
        return {
            "models": models,
            "default_params": default_params
        }
    except Exception as e:
        print(f"Error in list_models: {e}")
        return {
            "models": {
                "flux": ["flux-schnell", "flux-dev"],
                "stable_diffusion": ["sdxl", "sd3", "sd15"]
            },
            "default_params": {
                "width": 512,
                "height": 512
            }
        }

@app.get("/openapi.json", include_in_schema=False)
async def get_openapi_schema():
    """Get OpenAPI schema with CORS support"""
    return app.openapi()

# Add a new unified endpoint that will become the primary entry point
@app.post("/generate", 
    response_model=ImageGenerationResponse, 
    tags=["Image Generation"],
    summary="Generate Image (Unified Endpoint)",
    description="Unified endpoint that automatically selects the appropriate model type")
async def generate_image(request: ImageGenerationRequest, req: Request, api_key: str = Depends(verify_api_key)):
    """Generate an image using the appropriate model type based on request or config"""
    # Apply default width/height from config if not specified
    if request.width is None and "default_params" in config and "width" in config["default_params"]:
        request.width = config["default_params"]["width"]
    
    if request.height is None and "default_params" in config and "height" in config["default_params"]:
        request.height = config["default_params"]["height"]
    
    # If model is specified, route to appropriate endpoint
    if request.model:
        if request.model.lower().startswith("flux-"):
            return await generate_flux_image_endpoint(request, req)
        else:
            return await generate_stable_image(request, req)
    else:
        # Use default model from config, or fall back to flux-schnell
        default_model = config.get("default_model", "flux-schnell")
        request.model = default_model
        
        if default_model.lower().startswith("flux-"):
            return await generate_flux_image_endpoint(request, req)
        else:
            return await generate_stable_image(request, req)

# Update the main function to use configuration
if __name__ == "__main__":
    import uvicorn
    
    parser = argparse.ArgumentParser(description="DiffuGen OpenAPI Server")
    parser.add_argument("--host", type=str, help="Host to bind the server to")
    parser.add_argument("--port", type=int, help="Port to bind the server to")
    parser.add_argument("--config", type=str, help="Path to custom config file")
    args = parser.parse_args()
    
    # Override config with command line arguments if provided
    host = args.host or config["server"]["host"]
    port = args.port or config["server"]["port"]
    
    # Load custom config file if specified
    if args.config:
        try:
            with open(args.config, 'r') as f:
                custom_config = json.load(f)
                config.update(custom_config)
                print(f"Loaded custom configuration from {args.config}")
        except Exception as e:
            print(f"Error loading custom configuration: {e}")
    
    print(f"Starting DiffuGen OpenAPI server at http://{host}:{port}")
    print(f"Documentation available at http://{host}:{port}/docs")
    print(f"Serving images from {DEFAULT_OUTPUT_DIR} at {host}:{port}{config['images']['serve_path']}")
    
    uvicorn.run(app, host=host, port=port) 