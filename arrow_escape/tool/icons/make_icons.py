"""Renders the launcher icon (matches the in-app ArrowLogo) for Android and iOS.

Run from arrow_escape/: python3 tool/icons/make_icons.py
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
BG = (241, 234, 249)        # Palette.tileLight
ARROWS = [
    ((255, 159, 142), 0.22, "up"),     # peach
    ((124, 108, 242), 0.50, "right"),  # violet
    ((92, 201, 176), 0.78, "down"),    # mint
]


def render(size: int, rounded: bool) -> Image.Image:
    s = size * 4  # supersample
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=BG)
    else:
        d.rectangle([0, 0, s, s], fill=BG)  # iOS masks the corners itself
    w = int(s * 0.11)
    for color, at, direction in ARROWS:
        cx, cy = s * at, s * 0.5
        # Shaft + head, drawn pointing right then rotated by direction.
        shaft = [(-0.10, 0), (0.04, 0)]
        head = [(0.14, 0), (0.03, -0.09), (0.03, 0.09)]

        def tr(p):
            x, y = p
            if direction == "up":
                x, y = y, -x
            elif direction == "down":
                x, y = -y, x
            return (cx + x * s, cy + y * s)

        a, b = tr(shaft[0]), tr(shaft[1])
        d.line([a, b], fill=color, width=w)
        for end in (a, b):
            d.ellipse([end[0] - w / 2, end[1] - w / 2, end[0] + w / 2, end[1] + w / 2], fill=color)
        d.polygon([tr(p) for p in head], fill=color)
    return img.resize((size, size), Image.LANCZOS)


def main():
    android = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, px in android.items():
        out = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        render(px, rounded=True).save(out)
    iconset = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((iconset / "Contents.json").read_text())
    for image in contents["images"]:
        base = float(image["size"].split("x")[0])
        px = round(base * int(image["scale"][0]))
        # App Store icons must be opaque.
        render(px, rounded=False).convert("RGB").save(iconset / image["filename"])
    render(512, rounded=True).save(ROOT / "docs/icon_512.png")


if __name__ == "__main__":
    main()
