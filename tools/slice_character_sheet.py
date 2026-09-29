"""Slice the supplied character sheets into transparent sprite assets.

The source sheets are JPEGs, so the slicer keys the measured dark background
by colour distance. Layout coordinates are per-sheet because the artwork was
exported with small vertical offsets. Character frames are taken from detected
foreground inside measured row/group slots; no fixed sprite size is assumed.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "characters" / "source"
OUT = ROOT / "assets" / "characters"
BG = (22, 27, 33)

# x group boundaries are the thin divider lines measured in the template.
# y bands are the foreground-only bands measured separately for each export.
CONFIG = {
    "archer": {
        "sheet": "archer_sheet.jpg", "idle_y": (70, 163), "walk_y": (268, 342),
        "run_y": (445, 520), "attack_y": (601, 698), "hurt_y": (800, 877),
        "dead_y": (800, 877), "dead_x": (500, 930),
        "portrait": (0, 0, 335, 560), "weapon": (30, 948, 220, 1165),
        "splash": (535, 970, 1254, 1254),
        "skills": [(540, 930, 610, 1015), (615, 930, 695, 1015),
                   (700, 930, 775, 1015), (780, 930, 860, 1015)],
    },
    "mage": {
        "sheet": "mage_sheet.jpg", "idle_y": (71, 178), "walk_y": (275, 351),
        "run_y": (445, 520), "attack_y": (580, 700), "hurt_y": (805, 876),
        "dead_y": (805, 876), "dead_x": (500, 940),
        "portrait": (0, 0, 335, 560), "weapon": (30, 948, 220, 1165),
        "splash": (535, 970, 1254, 1254),
        "skills": [(530, 925, 595, 1015), (595, 925, 660, 1015),
                   (660, 925, 725, 1015), (725, 925, 790, 1015),
                   (790, 925, 860, 1015)],
    },
    "swordsman": {
        "sheet": "swordsman_sheet.jpg", "idle_y": (74, 181), "walk_y": (291, 366),
        "run_y": (482, 556), "attack_y": (642, 741), "hurt_y": (848, 925),
        "dead_y": (848, 925), "dead_x": (500, 930),
        "portrait": (0, 0, 335, 560), "weapon": (30, 995, 220, 1175),
        "splash": (535, 940, 1254, 1254), "skills": [],
    },
}
GROUPS = (350, 555, 783, 1013, 1230)
ATTACK_GROUPS = (20, 325, 622, 952, 1235)
DIRECTIONS = ("down", "left", "right", "up")


def foreground_mask(source: Image.Image, tolerance: int = 32) -> Image.Image:
    """Return an alpha mask that removes JPEG background and its halo."""
    rgb = source.convert("RGB")
    mask = Image.new("L", rgb.size, 0)
    src = rgb.load()
    dst = mask.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = src[x, y]
            # max-channel distance preserves near-black pixel-art outlines.
            distance = max(abs(r - BG[0]), abs(g - BG[1]), abs(b - BG[2]))
            dst[x, y] = 255 if distance > tolerance else 0
    # The template dividers are foreground-coloured enough to survive the
    # key, but are not part of any sprite. Remove their narrow columns.
    for x in (554, 555, 556, 782, 783, 784, 1012, 1013, 1014,
              324, 325, 326, 621, 622, 623, 951, 952, 953):
        for y in range(240, 750):
            dst[x, y] = 0
    for y in (243, 244, 415, 416, 589, 590,
              249, 250, 418, 419, 584, 585, 586,
              262, 263, 451, 452, 623, 624):
        for x in range(345, 1230):
            dst[x, y] = 0
    return mask


def trim(source: Image.Image, mask: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = source.crop(box).convert("RGBA")
    alpha = mask.crop(box)
    bbox = alpha.getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    crop.putalpha(alpha)
    return crop.crop(bbox)


def slot_boxes(group_bounds: tuple[int, ...], y: tuple[int, int],
               counts: tuple[int, ...], overlap: int = 0):
    for group_index, (group_start, group_end) in enumerate(zip(group_bounds, group_bounds[1:])):
        count = counts[group_index]
        width = (group_end - group_start) / count
        for i in range(count):
            x0 = round(group_start + i * width) - overlap
            x1 = round(group_start + (i + 1) * width) + overlap
            yield (max(0, x0), y[0], min(1254, x1), y[1])


def normalize(frames: list[Image.Image], pad: int = 3):
    width = max(frame.width for frame in frames) + pad * 2
    height = max(frame.height for frame in frames) + pad * 2
    baseline = height - pad
    result = []
    for frame in frames:
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(frame, ((width - frame.width) // 2, baseline - frame.height))
        result.append(canvas)
    return result, [width, height], baseline


def contact(items: list[tuple[str, Image.Image]], path: Path) -> None:
    cell_w, cell_h, cols = 170, 135, 6
    sheet = Image.new("RGBA", (cols * cell_w, math.ceil(len(items) / cols) * cell_h), (38, 43, 50, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (name, image) in enumerate(items):
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        for yy in range(y, y + 105, 16):
            for xx in range(x, x + cell_w, 16):
                colour = (72, 77, 84) if ((xx - x) // 16 + (yy - y) // 16) % 2 else (48, 53, 60)
                draw.rectangle((xx, yy, xx + 16, yy + 16), fill=colour)
        scale = min(1, 105 / max(image.width, 1), 90 / max(image.height, 1))
        preview = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.NEAREST)
        sheet.alpha_composite(preview, (x + (cell_w - preview.width) // 2, y + (95 - preview.height) // 2))
        draw.text((x + 4, y + 108), name, fill=(235, 235, 235))
    sheet.convert("RGB").save(path)


def process(class_name: str, cfg: dict) -> dict:
    source = Image.open(SOURCE / cfg["sheet"]).convert("RGB")
    mask = foreground_mask(source)
    output = OUT / class_name
    output.mkdir(parents=True, exist_ok=True)
    # Avoid stale files if the sheet's frame layout changes between runs.
    for old in output.glob("*.png"):
        old.unlink()

    manifest = {"canvas": {}, "baseline": {},
                "fps": {"idle": 4, "walk": 10, "run": 10, "attack": 12, "hurt": 8, "dead": 6},
                "animations": {}, "skills": []}
    items: list[tuple[str, Image.Image]] = []

    def save(name: str, image: Image.Image) -> None:
        image.save(output / f"{name}.png")
        items.append((name, image))

    save("portrait", trim(source, mask, cfg["portrait"]))
    save("weapon", trim(source, mask, cfg["weapon"]))
    save("splash", trim(source, mask, cfg["splash"]))

    idle = [trim(source, mask, (x0, cfg["idle_y"][0], x1, cfg["idle_y"][1]))
            for x0, x1 in zip((350, 470, 595, 720), (470, 595, 720, 840))]
    idle, size, baseline = normalize(idle)
    manifest["animations"]["idle"] = []
    for direction, frame in zip(DIRECTIONS, idle):
        name = f"idle_{direction}"
        save(name, frame)
        manifest["animations"]["idle"].append(f"{name}.png")
    manifest["canvas"]["idle"] = size
    manifest["baseline"]["idle"] = baseline

    direction_counts = (4, 3, 3, 3)
    for animation, y_key, bounds, overlap in (("walk", "walk_y", GROUPS, 0), ("run", "run_y", GROUPS, 0)):
        raw = [trim(source, mask, box) for box in slot_boxes(bounds, cfg[y_key], direction_counts, overlap)]
        manifest["animations"][animation] = {direction: [] for direction in DIRECTIONS}
        offset = 0
        for di, direction in enumerate(DIRECTIONS):
            frame_count = direction_counts[di]
            frames, size, baseline = normalize(raw[offset:offset + frame_count])
            for i, frame in enumerate(frames):
                name = f"{animation}_{direction}_{i}"
                save(name, frame)
                manifest["animations"][animation][direction].append(f"{name}.png")
            manifest["canvas"][animation] = size
            manifest["baseline"][animation] = baseline
            offset += frame_count

    raw = [trim(source, mask, box) for box in slot_boxes(ATTACK_GROUPS, cfg["attack_y"], direction_counts, 0)]
    manifest["animations"]["attack"] = {direction: [] for direction in DIRECTIONS}
    offset = 0
    for di, direction in enumerate(DIRECTIONS):
        frame_count = direction_counts[di]
        frames, size, baseline = normalize(raw[offset:offset + frame_count])
        for i, frame in enumerate(frames):
            name = f"attack_{direction}_{i}"
            save(name, frame)
            manifest["animations"]["attack"][direction].append(f"{name}.png")
        manifest["canvas"]["attack"] = size
        manifest["baseline"]["attack"] = baseline
        offset += frame_count

    for animation, y_key, x_bounds, count in (("hurt", "hurt_y", (25, 430), 5),
                                                ("dead", "dead_y", cfg["dead_x"], 4)):
        x0, x1 = x_bounds
        if animation == "dead":
            dead_slots = (x0, 590, 700, 810, x1)
            raw = [trim(source, mask, (dead_slots[i], cfg[y_key][0],
                                       dead_slots[i + 1], cfg[y_key][1])) for i in range(count)]
        else:
            width = (x1 - x0) / count
            raw = [trim(source, mask, (round(x0 + i * width), cfg[y_key][0],
                                       round(x0 + (i + 1) * width), cfg[y_key][1])) for i in range(count)]
        frames, size, baseline = normalize(raw)
        manifest["animations"][animation] = []
        for i, frame in enumerate(frames):
            name = f"{animation}_{i}"
            save(name, frame)
            manifest["animations"][animation].append(f"{name}.png")
        manifest["canvas"][animation] = size
        manifest["baseline"][animation] = baseline

    for i, box in enumerate(cfg["skills"]):
        frame = trim(source, mask, box)
        if frame.width > 2 and frame.height > 2:
            name = f"skill_{i}"
            save(name, frame)
            manifest["skills"].append(f"{name}.png")

    contact(items, output / "_contact.png")
    return manifest


def main() -> None:
    all_manifest = {name: process(name, cfg) for name, cfg in CONFIG.items()}
    (OUT / "manifest.json").write_text(json.dumps(all_manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
