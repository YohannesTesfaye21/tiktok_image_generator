"""
TikTok API Configuration
Store credentials securely using environment variables
"""

import os

# Try to load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # If dotenv not installed, use direct environment variables
    pass

# TikTok API Credentials
TIKTOK_CLIENT_KEY = os.getenv('TIKTOK_CLIENT_KEY', 'awexlvyuyzcvvisy')
TIKTOK_CLIENT_SECRET = os.getenv('TIKTOK_CLIENT_SECRET', 'ElIE4xE3HofwInmig2QC0ZaXU3YF7mSL')

# TikTok API Endpoints
TIKTOK_AUTH_URL = "https://www.tiktok.com/v2/auth/authorize/"
TIKTOK_TOKEN_URL = "https://open.tiktok.com/oauth/access_token/"
TIKTOK_API_BASE = "https://open.tiktok.com/open_api/v2/"

# OAuth Configuration
REDIRECT_URI = os.getenv('TIKTOK_REDIRECT_URI', 'http://localhost:8000/auth/callback')
OAUTH_SCOPES = "video.publish.basic,user.info.basic"

# Video Upload Settings
VIDEO_MAX_SIZE = 4 * 1024 * 1024 * 1024  # 4GB
VIDEO_MAX_DURATION = 600  # 10 minutes in seconds
VIDEO_MIN_DURATION = 3  # Minimum 3 seconds for static images
VIDEO_FPS = 30  # Frames per second for video conversion

# Verify credentials are set
if not TIKTOK_CLIENT_KEY or not TIKTOK_CLIENT_SECRET:
    print("⚠️  WARNING: TikTok credentials not set. Please set TIKTOK_CLIENT_KEY and TIKTOK_CLIENT_SECRET in .env file")

