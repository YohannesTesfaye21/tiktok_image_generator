"""
Convert images to TikTok-compatible videos
Converts PNG images to MP4 videos for TikTok upload
"""

import os
from PIL import Image
import numpy as np
from moviepy.editor import ImageClip, concatenate_videoclips
import tempfile


def image_to_video(image_path, output_path=None, duration=5, fps=30, fade_duration=0.5):
    """
    Convert a single image to a video file.
    
    Args:
        image_path: Path to input image (PNG, JPG, etc.)
        output_path: Path to output video file (optional, auto-generated if None)
        duration: Video duration in seconds (default: 5)
        fps: Frames per second (default: 30)
        fade_duration: Fade in/out duration in seconds (default: 0.5)
        
    Returns:
        str: Path to generated video file
    """
    if output_path is None:
        base_name = os.path.splitext(os.path.basename(image_path))[0]
        output_dir = os.path.dirname(image_path) or "output"
        output_path = os.path.join(output_dir, f"{base_name}.mp4")
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    try:
        # Load image
        img = Image.open(image_path)
        
        # Resize to TikTok dimensions if needed (1080x1920)
        target_size = (1080, 1920)
        if img.size != target_size:
            img = img.resize(target_size, Image.Resampling.LANCZOS)
        
        # Save to temporary file for moviepy
        temp_img_path = tempfile.mktemp(suffix='.png')
        img.save(temp_img_path, 'PNG')
        
        # Create video clip from image
        clip = ImageClip(temp_img_path, duration=duration)
        
        # Add fade in/out effects
        if fade_duration > 0:
            clip = clip.fadein(fade_duration).fadeout(fade_duration)
        
        # Set FPS
        clip = clip.set_fps(fps)
        
        # Write video file
        clip.write_videofile(
            output_path,
            fps=fps,
            codec='libx264',
            audio=False,
            preset='medium',
            bitrate='5000k',
            logger=None  # Suppress moviepy logs
        )
        
        # Clean up temporary file
        if os.path.exists(temp_img_path):
            os.remove(temp_img_path)
        
        # Clean up clip
        clip.close()
        
        print(f"✓ Converted image to video: {output_path}")
        return output_path
        
    except Exception as e:
        print(f"✗ Error converting image to video: {e}")
        # Clean up on error
        if 'temp_img_path' in locals() and os.path.exists(temp_img_path):
            os.remove(temp_img_path)
        raise


def images_to_video(image_paths, output_path=None, duration_per_image=5, fps=30, transition_duration=0.5):
    """
    Convert multiple images to a single video (slideshow style).
    
    Args:
        image_paths: List of image file paths
        output_path: Path to output video file
        duration_per_image: Duration for each image in seconds
        fps: Frames per second
        transition_duration: Transition duration between images
        
    Returns:
        str: Path to generated video file
    """
    if output_path is None:
        output_dir = os.path.dirname(image_paths[0]) if image_paths else "output"
        output_path = os.path.join(output_dir, "tiktok_video.mp4")
    
    try:
        clips = []
        
        for i, image_path in enumerate(image_paths):
            # Load and resize image
            img = Image.open(image_path)
            target_size = (1080, 1920)
            if img.size != target_size:
                img = img.resize(target_size, Image.Resampling.LANCZOS)
            
            # Save to temporary file
            temp_img_path = tempfile.mktemp(suffix='.png')
            img.save(temp_img_path, 'PNG')
            
            # Create clip
            clip = ImageClip(temp_img_path, duration=duration_per_image)
            
            # Add fade effects
            if transition_duration > 0:
                clip = clip.fadein(transition_duration).fadeout(transition_duration)
            
            clip = clip.set_fps(fps)
            clips.append(clip)
        
        # Concatenate all clips
        if len(clips) > 1:
            final_clip = concatenate_videoclips(clips, method="compose")
        else:
            final_clip = clips[0]
        
        # Write video
        final_clip.write_videofile(
            output_path,
            fps=fps,
            codec='libx264',
            audio=False,
            preset='medium',
            bitrate='5000k',
            logger=None
        )
        
        # Clean up
        for clip in clips:
            clip.close()
        final_clip.close()
        
        # Clean up temp files
        for image_path in image_paths:
            temp_path = tempfile.mktemp(suffix='.png')
            if os.path.exists(temp_path):
                os.remove(temp_path)
        
        print(f"✓ Created slideshow video: {output_path}")
        return output_path
        
    except Exception as e:
        print(f"✗ Error creating slideshow video: {e}")
        raise


