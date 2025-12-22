# TikTok Image Generator

A Python-based image generator for creating attractive TikTok-style images with text content, featuring dynamic gradient backgrounds and Unicode/Amharic text support.

## Features

- 🎨 Dynamic gradient backgrounds with customizable colors
- 📝 Text rendering with support for numbered lists and multi-line text
- 🌍 Unicode/Amharic text support with automatic font detection
- 📱 TikTok-optimized dimensions (1080x1920)
- 🎯 Batch image generation
- 🔄 Real-time gradient customization per image
- 📱 Flutter mobile app for easy image generation

## Project Structure

```
tiktok/
├── tiktok_photo_editor/          # Python image generator
│   ├── tiktok_image_generator.py # Main generator script
│   └── requirements.txt          # Python dependencies
├── tiktok_image_app/             # Flutter mobile app
│   ├── lib/                      # Flutter source code
│   └── backend/                   # Flask API server
└── README.md                      # This file
```

## Quick Start

### Python Backend

1. Navigate to the Python project:
```bash
cd tiktok_photo_editor
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the generator:
```bash
python tiktok_image_generator.py
```

### Flutter App

1. Navigate to the Flutter app:
```bash
cd tiktok_image_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Start the backend API server:
```bash
cd backend
python api_server.py
```

4. Run the Flutter app:
```bash
flutter run
```

## Usage

### Python Generator

The generator supports interactive mode where you can input text with numbered items:

```
1. First text item
2. Second text item
3. Third text item
```

Each numbered item will generate a separate image.

### Flutter App

1. Enter your text (supports numbered lists)
2. Select gradient colors using the spectrum color picker
3. Choose gradient direction (Vertical/Horizontal/Diagonal)
4. Generate images
5. Customize each image's gradient independently in preview
6. Save images to gallery

## Technologies

- **Python**: Pillow, NumPy
- **Flutter**: Mobile UI framework
- **Flask**: Backend API server
- **Font Support**: Noto Sans Ethiopic for Amharic text

## License

MIT License

