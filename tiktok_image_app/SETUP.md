# Complete Setup Guide

## Overview

This Flutter app generates TikTok images with:
- **Custom gradient backgrounds** (10+ presets to choose from)
- **Numbered text input** (paste texts like "1. text", "2. text")
- **Multiple image generation** (one image per text)
- **Save to gallery** functionality

## Architecture

```
Flutter App (Frontend)
    ↓ HTTP Request
Flask API Server (Backend)
    ↓
Python Image Generator
    ↓
Generated Images (1080x1920)
```

## Step-by-Step Setup

### 1. Flutter App Setup

```bash
cd /Users/m2pro/Desktop/tiktok/tiktok_image_app
flutter pub get
```

### 2. Python Backend Setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Link Image Generator

The backend needs access to the image generator. Make sure the path is correct:

```bash
# The backend expects tiktok_photo_editor at:
# /Users/m2pro/Desktop/tiktok/tiktok_photo_editor

# Or update the path in backend/api_server.py
```

### 4. Start Backend Server

```bash
cd backend
source venv/bin/activate
python api_server.py
```

You should see:
```
Starting TikTok Image Generator API server...
Server will be available at http://localhost:8000
 * Running on http://0.0.0.0:8000
```

### 5. Run Flutter App

In a new terminal:

```bash
cd /Users/m2pro/Desktop/tiktok/tiktok_image_app
flutter run
```

## How to Use

1. **Select Gradient**: Tap on one of the gradient color boxes
2. **Enter Text**: Paste your numbered texts:
   ```
   1. ክርስቶስ ሆይ 
   ምን አይነት ልጅህ ነኝ
   
   2. የምወድህን ያክል አልወድህም
   ```
3. **Generate**: Tap "Generate Images" button
4. **Preview**: View all generated images
5. **Save**: Tap "Save to Gallery" on each image

## Troubleshooting

### Backend not connecting?
- Make sure backend is running on port 8000
- Check firewall settings
- For iOS simulator, use `localhost`
- For Android emulator, use `10.0.2.2` instead of `localhost`

### Images not generating?
- Check backend logs for errors
- Verify tiktok_image_generator.py is accessible
- Check that output directory exists

### Font issues?
- The backend automatically downloads Noto Sans Ethiopic for Amharic
- Check ~/.tiktok_fonts/ directory

## Project Structure

```
tiktok_image_app/
├── lib/
│   ├── main.dart
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable widgets
│   ├── models/           # Data models
│   └── services/         # API services
├── backend/
│   ├── api_server.py     # Flask API
│   └── requirements.txt
└── pubspec.yaml
```

## Next Steps

- Add more gradient presets
- Add custom color picker
- Add text styling options
- Add image filters/effects
- Add batch export

