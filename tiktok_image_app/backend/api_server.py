"""
Flask API server for TikTok Image Generator
Handles image generation requests from Flutter app
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os

# Add the tiktok_photo_editor directory to path
# The image generator is at: /Users/m2pro/Desktop/tiktok/tiktok_photo_editor
photo_editor_paths = [
    os.path.join(os.path.dirname(__file__), '../../tiktok_photo_editor'),  # Relative path
    '/Users/m2pro/Desktop/tiktok/tiktok_photo_editor',  # Absolute path
    os.path.join(os.path.dirname(__file__), '../tiktok_photo_editor'),  # Alternative relative
]

photo_editor_path = None
for path in photo_editor_paths:
    if os.path.exists(path):
        sys.path.insert(0, path)
        photo_editor_path = path
        print(f"✓ Found image generator at: {path}")
        break

if not photo_editor_path:
    raise ImportError("Could not find tiktok_photo_editor directory. Please check the path.")

try:
    from tiktok_image_generator import TikTokImageGenerator
    print("✓ Successfully imported TikTokImageGenerator")
except ImportError as e:
    print(f"✗ Error importing tiktok_image_generator: {e}")
    print(f"  Searched paths: {photo_editor_paths}")
    raise

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Initialize the generator
generator = TikTokImageGenerator(output_dir="output")

@app.route('/api/generate', methods=['POST'])
def generate_images():
    """Generate images from texts and gradient colors."""
    try:
        data = request.json
        texts = data.get('texts', [])
        gradient_colors = data.get('gradient_colors', [])
        gradient_direction = data.get('gradient_direction', 'vertical')
        
        print(f"\n📥 Received request:")
        print(f"  Texts: {len(texts)} items")
        print(f"  Gradient colors: {len(gradient_colors) if gradient_colors else 0} colors")
        print(f"  Gradient direction: {gradient_direction}")
        
        if not texts:
            return jsonify({'error': 'No texts provided'}), 400
        
        # Convert gradient direction
        direction_map = {
            'vertical': 'vertical',
            'horizontal': 'horizontal',
            'diagonal': 'diagonal'
        }
        direction = direction_map.get(gradient_direction, 'vertical')
        
        # Convert gradient colors to RGB tuples (optional)
        color_tuples = []
        if gradient_colors and len(gradient_colors) > 0:
            for color in gradient_colors:
                r = color.get('r', 255) if isinstance(color, dict) else 255
                g = color.get('g', 255) if isinstance(color, dict) else 255
                b = color.get('b', 255) if isinstance(color, dict) else 255
                color_tuples.append((r, g, b))
            print(f"  Converted {len(color_tuples)} colors to tuples: {color_tuples}")
        else:
            print(f"  No gradient colors provided (empty list or None)")
        
        # If custom colors provided, use them; otherwise use random gradients
        if color_tuples and len(color_tuples) > 0:
            print(f"✓ Using custom gradient: {len(color_tuples)} colors, direction: {direction}")
            print(f"  Colors: {color_tuples}")
            # Temporarily set custom palette
            original_palettes = generator.color_palettes
            generator.color_palettes = [color_tuples]
            try:
                # Generate images with custom gradient and direction
                image_paths = []
                import time
                timestamp = int(time.time() * 1000)  # Use timestamp for unique filenames
                for i, text in enumerate(texts):
                    # Create gradient background with specified direction
                    img = generator.create_gradient_background(color_tuples, direction)
                    img = generator.add_decorative_elements(img)
                    img = generator.add_text_to_image(img, text)
                    
                    # Save image with unique filename (timestamp + index)
                    filename = f"tiktok_image_{timestamp}_{i:03d}.png"
                    filepath = os.path.join(generator.output_dir, filename)
                    img.save(filepath, "PNG", quality=95)
                    image_paths.append(filepath)
                    print(f"  ✓ Generated image {i+1}/{len(texts)}: {filename} with colors {color_tuples}")
            finally:
                # Restore original palettes
                generator.color_palettes = original_palettes
        else:
            print("✓ Using random gradients (no custom colors provided)")
            # Use random gradients (default behavior)
            image_paths = generator.generate_batch(texts)
        
        # Return absolute paths
        absolute_paths = [os.path.abspath(path) for path in image_paths]
        
        return jsonify({
            'success': True,
            'image_paths': absolute_paths,
            'count': len(absolute_paths)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    print("Starting TikTok Image Generator API server...")
    print("Server will be available at http://localhost:8000")
    app.run(host='0.0.0.0', port=8000, debug=True)

