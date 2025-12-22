# Backend API - Quick Start

## Status: ✅ Ready to Run

The backend is fully configured and ready to start.

## Start the Server

### Option 1: Using the script (Easiest)
```bash
cd /Users/m2pro/Desktop/tiktok/tiktok_image_app/backend
./start_server.sh
```

### Option 2: Manual start
```bash
cd /Users/m2pro/Desktop/tiktok/tiktok_image_app/backend
source venv/bin/activate
python3 api_server.py
```

You should see:
```
✓ Found image generator at: /Users/m2pro/Desktop/tiktok/tiktok_photo_editor
✓ Successfully imported TikTokImageGenerator
Starting TikTok Image Generator API server...
Server will be available at http://localhost:8000
 * Running on http://0.0.0.0:8000
```

## Test the API

### Health Check
```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{"status":"ok"}
```

### Generate Images (Example)
```bash
curl -X POST http://localhost:8000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "texts": ["Test 1", "Test 2"],
    "gradient_colors": [
      {"r": 255, "g": 107, "b": 107},
      {"r": 255, "g": 159, "b": 64}
    ]
  }'
```

## API Endpoints

### POST /api/generate
Generate images from texts and gradient colors.

**Request:**
```json
{
  "texts": ["Text 1", "Text 2"],
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
  "image_paths": ["/absolute/path/to/image1.png", "/absolute/path/to/image2.png"],
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

## Troubleshooting

### Port 8000 already in use?
```bash
lsof -i :8000  # Find what's using the port
kill -9 <PID>  # Kill the process
```

### Import errors?
- Make sure tiktok_photo_editor is at: `/Users/m2pro/Desktop/tiktok/tiktok_photo_editor`
- Check that tiktok_image_generator.py exists there

### Dependencies not found?
```bash
source venv/bin/activate
pip install -r requirements.txt
```

