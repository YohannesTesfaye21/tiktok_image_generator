# TikTok Image Generator API Backend

Flask API server for the TikTok Image Generator Flutter app.

## Setup

1. Create a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Make sure the main image generator is accessible:
   - The API expects the `tiktok_image_generator.py` to be in the parent directory
   - Or update the path in `api_server.py`

4. Run the server:
```bash
python api_server.py
```

The server will start on `http://localhost:8000`

## API Endpoints

### POST /api/generate
Generate images from texts and gradient colors.

**Request Body:**
```json
{
  "texts": ["Text 1", "Text 2", "Text 3"],
  "gradient_colors": [
    {"r": 255, "g": 107, "b": 107},
    {"r": 255, "g": 159, "b": 64},
    {"r": 255, "g": 206, "b": 84}
  ]
}
```

**Response:**
```json
{
  "success": true,
  "image_paths": ["/path/to/image1.png", "/path/to/image2.png"],
  "count": 2
}
```

### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "ok"
}
```

