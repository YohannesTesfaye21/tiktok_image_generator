# TikTok Image Generator Flutter App

A Flutter application for generating TikTok-optimized images with custom text and gradient backgrounds.

## Features

- 🎨 **Gradient Color Selection**: Choose from 10+ beautiful gradient presets
- 📝 **Numbered Text Input**: Paste texts with numbers (e.g., "1. text", "2. text")
- 🖼️ **Image Generation**: Generate multiple images at once
- 📱 **TikTok Optimized**: 1080x1920 vertical format
- 💾 **Save to Gallery**: Save generated images directly to your device

## Project Structure

```
tiktok_image_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/
│   │   ├── home_screen.dart      # Main screen with inputs
│   │   └── preview_screen.dart   # Preview and save images
│   ├── widgets/
│   │   ├── gradient_picker.dart  # Gradient color selector
│   │   └── text_input_section.dart # Text input widget
│   ├── models/
│   │   └── gradient_preset.dart  # Gradient color models
│   └── services/
│       └── image_generator_service.dart # API service
├── backend/
│   ├── api_server.py             # Flask API server
│   └── requirements.txt           # Python dependencies
└── pubspec.yaml                   # Flutter dependencies
```

## Setup

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Setup Python Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Start the Backend Server

```bash
cd backend
python api_server.py
```

The server will run on `http://localhost:8000`

### 4. Run Flutter App

```bash
flutter run
```

## Usage

1. **Select Gradient**: Tap on a gradient color preset
2. **Enter Texts**: Paste your texts with numbers like:
   ```
   1. First text
   2. Second text
   3. Third text
   ```
3. **Generate**: Tap "Generate Images" button
4. **Preview & Save**: View generated images and save to gallery

## Notes

- The app requires the Python backend to be running
- Generated images are saved in the `output/` directory
- Images are optimized for TikTok (1080x1920 pixels)

## Development

To modify gradient colors, edit `lib/models/gradient_preset.dart`

To modify API endpoint, edit `lib/services/image_generator_service.dart`
