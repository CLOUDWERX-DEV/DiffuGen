# DiffuGen OpenAPI Configuration Guide

This guide explains how to configure the DiffuGen OpenAPI server using the `openapi_config.json` file.

## Configuration File Location

The OpenAPI server looks for configuration in the following locations:

1. `openapi_config.json` in the DiffuGen root directory
2. Custom config file path specified with `--config` command line option
3. Environment variables for specific settings

## Configuration Structure

The `openapi_config.json` file has the following structure:

```json
{
  "server": {
    "host": "0.0.0.0",
    "port": 5199,
    "debug": false
  },
  "paths": {
    "sd_cpp_path": "stable-diffusion.cpp",
    "models_dir": "stable-diffusion.cpp/models",
    "output_dir": "outputs"
  },
  "hardware": {
    "vram_usage": "adaptive",
    "gpu_layers": -1,
    "cuda_device": "0"
  },
  "env": {
    "CUDA_VISIBLE_DEVICES": "0"
  },
  "cors": {
    "allow_origins": ["*"],
    "allow_methods": ["GET", "POST", "OPTIONS"],
    "allow_headers": ["*"]
  },
  "rate_limiting": {
    "rate": "60/minute",
    "enabled": true
  },
  "models": {
    "flux": ["flux-schnell", "flux-dev"],
    "stable_diffusion": ["sdxl", "sd3", "sd15"]
  },
  "default_model": "flux-schnell",
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
    "sampling_method": {
      "flux-schnell": "euler",
      "flux-dev": "euler",
      "sdxl": "euler",
      "sd3": "euler",
      "sd15": "euler"
    }
  },
  "images": {
    "serve_path": "/images",
    "cache_control": "max-age=3600"
  },
  "security": {
    "api_key_required": false,
    "api_keys": []
  }
}
```

## Configuration Sections

### Server Configuration

```json
"server": {
  "host": "0.0.0.0",
  "port": 5199,
  "debug": false
}
```

- `host`: The IP address the server will bind to (default: `"0.0.0.0"` to listen on all interfaces)
- `port`: The port the server will listen on (default: `5199`)
- `debug`: Whether to run in debug mode (default: `false`)

### Path Configuration

```json
"paths": {
  "sd_cpp_path": "stable-diffusion.cpp",
  "models_dir": "stable-diffusion.cpp/models",
  "output_dir": "outputs"
}
```

- `sd_cpp_path`: Path to the stable-diffusion.cpp directory
- `models_dir`: Path to the directory containing model files (if not set, defaults to `{sd_cpp_path}/models`)
- `output_dir`: Directory where generated images will be saved

### Hardware Configuration

```json
"hardware": {
  "vram_usage": "adaptive",
  "gpu_layers": -1,
  "cuda_device": "0"
}
```

- `vram_usage`: VRAM usage strategy (options: `"adaptive"`, `"minimal"`, `"balanced"`, `"maximum"`)
- `gpu_layers`: Number of layers to offload to GPU (-1 for auto-detect)
- `cuda_device`: CUDA device to use for generation

### Environment Variables

```json
"env": {
  "CUDA_VISIBLE_DEVICES": "0"
}
```

- `CUDA_VISIBLE_DEVICES`: Controls which GPUs are visible to the application
  - `"0"`: Use only the first GPU
  - `"1"`: Use only the second GPU
  - `"0,1"`: Use both first and second GPUs
  - `"-1"`: Disable CUDA and use CPU only

### CORS Configuration

```json
"cors": {
  "allow_origins": ["*"],
  "allow_methods": ["GET", "POST", "OPTIONS"],
  "allow_headers": ["*"]
}
```

- `allow_origins`: List of allowed origins (default: `["*"]` to allow all origins)
- `allow_methods`: List of allowed HTTP methods (default: `["GET", "POST", "OPTIONS"]`)
- `allow_headers`: List of allowed HTTP headers (default: `["*"]` to allow all headers)

### Rate Limiting

```json
"rate_limiting": {
  "rate": "60/minute",
  "enabled": true
}
```

- `rate`: Maximum request rate in format `number/timeunit` (default: `"60/minute"`)
- `enabled`: Whether rate limiting is enabled (default: `true`)

### Models Configuration

```json
"models": {
  "flux": ["flux-schnell", "flux-dev"],
  "stable_diffusion": ["sdxl", "sd3", "sd15"]
}
```

- `flux`: List of available Flux models
- `stable_diffusion`: List of available Stable Diffusion models

### Default Model

```json
"default_model": "flux-schnell"
```

- Specifies which model to use when no model is explicitly requested

### Default Parameters

```json
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
  "sampling_method": {
    "flux-schnell": "euler",
    "flux-dev": "euler",
    "sdxl": "euler",
    "sd3": "euler",
    "sd15": "euler"
  }
}
```

This section defines default parameters for generation:
- `width`: Default image width in pixels
- `height`: Default image height in pixels
- `steps`: Default number of diffusion steps for each model
- `cfg_scale`: Default classifier-free guidance scale for each model
- `sampling_method`: Default sampling method for each model

### Images Configuration

```json
"images": {
  "serve_path": "/images",
  "cache_control": "max-age=3600"
}
```

- `serve_path`: URL path where images will be served (default: `"/images"`)
- `cache_control`: Cache-Control header for served images (default: `"max-age=3600"`)

### Security Configuration

```json
"security": {
  "api_key_required": false,
  "api_keys": []
}
```

- `api_key_required`: Whether API key authentication is required (default: `false`)
- `api_keys`: List of valid API keys for authentication (default: `[]`)

## Environment Variable Overrides

You can override configuration settings with environment variables:

- `DIFFUGEN_OPENAPI_PORT`: Override the server port
- `SD_CPP_PATH`: Path to the stable-diffusion.cpp directory
- `DIFFUGEN_OUTPUT_DIR`: Directory where generated images will be saved
- `DIFFUGEN_CORS_ORIGINS`: Comma-separated list of allowed origins
- `DIFFUGEN_RATE_LIMIT`: Rate limit in format `number/timeunit`
- `CUDA_VISIBLE_DEVICES`: Control which GPUs are used
- `VRAM_USAGE`: VRAM usage strategy
- `GPU_LAYERS`: Number of layers to offload to GPU

## Command Line Options

You can also specify some configuration options via command line:

```bash
python diffugen_openapi.py --host 127.0.0.1 --port 8080 --config custom_config.json
```

- `--host`: Host address to bind to
- `--port`: Port to listen on
- `--config`: Path to a custom configuration file

## Examples

### Basic Configuration

```json
{
  "server": {
    "host": "127.0.0.1",
    "port": 8080
  },
  "paths": {
    "output_dir": "/var/diffugen/images"
  },
  "default_model": "flux-schnell"
}
```

### High-Performance Configuration

```json
{
  "hardware": {
    "vram_usage": "maximum",
    "gpu_layers": -1,
    "cuda_device": "0"
  },
  "env": {
    "CUDA_VISIBLE_DEVICES": "0,1"
  },
  "default_params": {
    "steps": {
      "flux-schnell": 12,
      "sdxl": 30
    }
  }
}
```

### Production Configuration with Security

```json
{
  "server": {
    "host": "0.0.0.0",
    "port": 5199,
    "debug": false
  },
  "cors": {
    "allow_origins": ["https://example.com", "https://api.example.com"],
    "allow_methods": ["GET", "POST"]
  },
  "rate_limiting": {
    "rate": "30/minute",
    "enabled": true
  },
  "security": {
    "api_key_required": true,
    "api_keys": ["your-secret-api-key-1", "your-secret-api-key-2"]
  }
}
```

### Custom Model Configuration

```json
{
  "models": {
    "flux": ["flux-schnell"],
    "stable_diffusion": ["sdxl"]
  },
  "default_model": "sdxl",
  "default_params": {
    "width": 1024,
    "height": 1024,
    "steps": {
      "flux-schnell": 12,
      "sdxl": 30
    },
    "cfg_scale": {
      "flux-schnell": 1.2,
      "sdxl": 8.0
    },
    "sampling_method": {
      "flux-schnell": "euler",
      "sdxl": "dpm++2m"
    }
  }
}
``` 