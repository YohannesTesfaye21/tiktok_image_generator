"""
TikTok Image Generator
Generates attractive, dynamic images with text content optimized for TikTok.
"""

from PIL import Image, ImageDraw, ImageFont
import random
import os
from typing import List, Tuple
import math
import re
import urllib.request
import shutil


class TikTokImageGenerator:
    """Generate TikTok-optimized images with text content."""
    
    # TikTok standard dimensions (vertical format)
    WIDTH = 1080
    HEIGHT = 1920
    
    def __init__(self, output_dir: str = "output"):
        """Initialize the generator.
        
        Args:
            output_dir: Directory to save generated images
        """
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.font_cache_dir = os.path.join(os.path.expanduser("~"), ".tiktok_fonts")
        os.makedirs(self.font_cache_dir, exist_ok=True)
        # Ensure Noto Sans Ethiopic is available
        self._ensure_noto_font()
        
        # Color palettes for dynamic backgrounds
        self.color_palettes = [
            # Vibrant gradients
            [(255, 107, 107), (255, 159, 64), (255, 206, 84)],
            [(72, 219, 251), (163, 230, 53), (18, 183, 106)],
            [(255, 77, 77), (255, 184, 0), (255, 255, 0)],
            [(138, 43, 226), (255, 20, 147), (255, 105, 180)],
            [(0, 191, 255), (0, 250, 154), (50, 205, 50)],
            # Modern pastels
            [(255, 182, 193), (255, 218, 185), (255, 239, 213)],
            [(173, 216, 230), (176, 224, 230), (175, 238, 238)],
            # Bold and dark
            [(25, 25, 112), (72, 61, 139), (123, 104, 238)],
            [(139, 0, 0), (178, 34, 34), (220, 20, 60)],
            # Energetic
            [(255, 69, 0), (255, 140, 0), (255, 215, 0)],
        ]
        
        # Text colors (high contrast for readability)
        self.text_colors = [
            (255, 255, 255),  # White
            (0, 0, 0),         # Black
            (255, 255, 255),  # White
            (255, 255, 255),  # White
            (0, 0, 0),         # Black
        ]
    
    def create_gradient_background(self, colors: List[Tuple[int, int, int]],
                                   direction: str = "vertical") -> Image.Image:
        """Create a gradient background.
        
        Args:
            colors: List of RGB color tuples
            direction: 'vertical', 'horizontal', or 'diagonal'
            
        Returns:
            PIL Image with gradient background
        """
        # Validate and sanitize colors
        if not colors or len(colors) == 0:
            print("⚠️  Warning: No colors provided, using default white")
            colors = [(255, 255, 255)]
        
        # Filter and validate each color
        valid_colors = []
        for i, color in enumerate(colors):
            if not isinstance(color, (tuple, list)) or len(color) < 3:
                print(f"⚠️  Warning: Invalid color at index {i}: {color}, skipping")
                continue
            try:
                # Ensure all values are integers in valid range
                r = max(0, min(255, int(color[0])))
                g = max(0, min(255, int(color[1])))
                b = max(0, min(255, int(color[2])))
                valid_colors.append((r, g, b))
            except (ValueError, TypeError, IndexError) as e:
                print(f"⚠️  Warning: Error processing color {color}: {e}, skipping")
                continue
        
        if len(valid_colors) == 0:
            print("⚠️  Warning: No valid colors after filtering, using default white")
            valid_colors = [(255, 255, 255)]
        
        colors = valid_colors
        
        img = Image.new('RGB', (self.WIDTH, self.HEIGHT))
        draw = ImageDraw.Draw(img)
        
        if direction == "vertical":
            for y in range(self.HEIGHT):
                ratio = y / self.HEIGHT
                color = self._interpolate_color(colors, ratio)
                draw.line([(0, y), (self.WIDTH, y)], fill=color)
        elif direction == "horizontal":
            for x in range(self.WIDTH):
                ratio = x / self.WIDTH
                color = self._interpolate_color(colors, ratio)
                draw.line([(x, 0), (x, self.HEIGHT)], fill=color)
        else:  # diagonal
            for y in range(self.HEIGHT):
                for x in range(self.WIDTH):
                    ratio = (x + y) / (self.WIDTH + self.HEIGHT)
                    color = self._interpolate_color(colors, ratio)
                    draw.point((x, y), fill=color)
        
        return img
    
    def _interpolate_color(self, colors: List[Tuple[int, int, int]], 
                          ratio: float) -> Tuple[int, int, int]:
        """Interpolate between colors based on ratio."""
        if not colors or len(colors) == 0:
            return (255, 255, 255)  # Default white if no colors
        
        ratio = max(0, min(1, ratio))
        if len(colors) == 1:
            return colors[0]
        
        segment = ratio * (len(colors) - 1)
        index = int(segment)
        # Ensure index is within bounds
        index = max(0, min(index, len(colors) - 2))
        t = segment - index
        
        if index >= len(colors) - 1:
            return colors[-1]
        
        c1 = colors[index]
        c2 = colors[index + 1]
        
        # Validate and convert c1
        try:
            if not isinstance(c1, (tuple, list)) or len(c1) < 3:
                print(f"⚠️  Warning: Invalid color c1: {c1}, using default white")
                c1 = (255, 255, 255)
            else:
                # Safely convert to int tuple
                c1 = (int(c1[0]), int(c1[1]), int(c1[2]))
                # Validate range
                c1 = (max(0, min(255, c1[0])), max(0, min(255, c1[1])), max(0, min(255, c1[2])))
        except (ValueError, TypeError, IndexError, AttributeError) as e:
            print(f"⚠️  Warning: Error processing c1: {e}, c1={c1}, using default white")
            c1 = (255, 255, 255)
        
        # Validate and convert c2
        try:
            if not isinstance(c2, (tuple, list)) or len(c2) < 3:
                print(f"⚠️  Warning: Invalid color c2: {c2}, using default white")
                c2 = (255, 255, 255)
            else:
                # Safely convert to int tuple
                c2 = (int(c2[0]), int(c2[1]), int(c2[2]))
                # Validate range
                c2 = (max(0, min(255, c2[0])), max(0, min(255, c2[1])), max(0, min(255, c2[2])))
        except (ValueError, TypeError, IndexError, AttributeError) as e:
            print(f"⚠️  Warning: Error processing c2: {e}, c2={c2}, using default white")
            c2 = (255, 255, 255)
        
        return (
            int(c1[0] + (c2[0] - c1[0]) * t),
            int(c1[1] + (c2[1] - c1[1]) * t),
            int(c1[2] + (c2[2] - c1[2]) * t)
        )
    
    def add_decorative_elements(self, img: Image.Image) -> Image.Image:
        """Add decorative elements to make the image more attractive."""
        draw = ImageDraw.Draw(img, 'RGBA')
        
        # Add some circles/ellipses
        num_elements = random.randint(3, 6)
        for _ in range(num_elements):
            x = random.randint(0, self.WIDTH)
            y = random.randint(0, self.HEIGHT)
            size = random.randint(100, 400)
            color = (*random.choice(self.color_palettes[0]), random.randint(30, 100))
            draw.ellipse([x-size, y-size, x+size, y+size], fill=color)
        
        # Add some lines
        for _ in range(random.randint(2, 4)):
            x1 = random.randint(0, self.WIDTH)
            y1 = random.randint(0, self.HEIGHT)
            x2 = random.randint(0, self.WIDTH)
            y2 = random.randint(0, self.HEIGHT)
            color = (*random.choice(self.color_palettes[0]), random.randint(50, 150))
            draw.line([(x1, y1), (x2, y2)], fill=color, width=random.randint(3, 8))
        
        return img
    
    def _ensure_noto_font(self):
        """Download Noto Sans Ethiopic font if not available."""
        noto_path = os.path.join(self.font_cache_dir, "NotoSansEthiopic-Regular.ttf")
        if not os.path.exists(noto_path):
            try:
                print("Downloading Noto Sans Ethiopic font for proper Amharic support...")
                # Get the latest URL from Google Fonts API
                try:
                    import urllib.parse
                    css_url = "https://fonts.googleapis.com/css2?family=Noto+Sans+Ethiopic:wght@400"
                    css_response = urllib.request.urlopen(css_url)
                    css_content = css_response.read().decode('utf-8')
                    # Extract TTF URL from CSS
                    import re
                    ttf_urls = re.findall(r'url\((https://[^)]+\.ttf)\)', css_content)
                    if ttf_urls:
                        font_url = ttf_urls[0]
                        urllib.request.urlretrieve(font_url, noto_path)
                        # Verify it's a valid font file
                        test_font = ImageFont.truetype(noto_path, 20)
                        print("✓ Noto Sans Ethiopic downloaded successfully!")
                    else:
                        raise Exception("Could not find TTF URL in CSS")
                except Exception as e:
                    # Fallback to a known working URL
                    try:
                        font_url = "https://fonts.gstatic.com/s/notosansethiopic/v50/7cHPv50vjIepfJVOZZgcpQ5B9FBTH9KGNfhSTgtoow1KVnIvyBoMSzUMacb-T35OK6Dj.ttf"
                        urllib.request.urlretrieve(font_url, noto_path)
                        test_font = ImageFont.truetype(noto_path, 20)
                        print("✓ Noto Sans Ethiopic downloaded successfully!")
                    except Exception as e2:
                        print(f"⚠ Could not download Noto font: {e2}")
                        print("   Will try system fonts instead...")
            except Exception as e:
                print(f"⚠ Could not download Noto font: {e}")
                print("   Will try system fonts instead...")
    
    def get_font(self, size: int, text: str = ""):
        """Get a font that supports Unicode/Amharic characters.
        
        Args:
            size: Font size
            text: Sample text to check font support (optional)
        """
        # Check if text contains Amharic characters
        has_amharic = text and any('\u1200' <= char <= '\u137F' for char in text)
        
        # For Amharic text, ALWAYS use Noto Sans Ethiopic if available
        if has_amharic:
            noto_path = os.path.join(self.font_cache_dir, "NotoSansEthiopic-Regular.ttf")
            if os.path.exists(noto_path):
                try:
                    font = ImageFont.truetype(noto_path, size)
                    print(f"✓ Using Noto Sans Ethiopic (best for Amharic)")
                    return font
                except Exception as e:
                    print(f"⚠ Warning: Could not load Noto font: {e}")
                    # Continue to try other fonts
        
        # Fonts that support Amharic/Unicode (prioritized order)
        font_paths = [
            # Try to download Noto if not already cached
            noto_path if os.path.exists(noto_path) else None,
            # macOS system fonts with Unicode support
            "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
            "/System/Library/Fonts/Supplemental/NotoSansEthiopic-Regular.ttf",
            "/System/Library/Fonts/Supplemental/NotoSansEthiopic-Bold.ttf",
            "/Library/Fonts/Arial Unicode.ttf",
            "/System/Library/Fonts/Supplemental/AppleGothic.ttf",
            "/System/Library/Fonts/Supplemental/STHeiti Light.ttc",
            "/System/Library/Fonts/Supplemental/STHeiti Medium.ttc",
            # Try Arial variants
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            # Linux/Windows fallbacks
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/ARIALUNI.TTF",
        ]
        
        # Try each font path
        for path in font_paths:
            if path and os.path.exists(path):
                try:
                    font = ImageFont.truetype(path, size)
                    # Test if font can render Amharic characters (if text provided)
                    if text:
                        # Check if text contains Amharic characters
                        has_amharic = any('\u1200' <= char <= '\u137F' for char in text)
                        if has_amharic:
                            # Simple test: just check if font can get bbox for Amharic character
                            test_char = "አ"  # Common Amharic character (U+12A0)
                            try:
                                bbox = font.getbbox(test_char)
                                # If width is reasonable, font supports it
                                if bbox[2] - bbox[0] > 5:
                                    print(f"✓ Using font: {path} (supports Amharic)")
                                    return font
                            except:
                                continue  # Font can't handle Amharic, try next
                    return font
                except Exception as e:
                    continue
        
        # Last resort: try to find any TTF font in common locations
        common_dirs = [
            "/System/Library/Fonts/Supplemental/",
            "/Library/Fonts/",
            "/usr/share/fonts/",
        ]
        
        for font_dir in common_dirs:
            if os.path.exists(font_dir):
                try:
                    for file in os.listdir(font_dir):
                        if file.lower().endswith(('.ttf', '.ttc', '.otf')):
                            font_path = os.path.join(font_dir, file)
                            try:
                                font = ImageFont.truetype(font_path, size)
                                if text:
                                    # Check if text contains Amharic characters
                                    has_amharic = any('\u1200' <= char <= '\u137F' for char in text)
                                    if has_amharic:
                                        try:
                                            test_char = "አ"
                                            bbox = font.getbbox(test_char)
                                            if bbox[2] - bbox[0] < 5:
                                                continue  # Font doesn't support Amharic
                                        except:
                                            continue  # Font can't handle Amharic
                                return font
                            except:
                                continue
                except:
                    continue
        
        # Try downloaded Noto Sans Ethiopic (should be available from __init__)
        noto_path = os.path.join(self.font_cache_dir, "NotoSansEthiopic-Regular.ttf")
        if os.path.exists(noto_path):
            try:
                font = ImageFont.truetype(noto_path, size)
                if text:
                    has_amharic = any('\u1200' <= char <= '\u137F' for char in text)
                    if has_amharic:
                        try:
                            test_char = "አ"
                            bbox = font.getbbox(test_char)
                            if bbox[2] - bbox[0] >= 5:
                                return font
                        except:
                            pass
                return font
            except:
                pass
        
        # Ultimate fallback
        print("Warning: Could not find Unicode font, using default (may not support Amharic)")
        return ImageFont.load_default()
    
    def wrap_text(self, text: str, font: ImageFont.FreeTypeFont, 
                  max_width: int) -> List[str]:
        """Wrap text to fit within max_width."""
        words = text.split()
        lines = []
        current_line = []
        
        for word in words:
            test_line = ' '.join(current_line + [word])
            bbox = font.getbbox(test_line)
            text_width = bbox[2] - bbox[0]
            
            if text_width <= max_width:
                current_line.append(word)
            else:
                if current_line:
                    lines.append(' '.join(current_line))
                current_line = [word]
        
        if current_line:
            lines.append(' '.join(current_line))
        
        return lines if lines else [text]
    
    def add_text_to_image(self, img: Image.Image, text: str) -> Image.Image:
        """Add text to image with dynamic styling.
        
        Supports multi-line text and Unicode characters (e.g., Amharic).
        """
        draw = ImageDraw.Draw(img)
        
        # Choose random text color
        text_color = random.choice(self.text_colors)
        
        # Calculate font size based on text length
        base_size = 120
        text_length = len(text)
        if text_length > 100:
            font_size = int(base_size * 0.6)
        elif text_length > 50:
            font_size = int(base_size * 0.7)
        elif text_length > 30:
            font_size = int(base_size * 0.85)
        else:
            font_size = base_size
        
        # Get font that supports the text (especially for Amharic/Unicode)
        font = self.get_font(font_size, text)
        
        # Handle multi-line text: split by newlines first, then wrap each paragraph
        max_width = self.WIDTH - 200  # Margins
        all_lines = []
        
        # Split by explicit newlines (preserve user's line breaks)
        paragraphs = text.split('\n')
        for paragraph in paragraphs:
            if paragraph.strip():
                # Wrap each paragraph
                wrapped = self.wrap_text(paragraph.strip(), font, max_width)
                all_lines.extend(wrapped)
                # Add small gap between paragraphs
                if len(wrapped) > 0:
                    all_lines.append("")  # Empty line for spacing
        
        # Remove trailing empty line
        if all_lines and not all_lines[-1]:
            all_lines.pop()
        
        # Calculate total text height
        line_height = int(font_size * 1.4)
        total_height = len(all_lines) * line_height
        
        # Center vertically
        start_y = (self.HEIGHT - total_height) // 2
        
        # Add text shadow/outline for better readability
        shadow_offset = 3
        
        # Draw each line
        for i, line in enumerate(all_lines):
            if not line:  # Skip empty lines (spacing)
                continue
                
            y = start_y + i * line_height
            
            # Get text dimensions (handles Unicode properly)
            try:
                bbox = font.getbbox(line)
                text_width = bbox[2] - bbox[0]
            except:
                # Fallback for complex Unicode
                text_width = len(line) * font_size * 0.6
            
            # Center horizontally
            x = (self.WIDTH - text_width) // 2
            
            # Draw shadow
            shadow_color = (0, 0, 0) if text_color == (255, 255, 255) else (255, 255, 255)
            for dx in range(-shadow_offset, shadow_offset + 1):
                for dy in range(-shadow_offset, shadow_offset + 1):
                    if dx != 0 or dy != 0:
                        try:
                            draw.text((x + dx, y + dy), line, font=font, fill=shadow_color)
                        except:
                            pass  # Skip shadow if there's an issue
            
            # Draw main text
            try:
                draw.text((x, y), line, font=font, fill=text_color)
            except Exception as e:
                # Don't fallback to default font for Amharic - it won't work
                # Just report the error
                print(f"Warning: Could not render line with selected font: {line[:30]}...")
                print(f"Error: {e}")
                # Try to render anyway - sometimes it works despite the exception
                try:
                    draw.text((x, y), line, font=font, fill=text_color)
                except:
                    pass
        
        return img
    
    def generate_image(self, text: str, index: int = 0) -> str:
        """Generate a single image with text.
        
        Args:
            text: Text content to display
            index: Index for filename
            
        Returns:
            Path to generated image
        """
        # Choose random color palette and direction
        palette = random.choice(self.color_palettes)
        direction = random.choice(["vertical", "horizontal", "diagonal"])
        
        # Create gradient background
        img = self.create_gradient_background(palette, direction)
        
        # Add decorative elements
        img = self.add_decorative_elements(img)
        
        # Add text
        img = self.add_text_to_image(img, text)
        
        # Save image
        filename = f"tiktok_image_{index:03d}.png"
        filepath = os.path.join(self.output_dir, filename)
        img.save(filepath, "PNG", quality=95)
        
        return filepath
    
    def generate_batch(self, texts: List[str]) -> List[str]:
        """Generate multiple images from a list of texts.
        
        Args:
            texts: List of text strings
            
        Returns:
            List of file paths to generated images
        """
        filepaths = []
        for i, text in enumerate(texts):
            print(f"Generating image {i+1}/{len(texts)}: {text[:50]}...")
            filepath = self.generate_image(text, i)
            filepaths.append(filepath)
        
        print(f"\n✅ Generated {len(filepaths)} images in '{self.output_dir}' directory")
        return filepaths


def parse_texts(input_text: str) -> List[str]:
    """Parse input text that may contain numbered items or multi-line format.
    
    Handles formats like:
    - "1. Text here\n2. Another text"
    - Numbered lists with multi-line items
    - Plain text separated by newlines
    
    Args:
        input_text: Raw input text from user
        
    Returns:
        List of cleaned text strings
    """
    texts = []
    
    # Split by lines and process
    lines = input_text.strip().split('\n')
    current_text = []
    
    for line in lines:
        line = line.strip()
        if not line:
            # Empty line - if we have accumulated text, save it
            if current_text:
                texts.append('\n'.join(current_text))
                current_text = []
            continue
        
        # Check if line starts with a number pattern (e.g., "1.", "2.", "10.")
        match = re.match(r'^\d+[\.\)]\s*(.*)', line)
        if match:
            # If we have accumulated text from previous item, save it
            if current_text:
                texts.append('\n'.join(current_text))
            # Start new text with the matched content
            current_text = [match.group(1).strip()]
        else:
            # Continuation of current text (multi-line item)
            current_text.append(line)
    
    # Don't forget the last item
    if current_text:
        texts.append('\n'.join(current_text))
    
    # If no numbered format detected, treat each non-empty line as separate text
    if not texts:
        texts = [line.strip() for line in lines if line.strip()]
    
    # Clean up texts (remove extra whitespace, but preserve line breaks)
    cleaned_texts = []
    for text in texts:
        # Preserve intentional line breaks but clean up extra spaces
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        cleaned = '\n'.join(lines)
        if cleaned:
            cleaned_texts.append(cleaned)
    
    return cleaned_texts


def main():
    """Main function to run the generator."""
    import sys
    
    texts = []
    
    # Check if texts provided as command line arguments
    if len(sys.argv) > 1:
        # Join all arguments as a single text block and parse
        input_text = ' '.join(sys.argv[1:])
        texts = parse_texts(input_text)
        print(f"📝 Received {len(texts)} text(s) from command line arguments")
    else:
        # Interactive mode: get texts from user input
        print("=" * 60)
        print("🎬 TikTok Image Generator")
        print("=" * 60)
        print("\nYou can enter texts in two ways:")
        print("1. Paste all texts at once (with numbers like '1. text', '2. text', etc.)")
        print("2. Enter texts one by one")
        print("\nEnter your texts (paste all at once or one per line):")
        print("Press Enter twice (or Ctrl+D) when done.\n")
        
        input_lines = []
        empty_line_count = 0
        
        while True:
            try:
                line = input()
                if not line.strip():
                    empty_line_count += 1
                    if empty_line_count >= 2:
                        break
                else:
                    empty_line_count = 0
                    input_lines.append(line)
            except (EOFError, KeyboardInterrupt):
                print("\n")
                break
        
        if not input_lines:
            print("❌ No texts provided. Exiting.")
            return
        
        # Parse the input (handles both numbered format and plain text)
        input_text = '\n'.join(input_lines)
        texts = parse_texts(input_text)
        
        if not texts:
            print("❌ No valid texts found. Exiting.")
            return
    
    if not texts:
        print("❌ No texts to process. Exiting.")
        return
    
    print(f"\n📋 Processing {len(texts)} text(s)...\n")
    for i, text in enumerate(texts, 1):
        preview = text.replace('\n', ' ')[:50]
        print(f"  {i}. {preview}{'...' if len(text) > 50 else ''}")
    print()
    
    # Create generator
    generator = TikTokImageGenerator(output_dir="output")
    
    # Generate images
    generator.generate_batch(texts)


if __name__ == "__main__":
    main()

