"""
TikTok API Client
Handles OAuth, video upload, and publishing to TikTok
"""

import requests
import json
import time
from tiktok_config import (
    TIKTOK_CLIENT_KEY,
    TIKTOK_CLIENT_SECRET,
    TIKTOK_AUTH_URL,
    TIKTOK_TOKEN_URL,
    TIKTOK_API_BASE,
    REDIRECT_URI,
    OAUTH_SCOPES
)


class TikTokAPI:
    """TikTok API client for OAuth and video posting."""
    
    def __init__(self):
        self.client_key = TIKTOK_CLIENT_KEY
        self.client_secret = TIKTOK_CLIENT_SECRET
        self.redirect_uri = REDIRECT_URI
        self.scopes = OAUTH_SCOPES
    
    def get_authorization_url(self, state=None):
        """
        Generate TikTok OAuth authorization URL.
        
        Args:
            state: Optional state parameter for CSRF protection
            
        Returns:
            str: Authorization URL
        """
        if state is None:
            import secrets
            state = secrets.token_urlsafe(32)
        
        params = {
            'client_key': self.client_key,
            'scope': self.scopes,
            'response_type': 'code',
            'redirect_uri': self.redirect_uri,
            'state': state,
            # Add parameters to encourage web-based login
            'enter_method': 'web',  # Force web-based login
            'hide_left_icon': '0',
            'type': '',  # Empty type to avoid app-specific flows
        }
        
        url = f"{TIKTOK_AUTH_URL}?" + "&".join([f"{k}={v}" for k, v in params.items()])
        return url, state
    
    def exchange_code_for_token(self, code):
        """
        Exchange authorization code for access token.
        
        Args:
            code: Authorization code from OAuth callback
            
        Returns:
            dict: Token response with access_token, refresh_token, etc.
        """
        data = {
            'client_key': self.client_key,
            'client_secret': self.client_secret,
            'code': code,
            'grant_type': 'authorization_code',
            'redirect_uri': self.redirect_uri
        }
        
        try:
            response = requests.post(TIKTOK_TOKEN_URL, data=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error exchanging code for token: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise
    
    def refresh_access_token(self, refresh_token):
        """
        Refresh an expired access token.
        
        Args:
            refresh_token: The refresh token
            
        Returns:
            dict: New token response
        """
        data = {
            'client_key': self.client_key,
            'client_secret': self.client_secret,
            'grant_type': 'refresh_token',
            'refresh_token': refresh_token
        }
        
        try:
            response = requests.post(TIKTOK_TOKEN_URL, data=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error refreshing token: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise
    
    def initialize_video_upload(self, access_token, video_size, video_duration):
        """
        Initialize video upload to TikTok.
        
        Args:
            access_token: User's access token
            video_size: Size of video file in bytes
            video_duration: Duration of video in seconds
            
        Returns:
            dict: Upload initialization response with upload_url
        """
        url = f"{TIKTOK_API_BASE}post/publish/inbox/video/init/"
        
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        data = {
            'source_info': {
                'source': 'FILE_UPLOAD'
            },
            'post_info': {
                'title': 'Generated TikTok Image',
                'privacy_level': 'PUBLIC_TO_EVERYONE',
                'disable_duet': False,
                'disable_comment': False,
                'disable_stitch': False,
                'video_cover_timestamp_ms': 1000
            },
            'video_info': {
                'video_size': video_size,
                'video_duration': video_duration
            }
        }
        
        try:
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error initializing video upload: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise
    
    def upload_video_chunk(self, upload_url, video_data, chunk_number=0, total_chunks=1):
        """
        Upload video file to TikTok.
        
        Args:
            upload_url: Upload URL from initialization
            video_data: Video file bytes
            chunk_number: Chunk number (for multi-part uploads)
            total_chunks: Total number of chunks
            
        Returns:
            dict: Upload response
        """
        try:
            # For single chunk uploads
            files = {
                'video': ('video.mp4', video_data, 'video/mp4')
            }
            
            response = requests.put(upload_url, files=files)
            response.raise_for_status()
            return response.json() if response.content else {'status': 'success'}
        except requests.exceptions.RequestException as e:
            print(f"Error uploading video chunk: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise
    
    def commit_video_upload(self, access_token, upload_id, caption="", privacy_level="PUBLIC_TO_EVERYONE"):
        """
        Commit and publish video upload.
        
        Args:
            access_token: User's access token
            upload_id: Upload ID from initialization
            caption: Video caption
            privacy_level: Privacy setting
            
        Returns:
            dict: Commit response
        """
        url = f"{TIKTOK_API_BASE}post/publish/inbox/video/commit/"
        
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        data = {
            'upload_id': upload_id,
            'post_info': {
                'title': caption,
                'privacy_level': privacy_level,
                'disable_duet': False,
                'disable_comment': False,
                'disable_stitch': False
            }
        }
        
        try:
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error committing video: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise
    
    def get_user_info(self, access_token):
        """
        Get user information.
        
        Args:
            access_token: User's access token
            
        Returns:
            dict: User info response
        """
        url = f"{TIKTOK_API_BASE}user/info/"
        
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        params = {
            'fields': 'open_id,union_id,avatar_url,display_name'
        }
        
        try:
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error getting user info: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            raise


