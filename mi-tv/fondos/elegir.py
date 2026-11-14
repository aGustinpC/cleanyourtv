"""De cada carpeta extraída por RePKG, copia la imagen horizontal más grande como <id>.png."""
import shutil, sys
from pathlib import Path
from PIL import Image

raw, dst = Path(sys.argv[1]), Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
for d in sorted(p for p in raw.iterdir() if p.is_dir()):
    best = None
    for f in d.rglob("*"):
        if f.suffix.lower() not in (".png", ".jpg", ".jpeg"):
            continue
        try:
            w, h = Image.open(f).size
        except Exception:
            continue
        # Horizontal y grande primero; si no hay ninguna horizontal, la más grande.
        key = (w / h >= 1.3, w * h)
        if best is None or key > best[0]:
            best = (key, f, (w, h))
    if best:
        shutil.copy(best[1], dst / f"{d.name}{best[1].suffix.lower()}")
        print(d.name, best[2], best[1].name)
    else:
        print(d.name, "SIN IMAGEN")
