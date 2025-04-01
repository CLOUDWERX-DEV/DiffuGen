# DiffuGen OpenAPI Integration Guide

This guide provides detailed instructions for setting up and using DiffuGen's OpenAPI server capabilities, enabling integration with OpenWebUI and other OpenAPI-compatible tools.

## Prerequisites

- Python 3.11 or newer
- NVIDIA GPU with CUDA support (recommended)
- DiffuGen base installation completed

## Installation

1. Install DiffuGen and its dependencies:
```bash
git clone https://github.com/CLOUDWERX-DEV/diffugen.git
cd diffugen
chmod +x setup_diffugen.sh
./setup_diffugen.sh
```

2. Start the OpenAPI server:
```bash
python diffugen_openapi.py --port 5199
```

The server will be available at http://0.0.0.0:5199 with interactive documentation at http://0.0.0.0:5199/docs

## OpenWebUI Integration

1. Open OpenWebUI Settings (gear icon)
2. Navigate to the "Tools" section
3. Click the "+" button to add a new tool server
4. Enter the following details:
   - URL: http://0.0.0.0:5199
   - API Key: (leave empty)
5. Click "Save"

Once added, DiffuGen will appear in the available tools list when clicking the tools icon in the chat interface. The following endpoints will be available:
- `generate_stable_image_generate_stable_post`: Generate with Stable Diffusion
- `generate_flux_image_endpoint_generate_flux_post`: Generate with Flux Models
- `list_models_models_get`: List Available Models

## API Endpoints Reference

### 1. Generate Image with Stable Diffusion Models

```http
POST /generate/stable
```

Request body:
```json
{
  "prompt": "A beautiful sunset over mountains",
  "model": "sdxl",
  "width": 1024,
  "height": 768,
  "steps": 30,
  "cfg_scale": 7.0,
  "seed": -1,
  "sampling_method": "dpm++2m",
  "negative_prompt": "blurry, low quality"
}
```

Response:
```json
{
  "file_path": "path/to/generated/image.png",
  "metadata": {
    "model": "sdxl",
    "prompt": "A beautiful sunset over mountains",
    "generation_time": "1.23s",
    "parameters": {
      // Generation parameters used
    }
  }
}
```

### 2. Generate Image with Flux Models

```http
POST /generate/flux
```

Request body:
```json
{
  "prompt": "A cyberpunk cityscape",
  "model": "flux-schnell",
  "width": 512,
  "height": 512,
  "steps": 8,
  "cfg_scale": 1.0,
  "seed": -1,
  "sampling_method": "euler"
}
```

Response: Same structure as Stable Diffusion endpoint

### 3. List Available Models

```http
GET /models
```

Response:
```json
{
  "models": {
    "flux": ["flux-schnell", "flux-dev"],
    "stable_diffusion": ["sdxl", "sd3", "sd15"],
    "default_parameters": {
      // Model-specific default parameters
    }
  }
}
```

## Advanced Configuration

### Server Configuration

The OpenAPI server can be configured to use a different host or port if needed. By default, it runs on:
- Host: 0.0.0.0
- Port: 8080

### Output Directory Configuration

The server uses the following directory configuration:
- Default output directory: `/output`
- Environment variable: `DIFFUGEN_OUTPUT_DIR`
- Fallback: Creates an `output` directory in the current working directory if the specified directory is not accessible

Generated images are saved to this directory and served through the `/images` endpoint. The full URL for accessing generated images will be: `http://your-server:port/images/filename.png`

### CORS Configuration

By default, CORS is enabled for OpenWebUI integration. You can configure CORS settings:

```python
# In your environment or configuration
DIFFUGEN_CORS_ORIGINS="http://localhost:3000,http://localhost:8080"
DIFFUGEN_CORS_METHODS="GET,POST"
```

### Rate Limiting

The server includes basic rate limiting to prevent abuse:
- Default: 60 requests per minute per IP
- Configurable through environment variables:
```bash
export DIFFUGEN_RATE_LIMIT="120/minute"
```

## Model-Specific Recommendations

### Flux Models
- **flux-schnell**: Best for rapid prototyping
  - Default steps: 8
  - Default cfg_scale: 1.0
  - Sampling method: euler
  - Best for: Quick iterations, concept testing

- **flux-dev**: Better quality, slower generation
  - Default steps: 20
  - Default cfg_scale: 1.0
  - Sampling method: euler
  - Best for: Higher quality generations

### Stable Diffusion Models
- **sdxl**: Highest quality, largest model
  - Default steps: 20-30
  - Default cfg_scale: 7.0
  - Sampling method: dpm++2m
  - Best for: Professional quality images

- **sd3**: Good balance of quality and speed
  - Default steps: 20
  - Default cfg_scale: 7.0
  - Sampling method: euler_a
  - Best for: General purpose generation

- **sd15**: Classic model, reliable results
  - Default steps: 20
  - Default cfg_scale: 7.0
  - Sampling method: euler_a
  - Best for: Consistent, well-understood results

## Error Handling

The API uses standard HTTP status codes:
- 200: Successful generation
- 400: Invalid request parameters
- 404: Model not found
- 500: Server error

Error responses include detailed messages:
```json
{
  "error": "Invalid parameters",
  "detail": "Width must be between 256 and 2048",
  "code": "INVALID_DIMENSIONS"
}
```

## Troubleshooting

1. **Server won't start**
   - Check if required models are downloaded
   - Verify CUDA installation if using GPU
   - Check port 5199 is available
   - Verify Python environment is activated

2. **Generation fails**
   - Check model paths in configuration
   - Verify GPU memory availability
   - Try reducing image dimensions or steps
   - Check server logs for detailed error messages

3. **Poor image quality**
   - Increase steps (20-30 for better quality)
   - Adjust cfg_scale (7.0-9.0 for SD models)
   - Use more detailed prompts
   - Try different sampling methods

4. **OpenWebUI Integration Issues**
   - Verify server is running and accessible
   - Check CORS settings if using a different domain
   - Ensure URL is correctly formatted in tool settings
   - Check browser console for error messages

## Support

For issues and questions:
- GitHub Issues: [CLOUDWERX-DEV/diffugen](https://github.com/CLOUDWERX-DEV/diffugen/issues)
- Discord: [Join our server](https://discord.gg/SvZFuufNTQ)
- Email: sysop@cloudwerx.dev 