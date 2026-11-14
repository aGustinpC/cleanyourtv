"""Busca entre los wallpapers de Wallpaper Engine los que casi no tienen color y arma una hoja de contacto.

Uso: python -I -X utf8 buscar-byn.py "<carpeta workshop 431960>" hoja.jpg
"""
import json, sys
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(sys.argv[1])
out = Path(sys.argv[2])
rows = []
for d in sorted(root.iterdir()):
    prev = next((p for p in d.glob("preview.*")), None)
    if prev is None:
        continue
    try:
        im = Image.open(prev)
        im.seek(0)
        im = im.convert("RGB").resize((96, 54))
    except Exception:
        continue
    hsv = list(im.convert("HSV").getdata())
    # Píxeles con color apreciable: saturación alta y no casi negros.
    colored = sum(1 for h, s, v in hsv if s > 50 and v > 40) / len(hsv)
    title = ""
    pj = d / "project.json"
    if pj.exists():
        try:
            j = json.loads(pj.read_text(encoding="utf-8"))
            title = j.get("title", "")
        except Exception:
            pass
    rows.append((colored, d.name, title, prev))

rows.sort()
cands = [r for r in rows if r[0] < 0.06]
for c, ident, title, _ in cands:
    print(f"{c:.3f}\t{ident}\t{title}")

# Hoja de contacto de los candidatos, numerados.
w, h, cols = 320, 180, 6
sheet = Image.new("RGB", (cols * w, ((len(cands) + cols - 1) // cols) * (h + 20)), "white")
draw = ImageDraw.Draw(sheet)
for i, (c, ident, title, prev) in enumerate(cands):
    im = Image.open(prev)
    im.seek(0)
    im = im.convert("RGB").resize((w, h))
    x, y = (i % cols) * w, (i // cols) * (h + 20)
    sheet.paste(im, (x, y))
    draw.text((x + 4, y + h + 3), f"{i + 1}. {title[:40]}", fill="black")
sheet.save(out)
print(len(cands), "candidatos")
