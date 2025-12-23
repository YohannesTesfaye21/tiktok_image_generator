"""
Flask API server for TikTok Image Generator
Handles image generation requests from Flutter app
"""

from flask import Flask, request, jsonify, redirect, session
from flask_cors import CORS
import sys
import os
import random
import time
import secrets
import json

# Import TikTok API modules
try:
    from tiktok_api import TikTokAPI
    try:
        from image_to_video import image_to_video
        VIDEO_CONVERSION_AVAILABLE = True
    except ImportError as e:
        print(f"⚠️  Video conversion not available: {e}")
        print("   TikTok posting will be disabled. Install moviepy: pip install moviepy")
        VIDEO_CONVERSION_AVAILABLE = False
        image_to_video = None
    TIKTOK_AVAILABLE = True
    print("✓ TikTok API modules loaded")
except ImportError as e:
    print(f"⚠️  TikTok API modules not available: {e}")
    TIKTOK_AVAILABLE = False
    VIDEO_CONVERSION_AVAILABLE = False
    image_to_video = None

# Import image generator
# First try same directory (for deployment), then try other paths
photo_editor_paths = [
    os.path.dirname(__file__),  # Same directory as api_server.py (for deployment)
    os.path.join(os.path.dirname(__file__), '../../tiktok_photo_editor'),  # Relative path (local dev)
    '/Users/m2pro/Desktop/tiktok/tiktok_photo_editor',  # Absolute path (local dev)
    os.path.join(os.path.dirname(__file__), '../tiktok_photo_editor'),  # Alternative relative
]

photo_editor_path = None
for path in photo_editor_paths:
    generator_file = os.path.join(path, 'tiktok_image_generator.py')
    if os.path.exists(generator_file):
        sys.path.insert(0, path)
        photo_editor_path = path
        print(f"✓ Found image generator at: {path}")
        break

if not photo_editor_path:
    raise ImportError("Could not find tiktok_image_generator.py. Please check the path.")

try:
    from tiktok_image_generator import TikTokImageGenerator
    print("✓ Successfully imported TikTokImageGenerator")
except ImportError as e:
    print(f"✗ Error importing tiktok_image_generator: {e}")
    print(f"  Searched paths: {photo_editor_paths}")
    raise

app = Flask(__name__)
app.secret_key = secrets.token_hex(32)  # Required for sessions
CORS(app, supports_credentials=True)  # Enable CORS with credentials for OAuth

# Initialize the generator
generator = TikTokImageGenerator(output_dir="output")

# Initialize TikTok API (if available)
tiktok_api = TikTokAPI() if TIKTOK_AVAILABLE else None

# In-memory token storage (use database in production)
# Format: {user_id: {'access_token': ..., 'refresh_token': ..., 'expires_at': ...}}
tiktok_tokens = {}

def _extract_semantic_colors_from_text(text):
    """Extract semantic colors based on text content keywords.
    
    This is a simple keyword-based approach. For better results,
    you could integrate with NLP/AI services to extract themes and colors.
    """
    text_lower = text.lower()
    
    # Color mappings based on keywords/themes
    color_keywords = {
        # Nature/Earth tones
        'nature': [(34, 139, 34), (107, 142, 35), (85, 107, 47)],  # Green tones
        'tree': [(34, 139, 34), (0, 100, 0), (85, 107, 47)],
        'forest': [(0, 100, 0), (34, 139, 34), (47, 79, 79)],
        'grass': [(124, 252, 0), (50, 205, 50), (34, 139, 34)],
        
        # Sky/Water tones
        'sky': [(135, 206, 235), (70, 130, 180), (30, 144, 255)],  # Blue tones
        'ocean': [(0, 119, 190), (25, 25, 112), (0, 191, 255)],
        'water': [(0, 191, 255), (70, 130, 180), (135, 206, 250)],
        'sea': [(0, 119, 190), (0, 191, 255), (70, 130, 180)],
        
        # Fire/Sunset tones
        'fire': [(255, 69, 0), (255, 140, 0), (255, 165, 0)],  # Orange/Red
        'sunset': [(255, 69, 0), (255, 140, 0), (255, 20, 147)],
        'sun': [(255, 215, 0), (255, 165, 0), (255, 140, 0)],
        'sunrise': [(255, 20, 147), (255, 69, 0), (255, 140, 0)],
        
        # Night/Dark tones
        'night': [(25, 25, 112), (0, 0, 128), (72, 61, 139)],  # Dark blue/purple
        'moon': [(192, 192, 192), (169, 169, 169), (105, 105, 105)],
        'dark': [(25, 25, 112), (0, 0, 0), (47, 79, 79)],
        
        # Love/Romance tones
        'love': [(255, 20, 147), (255, 105, 180), (219, 112, 147)],  # Pink
        'heart': [(255, 20, 147), (255, 105, 180), (220, 20, 60)],
        'romance': [(255, 20, 147), (255, 182, 193), (255, 105, 180)],
        
        # Warm/Earthy tones
        'earth': [(139, 69, 19), (160, 82, 45), (210, 180, 140)],  # Brown
        'warm': [(255, 140, 0), (255, 165, 0), (255, 69, 0)],
        'autumn': [(255, 140, 0), (255, 69, 0), (139, 69, 19)],
    }
    
    # Check for keywords in text (case-insensitive)
    for keyword, colors in color_keywords.items():
        if keyword.lower() in text_lower:
            print(f"    Found keyword '{keyword}' in text")
            return colors
    
    # If no specific keywords found, return None to use random gradient
    print(f"    No semantic keywords found in text")
    return None

@app.route('/api/generate', methods=['POST'])
def generate_images():
    """Generate images from texts and gradient colors."""
    try:
        data = request.json
        texts = data.get('texts', [])
        gradient_colors = data.get('gradient_colors', [])
        gradient_direction = data.get('gradient_direction', 'vertical')
        use_content_based_image = data.get('use_content_based_image', False)
        
        print(f"\n📥 Received request:")
        print(f"  Texts: {len(texts)} items")
        print(f"  Gradient colors: {len(gradient_colors) if gradient_colors else 0} colors")
        print(f"  Gradient direction: {gradient_direction}")
        print(f"  Content-based image: {use_content_based_image}")
        
        if use_content_based_image:
            print("  ⚠️  CONTENT-BASED MODE: Will IGNORE selected gradient colors")
            print("  ⚠️  Will extract colors from text content instead")
        
        if not texts:
            return jsonify({'error': 'No texts provided'}), 400
        
        # If content-based image is requested, generate image based on text content
        if use_content_based_image:
            print("🎨 Content-based image generation requested")
            print("   Generating background image from text content...")
            
            # Generate images with content-based backgrounds
            image_paths = []
            import time
            timestamp = int(time.time() * 1000)
            
            # Convert gradient direction first
            direction_map = {
                'vertical': 'vertical',
                'horizontal': 'horizontal',
                'diagonal': 'diagonal'
            }
            direction = direction_map.get(gradient_direction, 'vertical')
            
            for i, text in enumerate(texts):
                print(f"  📝 Processing text {i+1}: {text[:50]}...")
                
                # TODO: INTEGRATE AI IMAGE GENERATION API HERE
                # Currently, we use semantic color extraction as a placeholder
                # To generate actual images, you need to:
                # 1. Sign up for an AI image API (DALL-E, Stable Diffusion, etc.)
                # 2. Add API key to environment variables
                # 3. Implement generate_ai_image_from_text() function
                # 4. Replace the gradient creation below with:
                #    background_img = generate_ai_image_from_text(text)
                #    img = Image.open(background_img).resize((1080, 1920))
                
                # For now: Extract semantic colors from text (creates gradient, not image)
                semantic_colors = _extract_semantic_colors_from_text(text)
                
                # In content-based mode, ALWAYS use semantic colors from text
                # Ignore manually selected gradient colors
                if semantic_colors and len(semantic_colors) > 0:
                    bg_colors = semantic_colors
                    print(f"  🎨 Text {i+1}: Using semantic colors: {semantic_colors}")
                    print(f"  ⚠️  NOTE: This creates a GRADIENT, not an AI-generated image")
                    print(f"  ⚠️  To get actual images, integrate an AI image generation API")
                else:
                    # If no semantic match, use random (not user-selected colors)
                    palette = random.choice(generator.color_palettes)
                    bg_colors = palette
                    print(f"  🎨 Text {i+1}: No semantic match, using random colors")
                    print(f"  ⚠️  NOTE: This is still a GRADIENT, not an AI-generated image")
                
                # Create gradient background with semantic colors
                # TODO: Replace with: img = load_ai_generated_image(text)
                img = generator.create_gradient_background(bg_colors, direction)
                
                img = generator.add_decorative_elements(img)
                img = generator.add_text_to_image(img, text)
                
                filename = f"tiktok_image_{timestamp}_{i:03d}.png"
                filepath = os.path.join(generator.output_dir, filename)
                img.save(filepath, "PNG", quality=95)
                image_paths.append(filepath)
                print(f"  ✓ Generated content-based image {i+1}/{len(texts)}: {filename}")
            
            absolute_paths = [os.path.abspath(path) for path in image_paths]
            return jsonify({
                'success': True,
                'image_paths': absolute_paths,
                'count': len(absolute_paths)
            })
        
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
            print(f"  ✓ Custom gradient colors provided: {len(color_tuples)} colors")
            print(f"  Colors: {color_tuples}")
        else:
            print(f"  ✓ No custom colors - using random gradient")
        
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
    return jsonify({'status': 'ok', 'tiktok_available': TIKTOK_AVAILABLE})

# ============================================================================
# TIKTOK OAUTH ENDPOINTS
# ============================================================================

@app.route('/api/tiktok/auth/authorize', methods=['GET'])
def tiktok_authorize():
    """Initiate TikTok OAuth flow."""
    if not TIKTOK_AVAILABLE:
        return jsonify({'error': 'TikTok API not available'}), 503
    
    try:
        # Generate state for CSRF protection
        state = secrets.token_urlsafe(32)
        session['oauth_state'] = state
        
        # Get authorization URL
        auth_url, _ = tiktok_api.get_authorization_url(state)
        
        return jsonify({
            'success': True,
            'auth_url': auth_url,
            'state': state
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/auth/callback', methods=['GET'])
def tiktok_callback():
    """Handle TikTok OAuth callback."""
    if not TIKTOK_AVAILABLE:
        return jsonify({'error': 'TikTok API not available'}), 503
    
    try:
        code = request.args.get('code')
        state = request.args.get('state')
        error = request.args.get('error')
        
        if error:
            return jsonify({'error': f'OAuth error: {error}'}), 400
        
        if not code:
            return jsonify({'error': 'No authorization code provided'}), 400
        
        # Verify state (CSRF protection)
        if 'oauth_state' not in session or session['oauth_state'] != state:
            return jsonify({'error': 'Invalid state parameter'}), 400
        
        # Exchange code for token
        token_response = tiktok_api.exchange_code_for_token(code)
        
        if 'error' in token_response:
            return jsonify({'error': token_response.get('error_description', 'Token exchange failed')}), 400
        
        # Store tokens (in production, use database with user ID)
        access_token = token_response.get('access_token')
        refresh_token = token_response.get('refresh_token')
        expires_in = token_response.get('expires_in', 3600)
        
        # Get user info to identify user
        user_info = tiktok_api.get_user_info(access_token)
        user_id = user_info.get('data', {}).get('user', {}).get('open_id', 'default')
        
        tiktok_tokens[user_id] = {
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_at': time.time() + expires_in
        }
        
        # Clear session state
        session.pop('oauth_state', None)
        
        # Return HTML page that Flutter can detect
        # The page contains the user info in a script tag for easy extraction
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>TikTok Connected</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }}
                .container {{
                    text-align: center;
                    padding: 20px;
                }}
                .success {{
                    font-size: 24px;
                    margin-bottom: 10px;
                }}
                .message {{
                    font-size: 16px;
                    opacity: 0.9;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="success">✓ TikTok Account Connected!</div>
                <div class="message">You can close this window and return to the app.</div>
            </div>
            <script>
                // Store connection data for Flutter to detect
                window.tiktokAuthResult = {{
                    success: true,
                    user_id: '{user_id}',
                    user_info: {json.dumps(user_info)}
                }};
                // Also update URL hash for easier detection
                window.location.hash = '#tiktok_connected';
            </script>
        </body>
        </html>
        """
        
        return html_content, 200, {'Content-Type': 'text/html'}
        
    except Exception as e:
        # Return error page
        error_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Connection Failed</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: #f44336;
                    color: white;
                }}
                .container {{
                    text-align: center;
                    padding: 20px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div style="font-size: 24px; margin-bottom: 10px;">✗ Connection Failed</div>
                <div style="font-size: 16px;">{str(e)}</div>
            </div>
            <script>
                window.tiktokAuthResult = {{
                    success: false,
                    error: '{str(e).replace("'", "\\'")}'
                }};
                window.location.hash = '#tiktok_error';
            </script>
        </body>
        </html>
        """
        return error_html, 400, {'Content-Type': 'text/html'}

@app.route('/api/tiktok/user/info', methods=['GET'])
def tiktok_user_info():
    """Get connected TikTok user information."""
    if not TIKTOK_AVAILABLE:
        return jsonify({'error': 'TikTok API not available'}), 503
    
    try:
        user_id = request.args.get('user_id', 'default')
        
        if user_id not in tiktok_tokens:
            return jsonify({'error': 'User not connected'}), 401
        
        token_data = tiktok_tokens[user_id]
        access_token = token_data['access_token']
        
        # Check if token expired
        if time.time() > token_data['expires_at']:
            # Refresh token
            new_token = tiktok_api.refresh_access_token(token_data['refresh_token'])
            access_token = new_token['access_token']
            token_data['access_token'] = access_token
            token_data['expires_at'] = time.time() + new_token.get('expires_in', 3600)
        
        user_info = tiktok_api.get_user_info(access_token)
        return jsonify({'success': True, 'user_info': user_info})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# TIKTOK POSTING ENDPOINTS
# ============================================================================

@app.route('/api/tiktok/post/video', methods=['POST'])
def tiktok_post_video():
    """Post a video to TikTok."""
    if not TIKTOK_AVAILABLE:
        return jsonify({'error': 'TikTok API not available'}), 503
    
    try:
        data = request.json
        image_path = data.get('image_path')
        user_id = data.get('user_id', 'default')
        caption = data.get('caption', '')
        privacy_level = data.get('privacy_level', 'PUBLIC_TO_EVERYONE')
        video_duration = data.get('duration', 5)  # Default 5 seconds
        
        if not image_path:
            return jsonify({'error': 'No image path provided'}), 400
        
        if user_id not in tiktok_tokens:
            return jsonify({'error': 'User not connected to TikTok'}), 401
        
        # Get access token
        token_data = tiktok_tokens[user_id]
        access_token = token_data['access_token']
        
        # Check if token expired
        if time.time() > token_data['expires_at']:
            new_token = tiktok_api.refresh_access_token(token_data['refresh_token'])
            access_token = new_token['access_token']
            token_data['access_token'] = access_token
            token_data['expires_at'] = time.time() + new_token.get('expires_in', 3600)
        
        # Check if video conversion is available
        if not VIDEO_CONVERSION_AVAILABLE or image_to_video is None:
            return jsonify({
                'error': 'Video conversion not available. Please install moviepy: pip install moviepy'
            }), 503
        
        # Convert image to video
        print(f"📹 Converting image to video: {image_path}")
        video_path = image_to_video(image_path, duration=video_duration)
        
        # Get video file size
        video_size = os.path.getsize(video_path)
        
        # Initialize upload
        print(f"📤 Initializing TikTok video upload...")
        init_response = tiktok_api.initialize_video_upload(
            access_token, 
            video_size, 
            video_duration
        )
        
        if 'error' in init_response:
            return jsonify({'error': init_response.get('error_description', 'Upload initialization failed')}), 400
        
        upload_id = init_response.get('data', {}).get('upload_id')
        upload_url = init_response.get('data', {}).get('upload_url')
        
        if not upload_id or not upload_url:
            return jsonify({'error': 'Invalid upload initialization response'}), 500
        
        # Upload video
        print(f"⬆️  Uploading video to TikTok...")
        with open(video_path, 'rb') as f:
            video_data = f.read()
        
        upload_response = tiktok_api.upload_video_chunk(upload_url, video_data)
        
        # Commit upload
        print(f"✅ Committing video upload...")
        commit_response = tiktok_api.commit_video_upload(
            access_token,
            upload_id,
            caption,
            privacy_level
        )
        
        # Clean up video file
        if os.path.exists(video_path):
            os.remove(video_path)
        
        if 'error' in commit_response:
            return jsonify({'error': commit_response.get('error_description', 'Video commit failed')}), 400
        
        return jsonify({
            'success': True,
            'message': 'Video uploaded successfully. Check your TikTok inbox to publish.',
            'upload_id': upload_id,
            'response': commit_response
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/tiktok/post/multiple', methods=['POST'])
def tiktok_post_multiple():
    """Post multiple images as a slideshow video to TikTok."""
    if not TIKTOK_AVAILABLE:
        return jsonify({'error': 'TikTok API not available'}), 503
    
    try:
        data = request.json
        image_paths = data.get('image_paths', [])
        user_id = data.get('user_id', 'default')
        caption = data.get('caption', '')
        privacy_level = data.get('privacy_level', 'PUBLIC_TO_EVERYONE')
        duration_per_image = data.get('duration_per_image', 3)
        
        if not image_paths:
            return jsonify({'error': 'No image paths provided'}), 400
        
        if user_id not in tiktok_tokens:
            return jsonify({'error': 'User not connected to TikTok'}), 401
        
        # Get access token
        token_data = tiktok_tokens[user_id]
        access_token = token_data['access_token']
        
        # Check if token expired
        if time.time() > token_data['expires_at']:
            new_token = tiktok_api.refresh_access_token(token_data['refresh_token'])
            access_token = new_token['access_token']
            token_data['access_token'] = access_token
            token_data['expires_at'] = time.time() + new_token.get('expires_in', 3600)
        
        # Check if video conversion is available
        if not VIDEO_CONVERSION_AVAILABLE:
            return jsonify({
                'error': 'Video conversion not available. Please install moviepy: pip install moviepy'
            }), 503
        
        # Convert images to slideshow video
        from image_to_video import images_to_video
        print(f"📹 Converting {len(image_paths)} images to slideshow video...")
        video_path = images_to_video(image_paths, duration_per_image=duration_per_image)
        
        # Calculate total duration
        total_duration = len(image_paths) * duration_per_image
        
        # Get video file size
        video_size = os.path.getsize(video_path)
        
        # Initialize upload
        print(f"📤 Initializing TikTok video upload...")
        init_response = tiktok_api.initialize_video_upload(
            access_token,
            video_size,
            total_duration
        )
        
        if 'error' in init_response:
            return jsonify({'error': init_response.get('error_description', 'Upload initialization failed')}), 400
        
        upload_id = init_response.get('data', {}).get('upload_id')
        upload_url = init_response.get('data', {}).get('upload_url')
        
        if not upload_id or not upload_url:
            return jsonify({'error': 'Invalid upload initialization response'}), 500
        
        # Upload video
        print(f"⬆️  Uploading video to TikTok...")
        with open(video_path, 'rb') as f:
            video_data = f.read()
        
        upload_response = tiktok_api.upload_video_chunk(upload_url, video_data)
        
        # Commit upload
        print(f"✅ Committing video upload...")
        commit_response = tiktok_api.commit_video_upload(
            access_token,
            upload_id,
            caption,
            privacy_level
        )
        
        # Clean up video file
        if os.path.exists(video_path):
            os.remove(video_path)
        
        if 'error' in commit_response:
            return jsonify({'error': commit_response.get('error_description', 'Video commit failed')}), 400
        
        return jsonify({
            'success': True,
            'message': f'Slideshow video uploaded successfully. Check your TikTok inbox to publish.',
            'upload_id': upload_id,
            'response': commit_response
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    print("Starting TikTok Image Generator API server...")
    print(f"Server will be available at http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=debug)

