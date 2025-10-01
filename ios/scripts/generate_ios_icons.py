#!/usr/bin/env python3
"""
iOS App Icon Generator
Generates all required iOS app icon sizes from source PNG files
"""

import os
import sys
from PIL import Image

# Icon size mappings: (filename, target_size_px)
ICON_MAPPINGS = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

def find_best_source_image(logo_dir, target_size):
    """Find the best source image (closest size >= target size)"""
    available_sizes = [16, 24, 32, 48, 64, 72, 96, 120, 128, 144, 160, 192, 224, 240, 248, 256, 300, 320, 384, 512, 1024]
    
    # Find the smallest size that's >= target size
    for size in available_sizes:
        if size >= target_size:
            source_path = os.path.join(logo_dir, f"{size}x{size}.png")
            if os.path.exists(source_path):
                return source_path
    
    # Fallback to largest available
    return os.path.join(logo_dir, "1024x1024.png")

def generate_icon(source_path, output_path, target_size):
    """Resize and save icon"""
    try:
        img = Image.open(source_path)
        img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
        img.save(output_path, "PNG", optimize=True)
        print(f"✓ Generated: {os.path.basename(output_path)} ({target_size}x{target_size})")
        return True
    except Exception as e:
        print(f"✗ Failed to generate {os.path.basename(output_path)}: {e}")
        return False

def main():
    # Paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ios_dir = os.path.dirname(script_dir)
    flutter_project_root = os.path.dirname(ios_dir)
    workspace_root = os.path.dirname(flutter_project_root)
    logo_dir = os.path.join(workspace_root, "Logo", "logo")
    output_dir = os.path.join(ios_dir, "Runner", "Assets.xcassets", "AppIcon.appiconset")
    
    # Verify directories
    if not os.path.exists(logo_dir):
        print(f"Error: Logo directory not found: {logo_dir}")
        sys.exit(1)
    
    if not os.path.exists(output_dir):
        print(f"Error: Output directory not found: {output_dir}")
        sys.exit(1)
    
    print(f"Source: {logo_dir}")
    print(f"Output: {output_dir}")
    print("-" * 60)
    
    # Generate all icons
    success_count = 0
    for filename, target_size in ICON_MAPPINGS:
        source_path = find_best_source_image(logo_dir, target_size)
        output_path = os.path.join(output_dir, filename)
        
        if generate_icon(source_path, output_path, target_size):
            success_count += 1
    
    print("-" * 60)
    print(f"✓ Successfully generated {success_count}/{len(ICON_MAPPINGS)} icons")
    
    if success_count == len(ICON_MAPPINGS):
        print("✓ All iOS app icons generated successfully!")
        return 0
    else:
        print("✗ Some icons failed to generate")
        return 1

if __name__ == "__main__":
    sys.exit(main())
