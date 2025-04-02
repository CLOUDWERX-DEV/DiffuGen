from fastapi import FastAPI, HTTPException, Request, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware import Middleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Union, Callable, Any
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
import gc
import uuid

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
            config["server"]["port"] = int(os.environ.get("DIFFUGEN_OPENAPI_PORT", config["server"]["port"]))
        except ValueError:
            print(f"Invalid port in DIFFUGEN_OPENAPI_PORT: {os.environ.get('DIFFUGEN_OPENAPI_PORT')}")
    
    if "SD_CPP_PATH" in os.environ:
        config["paths"]["sd_cpp_path"] = os.environ.get("SD_CPP_PATH", config["paths"]["sd_cpp_path"])
    
    if "DIFFUGEN_OUTPUT_DIR" in os.environ:
        config["paths"]["output_dir"] = os.environ.get("DIFFUGEN_OUTPUT_DIR", config["paths"]["output_dir"])
    
    if "DIFFUGEN_CORS_ORIGINS" in os.environ:
        config["cors"]["allow_origins"] = os.environ.get("DIFFUGEN_CORS_ORIGINS", "").split(",")
    
    if "DIFFUGEN_RATE_LIMIT" in os.environ:
        config["rate_limiting"]["rate"] = os.environ.get("DIFFUGEN_RATE_LIMIT", config["rate_limiting"]["rate"])
    
    if "CUDA_VISIBLE_DEVICES" in os.environ:
        if "env" not in config:
            config["env"] = {}
        config["env"]["CUDA_VISIBLE_DEVICES"] = os.environ.get("CUDA_VISIBLE_DEVICES", "")
    
    if "VRAM_USAGE" in os.environ:
        if "hardware" not in config:
            config["hardware"] = {}
        config["hardware"]["vram_usage"] = os.environ.get("VRAM_USAGE", "")
    
    if "GPU_LAYERS" in os.environ:
        if "hardware" not in config:
            config["hardware"] = {}
        try:
            config["hardware"]["gpu_layers"] = int(os.environ.get("GPU_LAYERS", 0))
        except ValueError:
            print(f"Invalid GPU_LAYERS value: {os.environ.get('GPU_LAYERS')}")
    
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
        
        # Rate limit storage - use filesystem-based approach for better multi-process support
        self.cache_dir = Path(os.path.join(os.getcwd(), ".rate_limit_cache"))
        try:
            os.makedirs(self.cache_dir, exist_ok=True)
        except Exception as e:
            print(f"Warning: Could not create rate limit cache directory: {e}")
            print("Rate limiting will use in-memory storage and may not work correctly in multi-process deployments")
            # Fallback to in-memory storage
            self.requests = defaultdict(list)
            self.use_filesystem = False
        else:
            self.use_filesystem = True
    
    def _get_cache_path(self, key):
        """Get filesystem path for a rate limit key"""
        # Create a safe filename from the key
        safe_key = re.sub(r'[^\w]', '_', str(key))
        return self.cache_dir / f"{safe_key}.json"
    
    def _read_requests(self, key):
        """Read requests from filesystem for a key"""
        if not self.use_filesystem:
            return self.requests[key]
            
        cache_path = self._get_cache_path(key)
        try:
            if cache_path.exists():
                with open(cache_path, 'r') as f:
                    return json.load(f)
            return []
        except Exception as e:
            print(f"Error reading rate limit cache: {e}")
            return []
    
    def _write_requests(self, key, requests):
        """Write requests to filesystem for a key"""
        if not self.use_filesystem:
            self.requests[key] = requests
            return
            
        cache_path = self._get_cache_path(key)
        try:
            with open(cache_path, 'w') as f:
                json.dump(requests, f)
        except Exception as e:
            print(f"Error writing rate limit cache: {e}")
    
    def _clean_old_requests(self, key):
        """Clean up old requests for a key"""
        now = time.time()
        requests = self._read_requests(key)
        updated_requests = [req_time for req_time in requests 
                           if now - req_time < self.window_seconds]
        
        if len(updated_requests) != len(requests):
            self._write_requests(key, updated_requests)
        
        return updated_requests
    
    async def __call__(self, scope, receive, send):
        if not self.enabled or scope["type"] != "http":
            return await self.app(scope, receive, send)
            
        # Create a request object to get client information
        request = Request(scope=scope, receive=receive)
        # Get the rate limit key (client IP by default)
        key = self.rate_limit_by_key(request)
        
        # Clean up old requests and get current ones
        requests = self._clean_old_requests(key)
        
        # Check if rate limit is exceeded
        if len(requests) >= self.max_requests:
            # Create a response for rate limit exceeded
            headers = [
                (b"content-type", b"application/json"),
                (b"x-rate-limit-limit", str(self.max_requests).encode()),
                (b"x-rate-limit-remaining", b"0"),
                (b"x-rate-limit-reset", str(int(time.time() + self.window_seconds)).encode()),
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
        now = time.time()
        requests.append(now)
        self._write_requests(key, requests)
        
        # Add rate limit headers to responses
        original_send = send
        
        async def wrapped_send(message):
            if message["type"] == "http.response.start":
                message.setdefault("headers", [])
                message["headers"].append(
                    (b"x-rate-limit-limit", str(self.max_requests).encode())
                )
                message["headers"].append(
                    (b"x-rate-limit-remaining", str(max(0, self.max_requests - len(requests))).encode())
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

# Mount the output directory for serving generated images with proper cache control
print(f"Mounting static files from {DEFAULT_OUTPUT_DIR.absolute()} at {config['images']['serve_path']}")
app.mount(
    config["images"]["serve_path"], 
    StaticFiles(
        directory=str(DEFAULT_OUTPUT_DIR.absolute()), 
        check_dir=True,
        html=False
    ), 
    name="images"
)

# Add middleware to set cache control headers
@app.middleware("http")
async def add_cache_control(request: Request, call_next):
    response = await call_next(request)
    
    # Add cache control headers for image responses
    if request.url.path.startswith(config["images"]["serve_path"]):
        # Set strict no-cache headers for images to prevent browser caching
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
        print(f"Added no-cache headers for: {request.url.path}")
    
    return response

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
        # Log current paths for debugging
        print(f"Looking for images in: {DEFAULT_OUTPUT_DIR} (absolute: {DEFAULT_OUTPUT_DIR.absolute()})")
        print(f"Images path in server config: {config['images']['serve_path']}")
        
        # Use os.path.exists to verify directory accessibility
        if not os.path.exists(DEFAULT_OUTPUT_DIR):
            print(f"WARNING: Output directory does not exist or is not accessible: {DEFAULT_OUTPUT_DIR}")
            os.makedirs(DEFAULT_OUTPUT_DIR, exist_ok=True)
            print(f"Created output directory: {DEFAULT_OUTPUT_DIR}")
        
        # List all files in the directory to debug
        existing_files = list(os.listdir(DEFAULT_OUTPUT_DIR))
        print(f"Files in output directory: {existing_files}")
        
        for file in chain(DEFAULT_OUTPUT_DIR.glob("*.[jp][pn][g]"), DEFAULT_OUTPUT_DIR.glob("*.jpeg")):
            # Add extra verification that file really exists and is accessible
            if not os.path.exists(file) or not os.access(str(file), os.R_OK):
                print(f"WARNING: File listed but not accessible: {file}")
                continue
                
            # Get absolute paths to ensure we're referencing the correct file
            abs_path = os.path.abspath(file)
            rel_path = f"{config['images']['serve_path']}/{file.name}"
            
            print(f"Found image: {file.name} at {abs_path}, serving at {rel_path}")
            
            images.append({
                "filename": file.name,
                "path": rel_path,
                "created": datetime.fromtimestamp(file.stat().st_ctime).isoformat()
            })
        
        print(f"Total images found: {len(images)}")
        return {"images": images}
    except Exception as e:
        print(f"ERROR in list_images: {str(e)}")
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
    """Response for image generation"""
    success: bool
    error: Optional[str] = None
    image_path: Optional[str] = None
    image_url: Optional[str] = None  # Default to None to prevent client from trying to load an image when generation fails
    markdown_response: str
    model: Optional[str] = None
    prompt: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None

# Add resource cleanup helper function
def cleanup_resources():
    """Basic cleanup to prevent hanging on subsequent requests (works on all platforms)"""
    # Force garbage collection to clean up memory resources
    gc.collect()
    
    # Verify the output directory exists and is accessible
    try:
        if not os.path.exists(DEFAULT_OUTPUT_DIR):
            os.makedirs(DEFAULT_OUTPUT_DIR, exist_ok=True)
            print(f"Recreated output directory at {DEFAULT_OUTPUT_DIR}")
    except Exception as e:
        print(f"Error verifying output directory: {e}")
    
    # Very brief pause to allow file handles to be released
    # Keep this minimal to not impact user experience
    time.sleep(0.05)

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
        
        # Validate model name before proceeding (prevent typos)
        valid_models = ["sd15", "sdxl", "sd3"]
        if request.model.lower() not in valid_models:
            error_msg = f"Model {request.model} is not a valid Stable Diffusion model. Supported models are: {', '.join(valid_models)}"
            print(f"Invalid model specified: {request.model}")
            # Raise an HTTPException with 400 Bad Request
            raise HTTPException(
                status_code=400,
                detail=error_msg
            )
        
        # Force a random seed when the request appears to be a "make another" type request
        # Look for patterns in the referer or request path that indicate this is a follow-up request
        referer = req.headers.get("referer", "")
        if "generate" in referer or req.url.path.endswith("/stable"):
            # This looks like a follow-up request, force new random seed
            request.seed = -1
            
        # Ensure resources are cleaned up before generating a new image    
        cleanup_resources()
        
        abs_output_dir = os.path.abspath(str(DEFAULT_OUTPUT_DIR))
        print(f"Using absolute output directory: {abs_output_dir}")
        print(f"Output directory exists: {os.path.exists(abs_output_dir)}")
            
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
            output_dir=abs_output_dir
        )
        
        if not result.get("success", False):
            error_msg = result.get("error", "Unknown error")
            print(f"Image generation failed: {error_msg}")
            # Raise an HTTPException with 400 Bad Request
            raise HTTPException(
                status_code=400,
                detail=error_msg
            )
            
        # Create full image URL including host
        image_path = Path(result["image_path"])
        
        # Print path information for debugging
        print(f"Image path from generator: {image_path}")
        print(f"Image path exists: {os.path.exists(image_path)}")
        print(f"Image path size: {os.path.getsize(image_path) if os.path.exists(image_path) else 'N/A'}")
        print(f"Image file name: {image_path.name}")
        
        # Stricter verification that the image file exists and is readable
        # Wait a moment to ensure file operations are complete
        # This helps fix the issue where the image is reported as created but not yet fully written
        max_retries = 5
        retry_delay = 0.5
        for attempt in range(max_retries):
            if os.path.exists(image_path) and os.access(str(image_path), os.R_OK) and os.path.getsize(image_path) > 0:
                break
            print(f"Waiting for image file to be available (attempt {attempt+1}/{max_retries}): {image_path}")
            time.sleep(retry_delay)
        
        # Final verification check
        if not (os.path.exists(image_path) and os.access(str(image_path), os.R_OK) and os.path.getsize(image_path) > 0):
            error_msg = f"Generated image file not found or not readable at path: {image_path}"
            print(f"ERROR: {error_msg}")
            
            # List files in output directory to see what's actually there
            print(f"Files in output directory: {os.listdir(DEFAULT_OUTPUT_DIR)}")
            
            # Raise an HTTPException with 500 Internal Server Error
            raise HTTPException(
                status_code=500,
                detail=error_msg
            )
            
        # Add timestamp to prevent caching
        timestamp = int(time.time())
        base_url = str(req.base_url).rstrip('/')
        file_name = os.path.basename(image_path)
        image_url = f"{base_url}{config['images']['serve_path']}/{file_name}?t={timestamp}"
        
        print(f"Constructed image URL with timestamp: {image_url}")
        
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
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        error_msg = str(e)
        print(f"Unexpected error in generate_stable_image: {error_msg}")
        # Raise an HTTPException with 500 Internal Server Error
        raise HTTPException(
            status_code=500,
            detail=error_msg
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
            
        # Validate model name before proceeding
        if request.model.lower() not in ["flux-schnell", "flux-dev"]:
            error_msg = f"Model {request.model} is not a valid Flux model. Only flux-schnell and flux-dev are supported."
            print(f"Invalid model specified: {request.model}")
            # Raise an HTTPException with 400 Bad Request instead of returning a 200 OK
            raise HTTPException(
                status_code=400,
                detail=error_msg
            )
            
        # Force a random seed when the request appears to be a "make another" type request
        # Look for patterns in the referer or request path that indicate this is a follow-up request
        referer = req.headers.get("referer", "")
        if "generate" in referer or req.url.path.endswith("/flux"):
            # This looks like a follow-up request, force new random seed
            request.seed = -1
            
        # Ensure resources are cleaned up before generating a new image
        cleanup_resources()
        
        # Log the directory structure to debug path issues
        abs_output_dir = os.path.abspath(str(DEFAULT_OUTPUT_DIR))
        print(f"Using absolute output directory: {abs_output_dir}")
        print(f"Output directory exists: {os.path.exists(abs_output_dir)}")
            
        result = generate_flux_image(
            prompt=request.prompt,
            model=request.model,
            width=request.width,
            height=request.height,
            steps=request.steps,
            cfg_scale=request.cfg_scale,
            seed=request.seed,
            sampling_method=request.sampling_method,
            output_dir=abs_output_dir
        )
        
        if not result.get("success", False):
            error_msg = result.get("error", "Unknown error")
            print(f"Image generation failed: {error_msg}")
            # Raise an HTTPException with 400 Bad Request instead of returning a 200 OK
            raise HTTPException(
                status_code=400,
                detail=error_msg
            )
            
        # Get the image path from the result and ensure it's an absolute path
        if "image_path" not in result:
            print("ERROR: image_path missing from result")
            # Raise an HTTPException with 500 Internal Server Error
            raise HTTPException(
                status_code=500,
                detail="Image generation response missing image path"
            )
            
        # Create full image URL including host
        image_path = Path(result["image_path"])
        
        # Print path information for debugging
        print(f"Image path from generator: {image_path}")
        print(f"Image path exists: {os.path.exists(image_path)}")
        print(f"Image path size: {os.path.getsize(image_path) if os.path.exists(image_path) else 'N/A'}")
        print(f"Image file name: {image_path.name}")
        
        # Stricter verification that the image file exists and is readable
        # Wait a moment to ensure file operations are complete
        # This helps fix the issue where the image is reported as created but not yet fully written
        max_retries = 5  # Increase retry attempts
        retry_delay = 0.5
        for attempt in range(max_retries):
            if os.path.exists(image_path) and os.access(str(image_path), os.R_OK) and os.path.getsize(image_path) > 0:
                break
            print(f"Waiting for image file to be available (attempt {attempt+1}/{max_retries}): {image_path}")
            time.sleep(retry_delay)
        
        # Final verification check
        if not (os.path.exists(image_path) and os.access(str(image_path), os.R_OK) and os.path.getsize(image_path) > 0):
            error_msg = f"Generated image file not found or not readable at path: {image_path}"
            print(f"ERROR: {error_msg}")
            
            # List files in output directory to see what's actually there
            print(f"Files in output directory: {os.listdir(DEFAULT_OUTPUT_DIR)}")
            
            # Raise an HTTPException with 500 Internal Server Error
            raise HTTPException(
                status_code=500,
                detail=error_msg
            )
            
        # Ensure we're calculating the relative URL path correctly
        # Get just the filename and construct the URL path with a timestamp to prevent caching
        timestamp = int(time.time())
        base_url = str(req.base_url).rstrip('/')
        file_name = os.path.basename(image_path)
        image_url = f"{base_url}{config['images']['serve_path']}/{file_name}?t={timestamp}"
        
        print(f"Constructed image URL with timestamp: {image_url}")
        
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
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        error_msg = str(e)
        print(f"Unexpected error in generate_flux_image_endpoint: {error_msg}")
        # Raise an HTTPException with 500 Internal Server Error
        raise HTTPException(
            status_code=500,
            detail=error_msg
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
    
    # Force a random seed for all requests to this unified endpoint
    # This ensures "make another" requests always generate different images
    request.seed = -1
    
    # Add a distinct client ID in the request headers to prevent client-side caching
    # This works with the timestamp approach to ensure unique URLs for each request
    client_id = str(uuid.uuid4())
    req.headers.__dict__["_list"].append(
        (b"x-diffugen-client-id", client_id.encode())
    )
    print(f"Added unique client ID to request: {client_id}")
    
    # Ensure resources are cleaned up before generating a new image
    cleanup_resources()
    
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