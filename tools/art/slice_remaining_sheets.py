"""Slice the four owner-supplied 3x2 enemy sheets into transparent frames.

Column cuts are discovered from transparent pixel gutters in each row (the
effects sometimes cross the nominal thirds). Source frames are numbered
left-to-right, top-to-bottom; FRAME_MAP assigns those source indices to the
idle and attack animations.
"""
from __future__ import annotations

from collections import deque
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art_source" / "characters"
OUTPUT = ROOT / "assets" / "enemies"
CONTACT = ROOT / "build" / "slice_contact"
ALPHA_CUTOFF = 16
PAD = 3
MARGIN = 2

# These are source-frame indices, not destination ordinals. Images were
# visually reviewed: teal slash/orb frames are attacks; calm stances are idle.
SHEETS = {
    "old_swordsman": {
        "file": "old_swordsman_sheet.webp", "size_px": 64,
        "idle": [0, 1, 5], "attack": [2, 3, 4],
    },
    "shrine_spirit": {
        "file": "shrine_spirit_sheet.webp", "size_px": 64,
        "idle": [0, 1, 5], "attack": [2, 3, 4],
    },
    "thornback_boar": {
        "file": "thornback_boar_sheet.webp", "size_px": 64,
        "idle": [0, 1, 5], "attack": [2, 3, 4],
    },
    "veteran_hunter": {
        "file": "veteran_hunter_sheet.webp", "size_px": 64,
        "idle": [0, 3], "attack": [1, 2, 4, 5],
    },
}


def key_opaque_white_background(im: Image.Image) -> Image.Image:
    """Flood-fill edge-connected near-white pixels, preserving AA edges.

    Existing sheets have real alpha, so this is a no-op for them. It handles
    an opaque white export without keying white hair/beards inside the art.
    """
    rgba = im.convert("RGBA")
    alpha = rgba.getchannel("A")
    if alpha.getextrema() != (255, 255):
        return rgba
    w, h = rgba.size
    pixels = rgba.load()
    seen = bytearray(w * h)
    queue = deque()
    for x in range(w):
        queue.append((x, 0)); queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y)); queue.append((w - 1, y))
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, a = pixels[x, y]
        whiteness = min(r, g, b)
        if whiteness < 224 or max(r, g, b) - min(r, g, b) > 20:
            continue
        # Fully white edge pixels become transparent; near-white antialiasing
        # becomes partially transparent instead of leaving a pale fringe.
        pixels[x, y] = (r, g, b, round(a * max(0.0, (255 - whiteness) / 31.0)))
        if x: queue.append((x - 1, y))
        if x + 1 < w: queue.append((x + 1, y))
        if y: queue.append((x, y - 1))
        if y + 1 < h: queue.append((x, y + 1))
    return rgba


def projection(im: Image.Image, box: tuple[int, int, int, int], axis: int) -> list[int]:
    """Count art pixels above the alpha cutoff along one axis in a region."""
    x0, y0, x1, y1 = box
    alpha = im.getchannel("A")
    if axis == 0:
        return [sum(alpha.getpixel((x, y)) > ALPHA_CUTOFF for y in range(y0, y1))
                for x in range(x0, x1)]
    return [sum(alpha.getpixel((x, y)) > ALPHA_CUTOFF for x in range(x0, x1))
            for y in range(y0, y1)]


def zero_runs(values: list[int], offset: int) -> list[tuple[int, int]]:
    runs = []
    start = None
    for i, value in enumerate(values + [1]):
        if value == 0 and start is None:
            start = i
        elif value != 0 and start is not None:
            runs.append((offset + start, offset + i))
            start = None
    return runs


def find_column_cuts(im: Image.Image, row: int) -> list[int]:
    """Find actual empty gutters near nominal thirds, row by row."""
    w, h = im.size
    y0, y1 = round(row * h / 2), round((row + 1) * h / 2)
    cuts = [0]
    for third in (1, 2):
        nominal = round(third * w / 3)
        radius = max(35, round(w / 12))
        left, right = max(cuts[-1] + 1, nominal - radius), min(w, nominal + radius)
        profile = projection(im, (left, y0, right, y1), 0)
        runs = zero_runs(profile, left)
        if not runs:
            raise ValueError(f"no transparent gutter near x={nominal}, row={row}")
        # A gutter's midpoint is a safe cut; prefer the wider actual gap, then
        # the one closest to the nominal third. This is pixel-derived.
        a, b = min(runs, key=lambda run: (-(run[1] - run[0]), abs((run[0] + run[1]) / 2 - nominal)))
        cut = (a + b) // 2
        print(f"row {row} x-cut near {nominal}: transparent run [{a},{b}), cut={cut}")
        cuts.append(cut)
    cuts.append(w)
    return cuts


def find_row_cut(im: Image.Image) -> int:
    """Find the horizontal transparent gutter separating the two rows."""
    w, h = im.size
    nominal = round(h / 2)
    radius = max(40, round(h / 8))
    top, bottom = max(0, nominal - radius), min(h, nominal + radius)
    runs = zero_runs(projection(im, (0, top, w, bottom), 1), top)
    if not runs:
        raise ValueError("no transparent row gutter near the sheet midpoint")
    a, b = min(runs, key=lambda run: (-(run[1] - run[0]), abs((run[0] + run[1]) / 2 - nominal)))
    cut = (a + b) // 2
    print(f"y-cut near {nominal}: transparent run [{a},{b}), cut={cut}")
    return cut


def alpha_bbox(im: Image.Image):
    alpha = im.getchannel("A").point(lambda a: 255 if a > ALPHA_CUTOFF else 0)
    return alpha.getbbox()


def extract_source_frames(im: Image.Image) -> list[Image.Image]:
    w, h = im.size
    frames = []
    row_cut = find_row_cut(im)
    for row in range(2):
        y0, y1 = (0, row_cut) if row == 0 else (row_cut, h)
        xs = find_column_cuts(im, row)
        for col in range(3):
            cell = im.crop((xs[col], y0, xs[col + 1], y1))
            bb = alpha_bbox(cell)
            if bb is None:
                raise ValueError(f"empty frame at source row={row}, col={col}")
            x0, yy0, x1, yy1 = bb
            # Keep the original soft alpha; only discard negligible edge haze.
            crop_box = (max(0, x0 - PAD), max(0, yy0 - PAD),
                        min(cell.width, x1 + PAD), min(cell.height, yy1 + PAD))
            frames.append(cell.crop(crop_box))
            print(f"source_{row * 3 + col}: cell={(xs[col], y0, xs[col + 1], y1)} alpha_bbox={bb}")
    return frames


def align_frames(frames: list[Image.Image]) -> tuple[list[Image.Image], list[int], int]:
    """Common canvas; anchor every frame on alpha-mass x centre and baseline."""
    pieces = []
    max_half = 0.0
    max_h = 0
    for image in frames:
        alpha = image.getchannel("A")
        data = list(alpha.get_flattened_data() if hasattr(alpha, "get_flattened_data")
                    else alpha.getdata())
        mass = sum(data)
        if mass <= 0:
            raise ValueError("frame has no alpha mass")
        center = sum(x * data[y * image.width + x]
                     for y in range(image.height) for x in range(image.width)) / mass
        max_half = max(max_half, center, image.width - center)
        max_h = max(max_h, image.height)
        pieces.append((image, center))
    cw = int(max_half * 2 + 0.999) + 2 * MARGIN
    ch = max_h + 2 * MARGIN
    output = []
    for image, center in pieces:
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.alpha_composite(image, (round(cw / 2 - center), ch - MARGIN - image.height))
        output.append(canvas)
    return output, [cw, ch], ch - MARGIN - 1 - PAD


def checker(size: tuple[int, int]) -> Image.Image:
    out = Image.new("RGBA", size, (45, 45, 52, 255))
    draw = ImageDraw.Draw(out)
    for y in range(0, size[1], 12):
        for x in range(0, size[0], 12):
            if (x // 12 + y // 12) % 2:
                draw.rectangle((x, y, x + 11, y + 11), fill=(88, 88, 96, 255))
    return out


def write_contact(enemy_id: str, animations: dict[str, list[Image.Image]]) -> None:
    thumbs = [(f"{anim}_{i:02d}", image) for anim, items in animations.items()
              for i, image in enumerate(items)]
    tile_w, tile_h = 190, 220
    sheet = Image.new("RGBA", (tile_w * 6, tile_h * ((len(thumbs) + 5) // 6)), (32, 34, 40, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (name, image) in enumerate(thumbs):
        scale = min((tile_w - 12) / image.width, (tile_h - 24) / image.height)
        thumb = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale)),), Image.Resampling.LANCZOS)
        x, y = (i % 6) * tile_w, (i // 6) * tile_h
        tile = checker(thumb.size); tile.alpha_composite(thumb)
        sheet.alpha_composite(tile, (x + (tile_w - thumb.width) // 2, y + 3))
        draw.text((x + 4, y + tile_h - 17), name, fill="white")
    CONTACT.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT / f"{enemy_id}.png")


def main() -> None:
    manifest_path = OUTPUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for enemy_id, config in SHEETS.items():
        source_path = SOURCE / config["file"]
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        im = key_opaque_white_background(Image.open(source_path))
        source_frames = extract_source_frames(im)
        if len(source_frames) != 6:
            raise ValueError(f"{enemy_id}: expected six source frames, found {len(source_frames)}")
        (OUTPUT / enemy_id).mkdir(parents=True, exist_ok=True)
        animations = {}
        entry = {"animations": {}, "canvas": {}, "baseline": {},
                 "size_px": config["size_px"], "faces": "right", "variants": []}
        for animation in ("idle", "attack"):
            selected = [source_frames[i] for i in config[animation]]
            aligned, canvas_size, baseline = align_frames(selected)
            animations[animation] = aligned
            filenames = []
            for i, frame in enumerate(aligned):
                filename = f"{animation}_{i:02d}.png"
                frame.save(OUTPUT / enemy_id / filename)
                filenames.append(filename)
                alpha = frame.getchannel("A")
                if alpha.getpixel((0, 0)) != 0 or alpha.getpixel((frame.width - 1, frame.height - 1)) != 0:
                    raise ValueError(f"{enemy_id}/{filename}: canvas corner is not transparent")
            entry["animations"][animation] = filenames
            entry["canvas"][animation] = canvas_size
            entry["baseline"][animation] = baseline
            print(f"{enemy_id}/{animation}: source frames {config[animation]} -> {filenames}; canvas={canvas_size}, baseline={baseline}")
        for animation in ("hurt", "die"):
            entry["animations"][animation] = list(entry["animations"]["idle"])
            entry["canvas"][animation] = list(entry["canvas"]["idle"])
            entry["baseline"][animation] = entry["baseline"]["idle"]
        manifest[enemy_id] = entry
        write_contact(enemy_id, animations)
    with manifest_path.open("w", encoding="utf-8", newline="\n") as manifest_file:
        manifest_file.write(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"updated {manifest_path}")


if __name__ == "__main__":
    main()
