#!/usr/bin/env python3
"""
SpeedyOS boot artwork generator.

Creates the Plymouth boot splash (artwork/plymouth/speedyos/) and the GRUB
theme (artwork/grub/speedyos/) from the mascot badge. The text files that go
with them (speedyos.plymouth, theme.txt) are written here too, so the images
and the layout that uses them stay in one place.

Needs Pillow, Noto Sans (or DejaVu Sans) and grub-mkfont (grub package).
"""

import math
import os
import shutil
import subprocess

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
BADGE = os.path.join(HERE, "branding", "speedyos-badge.png")

BG = (26, 24, 22)            # #1a1816, same as the Welcome Center
AMBER = (224, 160, 96)       # #e0a060
BROWN = (201, 125, 62)       # #c97d3e
CREAM = (237, 229, 220)      # #ede5dc
MUTED = (201, 162, 126)      # #c9a27e
DIM = (138, 125, 112)        # #8a7d70
SS = 4                       # supersampling factor for smooth edges


def find_font(pattern):
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


def paw(size, color, angle=0):
    """A paw print (pad + four toes), pointing up, rotated by angle degrees."""
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rgba = color + (255,)
    # Main pad.
    d.ellipse([s * 0.22, s * 0.46, s * 0.78, s * 0.92], fill=rgba)
    # Toes on an arc above the pad.
    for cx, cy in ((0.17, 0.40), (0.37, 0.20), (0.63, 0.20), (0.83, 0.40)):
        r = s * 0.115
        d.ellipse([s * cx - r, s * cy - r * 1.25, s * cx + r, s * cy + r * 1.25], fill=rgba)
    im = im.rotate(angle, resample=Image.BICUBIC)
    return im.resize((size, size), Image.LANCZOS)


def badge(size):
    return Image.open(BADGE).convert("RGBA").resize((size, size), Image.LANCZOS)


def text_size(draw, text, font):
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0], box[3] - box[1], box


def centered_text(draw, y, width, text, font, fill):
    w, _, box = text_size(draw, text, font)
    draw.text(((width - w) / 2 - box[0], y - box[1]), text, font=font, fill=fill)


def rounded(size, radius, fill, outline=None, width=0):
    w, h = size
    im = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle(
        [0, 0, w * SS - 1, h * SS - 1], radius=radius * SS, fill=fill,
        outline=outline, width=width * SS)
    return im.resize((w, h), Image.LANCZOS)


# ------------------------------------------------------------------ plymouth

def plymouth(out):
    os.makedirs(out, exist_ok=True)

    # Watermark: badge, name and tagline, centered on the screen.
    w, h = 560, 400
    wm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b = badge(220)
    wm.alpha_composite(b, ((w - b.width) // 2, 0))
    d = ImageDraw.Draw(wm)
    centered_text(d, 248, w, "SpeedyOS", ImageFont.truetype(FONT_BOLD, 52), AMBER)
    centered_text(d, 326, w, "Fast Paws. Arch Power.", ImageFont.truetype(FONT_REGULAR, 22), MUTED)
    wm.save(os.path.join(out, "watermark.png"))

    # Throbber: a trail of paw prints walking to the right, on a loop.
    frames, steps, size, gap = 60, 7, 40, 62
    width, height = gap * (steps - 1) + size + 8, 96
    prints = [paw(size, BROWN, -90), paw(size, AMBER, -90)]
    for n in range(frames):
        front = n / frames * (steps + 3)
        im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        for i in range(steps):
            alpha = min(max(front - i, 0.0), 1.0)                  # step lands
            alpha *= min(max(1 - (front - i - 1) / 3, 0.0), 1.0)    # then fades
            if alpha <= 0:
                continue
            p = prints[i % 2].copy()
            p.putalpha(p.getchannel("A").point(lambda a, k=alpha: int(a * k)))
            y = 6 if i % 2 == 0 else height - size - 6               # left/right foot
            im.alpha_composite(p, (4 + i * gap, y))
        im.save(os.path.join(out, f"throbber-{n + 1:04d}.png"))

    # Password prompt pieces (used for encrypted disks).
    rounded((360, 44), 10, BG + (255,), outline=BROWN + (255,), width=2).save(
        os.path.join(out, "entry.png"))
    bullet = Image.new("RGBA", (14 * SS, 14 * SS), (0, 0, 0, 0))
    ImageDraw.Draw(bullet).ellipse([0, 0, 14 * SS - 1, 14 * SS - 1], fill=CREAM + (255,))
    bullet.resize((14, 14), Image.LANCZOS).save(os.path.join(out, "bullet.png"))
    lock = Image.new("RGBA", (32 * SS, 40 * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(lock)
    d.arc([6 * SS, 0, 26 * SS, 24 * SS], 180, 360, fill=AMBER + (255,), width=4 * SS)
    d.line([6 * SS + 2 * SS, 12 * SS, 6 * SS + 2 * SS, 18 * SS], fill=AMBER + (255,), width=4 * SS)
    d.line([24 * SS, 12 * SS, 24 * SS, 18 * SS], fill=AMBER + (255,), width=4 * SS)
    d.rounded_rectangle([0, 16 * SS, 32 * SS - 1, 40 * SS - 1], radius=5 * SS, fill=AMBER + (255,))
    lock.resize((32, 40), Image.LANCZOS).save(os.path.join(out, "lock.png"))

    with open(os.path.join(out, "speedyos.plymouth"), "w") as f:
        f.write(f"""[Plymouth Theme]
Name=SpeedyOS
Description=Speedy's paw prints walking across the boot screen
ModuleName=two-step

[two-step]
Font=Noto Sans 12
TitleFont=Noto Sans Light 30
MonospaceFont=Noto Sans Mono 12
ImageDir=/usr/share/plymouth/themes/speedyos
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.78
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.80
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.36
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x}
BackgroundEndColor=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x}
ProgressBarBackgroundColor=0x3d352e
ProgressBarForegroundColor=0x{BROWN[0]:02x}{BROWN[1]:02x}{BROWN[2]:02x}
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
UseEndAnimation=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing Updates...
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading System...
SubTitle=Do not turn off your computer
""")


# ---------------------------------------------------------------------- grub

GRUB_FONTS = [  # (file, ttf, size) -> GRUB font name "<family> <style> <size>"
    ("noto_sans_regular_16.pf2", FONT_REGULAR, 16),
    ("noto_sans_regular_20.pf2", FONT_REGULAR, 20),
    ("noto_sans_bold_24.pf2", FONT_BOLD, 24),
]


def grub(out):
    os.makedirs(out, exist_ok=True)
    w, h = 1920, 1080

    # Background: dark vertical gradient, badge and title at the top, a few
    # faint paw prints walking along the bottom edge.
    bg = Image.new("RGBA", (w, h))
    px = bg.load()
    top, bottom = (36, 31, 28), BG
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(w):
            px[x, y] = c
    b = badge(200)
    bg.alpha_composite(b, ((w - b.width) // 2, 90))
    d = ImageDraw.Draw(bg)
    centered_text(d, 318, w, "SpeedyOS", ImageFont.truetype(FONT_BOLD, 64), AMBER)
    centered_text(d, 410, w, "Fast Paws. Arch Power.", ImageFont.truetype(FONT_REGULAR, 26), MUTED)
    for i in range(10):
        p = paw(44, BROWN, -70)
        p.putalpha(p.getchannel("A").point(lambda a: a * 40 // 255))
        bg.alpha_composite(p, (90 + i * 180, 990 if i % 2 else 940))
    bg.convert("RGB").save(os.path.join(out, "background.png"))

    # Selected menu entry: a rounded amber box, cut into GRUB's 9 slices.
    r, box = 8, rounded((48, 48), 8, BROWN + (255,))
    slices = {
        "nw": (0, 0, r, r), "n": (r, 0, 48 - r, r), "ne": (48 - r, 0, 48, r),
        "w": (0, r, r, 48 - r), "c": (r, r, 48 - r, 48 - r), "e": (48 - r, r, 48, 48 - r),
        "sw": (0, 48 - r, r, 48), "s": (r, 48 - r, 48 - r, 48), "se": (48 - r, 48 - r, 48, 48),
    }
    for name, area in slices.items():
        box.crop(area).save(os.path.join(out, f"select_{name}.png"))

    for name, ttf, size in GRUB_FONTS:
        subprocess.run(["grub-mkfont", "-s", str(size), "-o", os.path.join(out, name), ttf],
                       check=True)

    with open(os.path.join(out, "theme.txt"), "w") as f:
        f.write("""# SpeedyOS GRUB theme (generated by artwork/generate-boot-art.py)
title-text: ""
desktop-image: "background.png"
desktop-color: "#1a1816"
desktop-image-scale-method: "crop"
terminal-font: "Unifont Regular 16"

+ boot_menu {
    left = 20%
    top = 47%
    width = 60%
    height = 36%
    item_font = "Noto Sans Regular 20"
    selected_item_font = "Noto Sans Bold 24"
    item_color = "#cfc4b8"
    selected_item_color = "#1a1816"
    selected_item_pixmap_style = "select_*.png"
    item_height = 42
    item_padding = 14
    item_spacing = 6
    icon_width = 0
    icon_height = 0
    scrollbar = false
}

+ label {
    id = "__timeout__"
    left = 0
    top = 86%
    width = 100%
    align = "center"
    font = "Noto Sans Regular 20"
    color = "#c9a27e"
    text = "Speedy starts in %d seconds"
}

+ label {
    left = 0
    top = 91%
    width = 100%
    align = "center"
    font = "Noto Sans Regular 16"
    color = "#8a7d70"
    text = "Enter: boot    Arrows: choose    E: edit    C: command line"
}
""")


def main():
    if not shutil.which("grub-mkfont"):
        raise SystemExit("grub-mkfont not found (grub package).")
    plymouth(os.path.join(HERE, "plymouth", "speedyos"))
    grub(os.path.join(HERE, "grub", "speedyos"))
    print("Boot artwork written to artwork/plymouth/ and artwork/grub/")


if __name__ == "__main__":
    main()
