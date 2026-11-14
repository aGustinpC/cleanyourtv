"""Recorta cada imagen al centro en 16:9 y la guarda en 1920x1080 en escala de grises, como JPEG."""
import sys
from pathlib import Path
from PIL import Image

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
for f in sorted(src.glob("*.*")):
    im = Image.open(f).convert("RGB")
    w, h = im.size
    if w / h > 16 / 9:
        nw = round(h * 16 / 9)
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = round(w * 9 / 16)
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((1920, 1080), Image.LANCZOS).convert("L").convert("RGB")
    im.save(dst / (f.stem + ".jpg"), quality=90)
    print(f.name, "->", (dst / (f.stem + ".jpg")).name)
