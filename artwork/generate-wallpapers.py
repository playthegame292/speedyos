#!/usr/bin/env python3
"""
SpeedyOS Wallpaper Generator
Creates themed wallpapers featuring beagle elements
"""

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageFilter
import math
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))


def find_font(pattern):
    """Resolve a font file with fontconfig (e.g. 'Noto Sans:bold')."""
    for pat in (pattern, pattern.replace("Noto Sans", "DejaVu Sans")):
        try:
            path = subprocess.run(["fc-match", "-f", "%{file}", pat],
                                  capture_output=True, text=True, check=True).stdout
            if path.endswith((".ttf", ".otf")) and os.path.exists(path):
                return path
        except (OSError, subprocess.CalledProcessError):
            pass
    raise SystemExit(f"No usable font for {pattern!r}; install noto-fonts.")


FONT_BOLD = find_font("Noto Sans:bold")
FONT_REGULAR = find_font("Noto Sans")


def load_fonts(width, large, small):
    """Font sizes are given for 4K and scaled to the target width."""
    scale = width / 3840
    return (ImageFont.truetype(FONT_BOLD, max(12, int(large * scale))),
            ImageFont.truetype(FONT_REGULAR, max(10, int(small * scale))))

def create_gradient_background(width, height, colors):
    """Create a smooth gradient background"""
    base = Image.new('RGB', (width, height), colors[0])
    draw = ImageDraw.Draw(base)

    for i in range(height):
        ratio = i / height
        r = int(colors[0][0] * (1 - ratio) + colors[1][0] * ratio)
        g = int(colors[0][1] * (1 - ratio) + colors[1][1] * ratio)
        b = int(colors[0][2] * (1 - ratio) + colors[1][2] * ratio)
        draw.line([(0, i), (width, i)], fill=(r, g, b))

    return base

def draw_paw_print(draw, x, y, size, color, opacity=255):
    """Draw a stylized paw print"""
    # Main pad (largest circle)
    pad_size = size
    draw.ellipse([x - pad_size//2, y, x + pad_size//2, y + pad_size],
                 fill=color + (opacity,))

    # Four toe pads (smaller circles)
    toe_size = size // 3
    positions = [
        (x - size//2, y - size//2),  # Left
        (x - size//6, y - size*3//4),  # Center-left
        (x + size//6, y - size*3//4),  # Center-right
        (x + size//2, y - size//2),  # Right
    ]

    for px, py in positions:
        draw.ellipse([px - toe_size//2, py - toe_size//2,
                     px + toe_size//2, py + toe_size//2],
                    fill=color + (opacity,))

def create_speedy_wallpaper_dark(width=3840, height=2160):
    """Create dark theme wallpaper with modern geometric design"""

    # SpeedyOS color palette (inspired by beagle colors)
    brown_dark = (101, 67, 33)      # Deep brown
    brown_warm = (165, 113, 78)     # Warm brown
    cream = (245, 234, 215)         # Cream/tan
    blue_accent = (64, 128, 192)    # Complementary blue

    # Create gradient background (dark brown to darker)
    img = create_gradient_background(width, height,
                                    [(45, 35, 30), (25, 20, 18)])

    # Add overlay for depth
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Draw large decorative paw prints (subtle, background)
    paw_positions = [
        (width * 0.15, height * 0.25, 300, 30),
        (width * 0.85, height * 0.75, 350, 25),
        (width * 0.75, height * 0.20, 250, 35),
        (width * 0.25, height * 0.80, 280, 20),
    ]

    for x, y, size, opacity in paw_positions:
        draw_paw_print(draw, int(x), int(y), size, brown_warm, opacity)

    # Add geometric accent lines
    line_color = brown_warm + (40,)
    for i in range(5):
        y_pos = height * 0.2 + i * (height * 0.15)
        draw.line([(0, y_pos), (width * 0.3, y_pos)],
                 fill=line_color, width=3)

    # Merge overlay
    img = Image.alpha_composite(img.convert('RGBA'), overlay)

    # Add SpeedyOS logo text
    font_large, font_small = load_fonts(width, 120, 60)

    draw = ImageDraw.Draw(img)

    # Position text in lower third
    text_x = width // 2
    text_y = height * 0.75

    # Draw "SpeedyOS" with glow effect
    text = "SpeedyOS"

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (width - text_width) // 2

    # Glow effect
    for offset in range(10, 0, -2):
        opacity = 15 + offset * 2
        draw.text((text_x, text_y), text,
                 font=font_large, fill=brown_warm + (opacity,))

    # Main text
    draw.text((text_x, text_y), text,
             font=font_large, fill=cream + (255,))

    # Tagline
    tagline = "Fast Paws. Arch Power."
    bbox = draw.textbbox((0, 0), tagline, font=font_small)
    tagline_width = bbox[2] - bbox[0]
    tagline_x = (width - tagline_width) // 2

    draw.text((tagline_x, text_y + 140 * height // 2160), tagline,
             font=font_small, fill=cream + (180,))

    return img.convert('RGB')

def create_speedy_wallpaper_light(width=3840, height=2160):
    """Create light theme wallpaper"""

    # Light color palette
    cream_light = (252, 248, 240)
    brown_soft = (200, 165, 140)
    brown_medium = (140, 100, 70)
    blue_soft = (180, 210, 230)

    # Create gradient background
    img = create_gradient_background(width, height,
                                    [cream_light, (240, 235, 225)])

    overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Paw prints (more visible in light theme)
    paw_positions = [
        (width * 0.10, height * 0.20, 280, 60),
        (width * 0.88, height * 0.75, 320, 50),
        (width * 0.78, height * 0.15, 240, 65),
        (width * 0.20, height * 0.85, 260, 55),
        (width * 0.50, height * 0.40, 200, 40),
    ]

    for x, y, size, opacity in paw_positions:
        draw_paw_print(draw, int(x), int(y), size, brown_soft, opacity)

    img = Image.alpha_composite(img.convert('RGBA'), overlay)

    # Add text
    font_large, font_small = load_fonts(width, 120, 60)

    draw = ImageDraw.Draw(img)

    text_x = width // 2
    text_y = height * 0.70

    text = "SpeedyOS"
    bbox = draw.textbbox((0, 0), text, font=font_large)
    text_width = bbox[2] - bbox[0]
    text_x = (width - text_width) // 2

    # Shadow
    draw.text((text_x + 4, text_y + 4), text,
             font=font_large, fill=(0, 0, 0, 60))

    # Main text
    draw.text((text_x, text_y), text,
             font=font_large, fill=brown_medium + (255,))

    # Tagline
    tagline = "Fast Paws. Arch Power."
    bbox = draw.textbbox((0, 0), tagline, font=font_small)
    tagline_width = bbox[2] - bbox[0]
    tagline_x = (width - tagline_width) // 2

    draw.text((tagline_x, text_y + 140 * height // 2160), tagline,
             font=font_small, fill=brown_medium + (200,))

    return img.convert('RGB')

def create_minimal_wallpaper(width=3840, height=2160):
    """Create minimal/clean wallpaper with just subtle paw"""

    # Minimal color scheme
    bg_color = (35, 35, 38)  # Dark gray
    accent_color = (165, 113, 78)  # Warm brown

    img = Image.new('RGB', (width, height), bg_color)
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Single large, very subtle paw print in corner
    draw_paw_print(draw, width - 400, height - 400, 600, accent_color, 15)

    img = Image.alpha_composite(img.convert('RGBA'), overlay)

    return img.convert('RGB')

def make_badge(photo_path, size):
    """Circular mascot badge: the beagle photo on a cream disc with a
    warm-brown ring. Used for the wallpaper and the logo/icon set."""
    ss = 4  # supersample for smooth edges
    big = size * ss
    photo = Image.open(photo_path).convert('RGBA')
    # Square crop centred on the face (the photo is a cutout of a sleeping
    # puppy; its head sits in the lower-right part of the frame).
    side = min(photo.size)
    cx, cy = int(photo.width * 0.56), int(photo.height * 0.55)
    half = int(side * 0.47)
    box = (max(0, cx - half), max(0, cy - half), min(photo.width, cx + half), min(photo.height, cy + half))
    photo = photo.crop(box).resize((big, big), Image.Resampling.LANCZOS)

    disc = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(disc).ellipse([0, 0, big - 1, big - 1], fill=(245, 234, 215, 255))
    disc.alpha_composite(photo)

    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, big - 1, big - 1], fill=255)
    disc.putalpha(ImageChops.multiply(disc.getchannel('A'), mask))

    ring = int(big * 0.035)
    ImageDraw.Draw(disc).ellipse([0, 0, big - 1, big - 1], outline=(140, 90, 50, 255), width=ring)
    return disc.resize((size, size), Image.Resampling.LANCZOS)


def create_photo_integrated_wallpaper(photo_path, width=3840, height=2160):
    """Create wallpaper integrating baby Speedy's photo"""

    # Create gradient background
    brown_dark = (45, 35, 30)
    brown_warm = (85, 65, 50)

    img = create_gradient_background(width, height, [brown_dark, brown_warm])

    try:
        badge = make_badge(photo_path, height // 2)
        bw = badge.width
        # Keep clear of the edges: 16:10 screens crop ~5% off each side.
        photo_x = int(width * 0.24) - bw // 2
        photo_y = height // 2 - bw // 2

        # Soft warm glow behind the badge
        glow = Image.new('RGBA', (bw + bw // 5, bw + bw // 5), (0, 0, 0, 0))
        ImageDraw.Draw(glow).ellipse([bw // 10, bw // 10, bw + bw // 10, bw + bw // 10],
                                     fill=(201, 125, 62, 90))
        glow = glow.filter(ImageFilter.GaussianBlur(bw // 14))
        img = img.convert('RGBA')
        img.alpha_composite(glow, (photo_x - bw // 10, photo_y - bw // 10))
        img.alpha_composite(badge, (photo_x, photo_y))

    except Exception as e:
        print(f"Could not load photo: {e}")

    # Add text on right side
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Add decorative paw prints
    cream = (245, 234, 215)
    paw = int(width * 0.039)
    for i in range(3):
        y_offset = height * 0.22 + i * paw * 2.6
        draw_paw_print(draw, int(width * 0.86), int(y_offset), paw, cream, 40 + i * 15)

    img = Image.alpha_composite(img.convert('RGBA'), overlay)

    # Add text
    font_large, font_small = load_fonts(width, 140, 70)

    draw = ImageDraw.Draw(img)

    # Text on right side
    text_x = width * 0.62
    text_y = height * 0.40

    cream = (245, 234, 215)

    draw.text((text_x, text_y), "SpeedyOS",
             font=font_large, fill=cream + (255,))

    step = height / 2160
    draw.text((text_x, text_y + 180 * step), "Fast Paws.",
             font=font_small, fill=cream + (200,))
    draw.text((text_x, text_y + 270 * step), "Arch Power.",
             font=font_small, fill=cream + (200,))

    return img.convert('RGB')

if __name__ == "__main__":
    output_dir = os.path.join(HERE, "wallpapers")
    os.makedirs(output_dir, exist_ok=True)

    print("🐾 Generating SpeedyOS Wallpapers...")
    print()

    # 4K resolution
    width, height = 3840, 2160

    # Also generate 1080p versions
    width_1080p, height_1080p = 1920, 1080

    print("Creating dark theme wallpaper (4K)...")
    wall_dark = create_speedy_wallpaper_dark(width, height)
    wall_dark.save(f"{output_dir}/speedyos-dark-4k.png", quality=95)

    print("Creating dark theme wallpaper (1080p)...")
    wall_dark_1080 = create_speedy_wallpaper_dark(width_1080p, height_1080p)
    wall_dark_1080.save(f"{output_dir}/speedyos-dark-1080p.png", quality=95)

    print("Creating light theme wallpaper (4K)...")
    wall_light = create_speedy_wallpaper_light(width, height)
    wall_light.save(f"{output_dir}/speedyos-light-4k.png", quality=95)

    print("Creating light theme wallpaper (1080p)...")
    wall_light_1080 = create_speedy_wallpaper_light(width_1080p, height_1080p)
    wall_light_1080.save(f"{output_dir}/speedyos-light-1080p.png", quality=95)

    print("Creating minimal wallpaper (4K)...")
    wall_minimal = create_minimal_wallpaper(width, height)
    wall_minimal.save(f"{output_dir}/speedyos-minimal-4k.png", quality=95)

    print("Creating minimal wallpaper (1080p)...")
    wall_minimal_1080 = create_minimal_wallpaper(width_1080p, height_1080p)
    wall_minimal_1080.save(f"{output_dir}/speedyos-minimal-1080p.png", quality=95)

    # Try to create photo-integrated version
    photo_path = os.path.join(HERE, "branding", "speedylogo.png")
    if os.path.exists(photo_path):
        print("Creating photo-integrated wallpaper (4K)...")
        wall_photo = create_photo_integrated_wallpaper(photo_path, width, height)
        wall_photo.save(f"{output_dir}/speedyos-speedy-4k.png", quality=95)

        print("Creating photo-integrated wallpaper (1080p)...")
        wall_photo_1080 = create_photo_integrated_wallpaper(photo_path, width_1080p, height_1080p)
        wall_photo_1080.save(f"{output_dir}/speedyos-speedy-1080p.png", quality=95)

        # Square app/distro icons from the same badge (hicolor sizes).
        icon_dir = os.path.join(HERE, "icons", "hicolor")
        for size in (16, 22, 24, 32, 48, 64, 128, 256, 512):
            d = os.path.join(icon_dir, f"{size}x{size}", "apps")
            os.makedirs(d, exist_ok=True)
            make_badge(photo_path, size).save(os.path.join(d, "speedyos.png"))
        make_badge(photo_path, 1024).save(os.path.join(HERE, "branding", "speedyos-badge.png"))
        print("Created badge icons in artwork/icons/hicolor and branding/speedyos-badge.png")

    print()
    print("✓ Wallpapers generated successfully!")
    print(f"  Location: {output_dir}")
    print()
    print("Wallpapers created:")
    for f in sorted(os.listdir(output_dir)):
        if f.endswith('.png'):
            size = os.path.getsize(f"{output_dir}/{f}") / 1024 / 1024
            print(f"  🐾 {f} ({size:.1f} MB)")
