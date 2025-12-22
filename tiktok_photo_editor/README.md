# TikTok Image Generator

A Python tool to generate attractive, dynamic images with text content optimized for TikTok.

## Features

- 🎨 **Dynamic Design**: Each image gets a unique gradient background with decorative elements
- 📱 **TikTok Optimized**: Generates images in 1080x1920 (vertical) format perfect for TikTok
- 📝 **Batch Processing**: Generate multiple images from a list of texts
- 🎯 **Smart Text Wrapping**: Automatically wraps long text to fit the image
- 🌈 **Vibrant Colors**: Uses multiple color palettes for variety
- 🔢 **Numbered Text Parsing**: Automatically parses numbered lists (e.g., "1. text", "2. text")
- 📄 **Multi-line Support**: Handles texts with line breaks and paragraphs
- 🌍 **Unicode Support**: Works with any language including Amharic, Arabic, Chinese, etc.

## Installation

1. Create a virtual environment (recommended):
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install required packages:
```bash
pip install -r requirements.txt
```

## Usage

### Interactive Mode (Recommended)

**Option 1: Using the run script (easiest)**
```bash
./run.sh
```

**Option 2: Manual activation**
First, activate the virtual environment:
```bash
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Then run the script and paste your texts. You can use numbered format:

```bash
python3 tiktok_image_generator.py
```

Then paste your texts like this:
```
1. First text here
2. Second text here
3. Third text here
```

Or paste multi-line texts:
```
1. ክርስቶስ ሆይ 
ምን አይነት ልጅህ ነኝ ብዬ ባሰብኩ ጊዜ

2. የምወድህን ያክል አልወድህም፣ አስብሃለው ብዬ የማስብህን ያክልም አላሰብኩህም።
```

Press Enter twice when done.

### Command Line Mode

Provide your texts as command-line arguments:

```bash
python3 tiktok_image_generator.py "First text" "Second text" "Third text"
```

### Programmatic Usage

```python
from tiktok_image_generator import TikTokImageGenerator

# Create generator
generator = TikTokImageGenerator(output_dir="output")

# Generate single image
generator.generate_image("Your text here", index=0)

# Generate multiple images
texts = [
    "Text 1",
    "Text 2",
    "Text 3",
    "Text 4",
    "Text 5",
    "Text 6",
    "Text 7"
]
generator.generate_batch(texts)
```

## Output

Generated images are saved in the `output/` directory with filenames like:
- `tiktok_image_000.png`
- `tiktok_image_001.png`
- `tiktok_image_002.png`
- etc.

## Image Specifications

- **Dimensions**: 1080x1920 pixels (9:16 aspect ratio)
- **Format**: PNG
- **Quality**: High quality (95%)
- **Background**: Dynamic gradient with decorative elements
- **Text**: Centered with shadow/outline for readability

## Requirements

- Python 3.7+
- Pillow (PIL) >= 10.0.0
- numpy >= 1.24.0

