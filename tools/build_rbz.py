"""Packs src/ into dist/fog_<version>.rbz (a zip SketchUp installs via Extension Manager)."""
import pathlib
import re
import zipfile

root = pathlib.Path(__file__).resolve().parent.parent
src = root / 'src'
version = re.search(r"ex\.version\s*=\s*'([^']+)'", (src / 'fog.rb').read_text(encoding='utf-8')).group(1)
dist = root / 'dist'
dist.mkdir(exist_ok=True)
out = dist / f'fog_{version}.rbz'

with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for path in sorted(src.rglob('*')):
        if path.is_file():
            z.write(path, path.relative_to(src).as_posix())

print(out)
