"""Slice the owner's v2 hero sheets into transparent sprite assets.

Sources: art_source/heroes/<class>_sheet_v2.webp (1536x1024, never edited).
Output:  assets/heroes/<class>/*.png and assets/heroes/manifest.json.
Contact sheets for review: build/slice_contact/<class>.png.

Every sheet shares one template: four labelled rows on the right half
(Player, Idle, Walk, Run) split into Down/Left/Right/Up groups, a full-width
Attack row, a lower band with Jump/Hurt/Dead, and Weapon / Skill boxes.
The y-bands, x-ranges and attack cut columns below were measured by looking
at each sheet (per-sheet config, not layout detection). Inside a band the
foreground is keyed by colour distance from the band's flat background,
split into frames, and every animation must yield exactly the frame count
read off the sheet or the script exits non-zero without writing anything.

Pillow only.  Run:  python tools/art/slice_character_sheet.py
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art_source" / "heroes"
OUT = ROOT / "assets" / "heroes"
CONTACT = ROOT / "build" / "slice_contact"

MASK_T = 20        # colour distance that counts as solid foreground
ALPHA_LO = 6       # at or below this distance a pixel is background (alpha 0)
ALPHA_HI = 18      # at or above this distance a pixel next to drawn art is fully opaque
HAZE_HI = 60       # glow haze further than 2px from such pixels is opaque only from here
MARGIN = 2         # transparent margin around every animation canvas
DIRECTIONS = ("down", "left", "right", "up")
FPS = {"idle": 4, "walk": 10, "run": 10, "attack": 12, "jump": 10, "hurt": 8, "dead": 6}

# Frames per direction group in the four upper rows (read off the sheets).
ROW_COUNTS = {
    "idle": {"down": 4, "left": 4, "right": 4, "up": 3},
    "walk": {"down": 4, "left": 4, "right": 4, "up": 3},
    "run": {"down": 4, "left": 3, "right": 4, "up": 3},
}
# Direction groups (between the thin vertical dividers) shared by all sheets.
GROUPS = {"down": (482, 757), "left": (766, 1002), "right": (1012, 1262), "up": (1275, 1512)}

CONFIG = {
    "archer": {
        "rows": {"idle": (181, 264), "walk": (306, 392), "run": (444, 531)},
        # 12 shots; arrows and their glow belong to the body on their left.
        "attack": {"box": (24, 588, 1512, 688), "text_y": 683,
                   "cuts": [132, 200, 275, 382, 503, 618, 798, 908, 1041, 1191, 1350]},
        "jump": {"box": (24, 719, 405, 806), "cuts": [145, 283]},
        "hurt": {"box": (420, 719, 775, 806), "count": 4},
        "dead": {"box": (790, 719, 1106, 806), "count": 3},
        "portrait": (130, 82, 390, 342),
        "weapon": (30, 845, 262, 995),
        "skills": {"box": (524, 846, 1092, 926), "count": 7},
    },
    "assassin": {
        "rows": {"idle": (181, 264), "walk": (306, 390), "run": (444, 529)},
        # Groups of 3/3/3/2 split by dividers; slashes attach to the body on their left.
        "attack": {"box": (24, 588, 1512, 688), "text_y": 683,
                   "cuts": [128, 243, 405, 500, 604, 754, 850, 1001, 1175, 1263]},
        "jump": {"box": (24, 719, 412, 806), "cuts": [118, 258]},
        "hurt": {"box": (425, 719, 748, 806), "count": 4},
        "dead": {"box": (762, 719, 1058, 806), "count": 3},
        "portrait": (145, 84, 395, 334),
        "weapon": (30, 845, 262, 995),
        "skills": {"box": (538, 846, 1068, 926), "count": 6},
    },
    "guardian": {
        "rows": {"idle": (181, 263), "walk": (306, 390), "run": (444, 529)},
        # The big art's cape reaches x=487 beside the Walk row.
        "group_x": {("walk", "down"): (489, 757)},
        "attack": {"box": (24, 586, 1512, 688), "text_y": 683,
                   "cuts": [170, 308, 495, 611, 740, 910, 1033, 1148, 1262]},
        "jump": {"box": (22, 719, 410, 806), "cuts": [116, 214]},
        "hurt": {"box": (425, 719, 762, 806), "count": 4},
        "dead": {"box": (776, 719, 1078, 806), "count": 3},
        "portrait": (70, 88, 330, 348),
        "weapon": (30, 845, 262, 995),
        "skills": {"box": (543, 846, 1072, 926), "count": 6},
    },
    "mage": {
        "rows": {"idle": (181, 265), "walk": (306, 390), "run": (444, 531)},
        # Orbs, bolts and circles float to the right of the casting body.
        "attack": {"box": (22, 589, 1512, 688), "text_y": 683,
                   "cuts": [163, 302, 486, 562, 723, 810, 890, 1101, 1262]},
        "jump": {"box": (22, 719, 385, 806), "cuts": [127, 241]},
        "hurt": {"box": (400, 719, 772, 806), "count": 5},
        # The sheet shows a fourth, translucent standing "ghost" after the three
        # lying frames (x ~1040-1100); it is left out so the held last frame lies down.
        "dead": {"box": (785, 719, 1036, 806), "count": 3},
        "portrait": (110, 90, 390, 370),
        "weapon": (30, 845, 236, 995),
        "skills": {"box": (498, 846, 1072, 926), "count": 7},
    },
    "swordsman": {
        "rows": {"idle": (181, 264), "walk": (306, 390), "run": (444, 530)},
        # Blue sparks of the big art reach x=483 beside the Run row.
        "group_x": {("run", "down"): (484, 757)},
        # Attack row is grouped Down/Left/Right/Up; the game uses the Right group.
        # The "Right" caption sits under the frames (y >= 675) and is dropped.
        "attack": {"box": (757, 586, 1097, 688), "cuts": [855, 922], "text_y": 675},
        "jump": {"box": (22, 719, 393, 806), "cuts": [110, 255]},
        "hurt": {"box": (405, 719, 728, 806), "count": 4},
        "dead": {"box": (742, 719, 1085, 797), "count": 3},
        "portrait": (140, 80, 400, 340),
        "weapon": (30, 845, 252, 995),
        "skills": {"box": (538, 846, 1068, 926), "count": 6},
    },
}


class SliceError(Exception):
    pass


# --------------------------------------------------------------------------- keying

class Band:
    """A keyed rectangle of a sheet: colour distance, solid mask, components."""

    def __init__(self, sheet: Image.Image, box: tuple[int, int, int, int], text_y: int | None = None):
        self.box = box
        self.x0, self.y0, x1, y1 = box
        self.w, self.h = x1 - self.x0, y1 - self.y0
        self.rgb = sheet.crop(box)
        self.bg = _band_background(self.rgb)
        solid = Image.new("RGB", self.rgb.size, self.bg)
        r, g, b = ImageChops.difference(self.rgb, solid).split()
        self.dist = list(ImageChops.lighter(ImageChops.lighter(r, g), b).get_flattened_data())
        self.pix = list(self.rgb.get_flattened_data())
        self.mask = bytearray(1 if d > MASK_T else 0 for d in self.dist)
        self._remove_divider_lines()
        self.components = self._label(text_y)

    def _remove_divider_lines(self) -> None:
        """Clear thin full-height vertical and full-width horizontal dividers."""
        w, h, m = self.w, self.h, self.mask
        cols = [sum(m[y * w + x] for y in range(h)) for x in range(w)]
        for x in range(w):
            if cols[x] >= 0.75 * h:
                side = [cols[i] for i in (x - 3, x + 3) if 0 <= i < w]
                if side and max(side) < 0.4 * h:
                    for y in range(h):
                        m[y * w + x] = 0
        rows = [sum(m[y * w: (y + 1) * w]) for y in range(h)]
        for y in range(h):
            if rows[y] >= 0.8 * w and w > 120:
                side = [rows[i] for i in (y - 3, y + 3) if 0 <= i < h]
                if side and max(side) < 0.3 * w:
                    for x in range(w):
                        m[y * w + x] = 0

    def _label(self, text_y: int | None) -> list[dict]:
        w, h, m = self.w, self.h, self.mask
        seen = bytearray(w * h)
        comps = []
        for start in range(w * h):
            if not m[start] or seen[start]:
                continue
            seen[start] = 1
            stack, pixels = [start], []
            while stack:
                p = stack.pop()
                pixels.append(p)
                px, py = p % w, p // w
                for dy in (-1, 0, 1):
                    ny = py + dy
                    if ny < 0 or ny >= h:
                        continue
                    for dx in (-1, 0, 1):
                        nx = px + dx
                        if 0 <= nx < w:
                            q = ny * w + nx
                            if m[q] and not seen[q]:
                                seen[q] = 1
                                stack.append(q)
            if len(pixels) < 3:
                continue
            xs = [p % w for p in pixels]
            ys = [p // w for p in pixels]
            comp = {"pixels": pixels, "x0": min(xs) + self.x0, "x1": max(xs) + 1 + self.x0,
                    "y0": min(ys) + self.y0, "y1": max(ys) + 1 + self.y0,
                    "cx": sum(xs) / len(xs) + self.x0}
            if text_y is not None and comp["y0"] >= text_y:
                continue  # caption under the frames
            comps.append(comp)
        return comps

    def column_counts(self) -> list[int]:
        w, h, m = self.w, self.h, self.mask
        counts = [0] * w
        for c in self.components:
            for p in c["pixels"]:
                counts[p % w] += 1
        return counts


def _band_background(rgb: Image.Image) -> tuple[int, int, int]:
    w, h = rgb.size
    samples = [rgb.getpixel((x, y)) for y in (0, 1, h - 2, h - 1) for x in range(0, w, 3)]
    samples += [rgb.getpixel((x, y)) for x in (0, w - 1) for y in range(0, h, 3)]
    return tuple(sorted(s[i] for s in samples)[len(samples) // 2] for i in range(3))


# --------------------------------------------------------------------------- frames

def split_by_gaps(band: Band, count: int, what: str) -> list[list[dict]]:
    """Group components into frames by empty columns; split merged frames at the
    emptiest column until `count` frames exist. Fails if the count is not met."""
    comps = sorted(band.components, key=lambda c: c["x0"])
    clusters: list[list[dict]] = []
    for c in comps:
        if clusters and c["x0"] <= max(k["x1"] for k in clusters[-1]) + 2:
            clusters[-1].append(c)
        else:
            clusters.append([c])
    clusters = [k for k in clusters if sum(len(c["pixels"]) for c in k) >= 150]
    counts = band.column_counts()
    for _ in range(count):
        if len(clusters) >= count:
            break
        widths = sorted(_span(k)[1] - _span(k)[0] for k in clusters)
        typical = widths[0] if widths else 55
        typical = max(40, min(typical, 64))
        widest = max(clusters, key=lambda k: _span(k)[1] - _span(k)[0])
        x0, x1 = _span(widest)
        pieces = min(count - len(clusters) + 1, max(2, round((x1 - x0) / typical)))
        cuts = [_refine_cut(counts, band.x0, x0 + (x1 - x0) * i / pieces, 10) for i in range(1, pieces)]
        idx = clusters.index(widest)
        clusters[idx:idx + 1] = _assign(widest, [x0] + cuts + [x1], band)
    if len(clusters) != count:
        spans = [_span(k) for k in clusters]
        raise SliceError(f"{what}: expected {count} frames, found {len(clusters)} at x-spans {spans}")
    return clusters


def split_by_cuts(band: Band, cuts: list[int], what: str) -> list[list[dict]]:
    counts = band.column_counts()
    refined = [_refine_cut(counts, band.x0, c, 8) for c in cuts]
    frames = _assign(band.components, [band.x0] + refined + [band.x0 + band.w], band)
    for i, frame in enumerate(frames):
        if not frame or _body(frame) is None:
            raise SliceError(f"{what}: slot {i} ({refined}) has no character body")
    return frames


def _refine_cut(counts: list[int], x_origin: int, nominal: float, window: int) -> int:
    lo = max(0, int(nominal) - window - x_origin)
    hi = min(len(counts) - 1, int(nominal) + window - x_origin)
    best = min(range(lo, hi + 1), key=lambda i: (counts[i], abs(i + x_origin - nominal)))
    return best + x_origin


def _assign(comps: list[dict], edges: list[int], band: Band) -> list[list[dict]]:
    """Give each component to the slot holding its centroid; a component that
    bridges two slots (large share on both sides of a cut) is split at the cut."""
    slots: list[list[dict]] = [[] for _ in range(len(edges) - 1)]
    for c in comps:
        for piece in _split_bridge(c, edges, band):
            k = max(0, min(len(slots) - 1, sum(1 for e in edges[1:-1] if piece["cx"] >= e)))
            slots[k].append(piece)
    return slots


def _split_bridge(c: dict, edges: list[int], band: Band) -> list[dict]:
    inner = [e for e in edges[1:-1] if c["x0"] < e < c["x1"]]
    if not inner:
        return [c]
    parts: dict[int, list[int]] = {}
    for p in c["pixels"]:
        x = p % band.w + band.x0
        parts.setdefault(sum(1 for e in inner if x >= e), []).append(p)
    big = [k for k, v in parts.items() if len(v) >= 0.12 * len(c["pixels"]) and len(v) >= 40]
    if len(big) < 2:
        return [c]
    out = []
    for pixels in parts.values():
        xs = [p % band.w for p in pixels]
        ys = [p // band.w for p in pixels]
        out.append({"pixels": pixels, "x0": min(xs) + band.x0, "x1": max(xs) + 1 + band.x0,
                    "y0": min(ys) + band.y0, "y1": max(ys) + 1 + band.y0,
                    "cx": sum(xs) / len(xs) + band.x0})
    return out


def _span(frame: list[dict]) -> tuple[int, int]:
    return min(c["x0"] for c in frame), max(c["x1"] for c in frame)


def _body(frame: list[dict]) -> dict | None:
    """The character body: the largest component plus the sizeable pieces that
    overlap it (dark armour seams can split one sprite into several pieces).
    None unless the result is tall and dense enough to be a character."""
    if not frame:
        return None
    core = max(frame, key=lambda c: len(c["pixels"]))
    parts = [c for c in frame if c is core or (len(c["pixels"]) >= 60
             and c["x0"] < core["x1"] + 5 and c["x1"] > core["x0"] - 5
             and c["y0"] < core["y1"] + 5 and c["y1"] > core["y0"] - 5)]
    body = {"core": core, "pixels": [p for c in parts for p in c["pixels"]],
            "x0": min(c["x0"] for c in parts), "x1": max(c["x1"] for c in parts),
            "y0": min(c["y0"] for c in parts), "y1": max(c["y1"] for c in parts)}
    if body["y1"] - body["y0"] < 20 or len(body["pixels"]) < 250:
        return None
    return body


class Frame:
    """One cut frame in sheet coordinates: RGBA image, body anchor x, feet y."""

    def __init__(self, band: Band, comps: list[dict], lying: bool = False):
        body = _body(comps)
        if body is None:
            raise SliceError(f"frame without a body in band {band.box}: comps {[(c['x0'], c['y0'], c['x1'], c['y1'], len(c['pixels'])) for c in comps]}")
        w = band.w
        owned = set()
        for c in comps:
            owned.update(c["pixels"])
        xs = [p % w for p in owned]
        ys = [p // w for p in owned]
        # Grow by 2px so the soft (sub-threshold) fringe around the solid pixels is kept.
        fx0, fx1 = max(0, min(xs) - 2), min(w, max(xs) + 3)
        fy0, fy1 = max(0, min(ys) - 2), min(band.h, max(ys) + 3)
        self.x0, self.y0 = fx0 + band.x0, fy0 + band.y0
        img = Image.new("RGBA", (fx1 - fx0, fy1 - fy0), (0, 0, 0, 0))
        near = _dilate(owned, w, band.h, 2)
        holes, dim = _pockets(band, owned, fx0, fy0, fx1, fy1)
        strong = {p for p in owned if band.dist[p] >= HAZE_HI}
        near_strong = _dilate(strong, w, band.h, 2)
        bg = band.bg
        put = img.load()
        for p in near | holes | dim:
            x, y = p % w, p // w
            if not (fx0 <= x < fx1 and fy0 <= y < fy1):
                continue
            d = band.dist[p]
            if p in holes:
                a = 1.0
            elif p not in owned and d > MASK_T:
                continue  # solid pixels of other frames, dividers and captions
            else:
                # Alpha follows the distance from the flat background, so soft
                # glows, drop shadows and near-background dark cloth fade out
                # instead of carrying a band of background colour.
                # Faint haze away from any clearly drawn pixel (the dark aura
                # around orbs and slashes) fades over a wider range.
                hi = ALPHA_HI if p in near_strong else HAZE_HI
                a = min(1.0, (d - ALPHA_LO) / (hi - ALPHA_LO))
                if a <= 0:
                    continue
            c = band.pix[p]
            if a < 1.0:  # un-blend the flat background out of soft edges and glows
                c = tuple(max(0, min(255, round(bg[i] + (c[i] - bg[i]) / a))) for i in range(3))
            put[x - fx0, y - fy0] = (c[0], c[1], c[2], round(a * 255))
        self.image = img
        self.feet = body["y1"] - 1
        if lying:
            self.anchor = (body["x0"] + body["x1"]) / 2
        else:
            # The torso is the densest 24px-wide column strip of the body; bows,
            # blades and glows reaching sideways are thin by comparison and
            # must not shift where the character stands.
            cols: dict[int, int] = {}
            for p in body["core"]["pixels"]:
                cols[p % w] = cols.get(p % w, 0) + 1
            lo, hi = min(cols), max(cols)
            strip = 24
            best, best_x = -1, lo
            for x in range(lo, max(lo, hi - strip + 1) + 1):
                s = sum(cols.get(i, 0) for i in range(x, x + strip))
                if s > best:
                    best, best_x = s, x
            self.anchor = best_x + strip / 2 + band.x0


def _dilate(pixels: set[int], w: int, h: int, r: int) -> set[int]:
    out = set()
    for p in pixels:
        x, y = p % w, p // w
        for dy in range(-r, r + 1):
            ny = y + dy
            if 0 <= ny < h:
                for dx in range(-r, r + 1):
                    nx = x + dx
                    if 0 <= nx < w:
                        out.add(ny * w + nx)
    return out


def _pockets(band: Band, owned: set[int], x0: int, y0: int, x1: int, y1: int) -> tuple[set[int], set[int]]:
    """Enclosed non-solid pockets of a frame box: `holes` are filled opaque
    (small shading gaps, clearly coloured cloth); `dim` pockets (drop shadows,
    flat background inside rings and bow strings) keep distance-based alpha."""
    w = band.w
    dim: set[int] = set()
    outside = set()
    stack = [y * w + x for y in (y0, y1 - 1) for x in range(x0, x1)]
    stack += [y * w + x for x in (x0, x1 - 1) for y in range(y0, y1)]
    stack = [p for p in stack if p not in owned]
    outside.update(stack)
    while stack:
        p = stack.pop()
        x, y = p % w, p // w
        for q, ok in ((p - 1, x > x0), (p + 1, x < x1 - 1), (p - w, y > y0), (p + w, y < y1 - 1)):
            if ok and q not in owned and q not in outside:
                outside.add(q)
                stack.append(q)
    holes: set[int] = set()
    seen: set[int] = set()
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = y * w + x
            if p in owned or p in outside or p in seen:
                continue
            pocket, stack = [], [p]
            seen.add(p)
            while stack:
                q = stack.pop()
                pocket.append(q)
                qx, qy = q % w, q // w
                for r, ok in ((q - 1, qx > x0), (q + 1, qx < x1 - 1), (q - w, qy > y0), (q + w, qy < y1 - 1)):
                    if ok and r not in owned and r not in outside and r not in seen:
                        seen.add(r)
                        stack.append(r)
            median = sorted(band.dist[q] for q in pocket)[len(pocket) // 2]
            if median >= 14 or (len(pocket) <= 40 and median >= ALPHA_LO):
                holes.update(pocket)
            else:
                dim.update(pocket)
    return holes, dim


# --------------------------------------------------------------------------- output

def compose(frames: list[Frame]) -> tuple[list[Image.Image], list[int], int]:
    """Place frames on one shared canvas: body anchor at the centre column, the
    animation's ground line (lowest feet) on a common baseline."""
    ground = max(f.feet for f in frames)
    left = max(f.anchor - f.x0 for f in frames)
    right = max(f.x0 + f.image.width - f.anchor for f in frames)
    up = max(ground - f.y0 for f in frames)
    down = max(0, max(f.y0 + f.image.height - 1 - ground for f in frames))
    half = int(max(left, right) + 0.999)
    width = 2 * half + 2 * MARGIN
    base = int(up) + MARGIN
    height = base + int(down) + 1 + MARGIN
    out = []
    for f in frames:
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.paste(f.image, (round(width / 2 - f.anchor + f.x0), base - ground + f.y0), f.image)
        out.append(canvas)
    return out, [width, height], base


def key_object(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Transparent cut of everything solid inside a box (weapon art)."""
    band = Band(sheet, box)
    comps = [c for c in band.components if len(c["pixels"]) >= 20]
    return Frame(band, comps).image


def skill_tiles(sheet: Image.Image, box: tuple[int, int, int, int], count: int, what: str) -> list[Image.Image]:
    """Framed square icons: runs of non-background columns 55-85px wide
    (panel border lines are 1-3px and fall out); captions sit below the box."""
    x0, y0, x1, y1 = box
    rgb = sheet.crop(box)
    bg = _band_background(rgb)
    r, g, b = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg)).split()
    dist = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda v: 255 if v > 30 else 0)
    w, h = rgb.size
    px = dist.load()
    cols = [any(px[x, y] for y in range(h)) for x in range(w)]
    runs, start = [], None
    for x in range(w + 1):
        on = x < w and cols[x]
        if on and start is None:
            start = x
        elif not on and start is not None:
            runs.append((start, x))
            start = None
    tiles = []
    for a, bnd in runs:
        if 55 <= bnd - a <= 85:
            rows = [y for y in range(h) if any(px[x, y] for x in range(a, bnd))]
            tiles.append((a + x0, rows[0] + y0, bnd + x0, rows[-1] + 1 + y0))
    if len(tiles) != count:
        raise SliceError(f"{what}: expected {count} skill tiles, found {len(tiles)}: {tiles}")
    return [sheet.crop(t).convert("RGBA") for t in tiles]


def slice_class(cls: str, cfg: dict) -> tuple[dict, dict[str, Image.Image], list]:
    sheet = Image.open(SOURCE / f"{cls}_sheet_v2.webp").convert("RGB")
    files: dict[str, Image.Image] = {}
    entry: dict = {"canvas": {}, "baseline": {}, "fps": {}, "animations": {}}
    review: list = []

    def emit(anim: str, named: list[tuple[str, Frame]]) -> None:
        images, size, base = compose([f for _, f in named])
        entry["canvas"][anim] = size
        entry["baseline"][anim] = base
        entry["fps"][anim] = FPS[anim]
        for (name, _), img in zip(named, images):
            files[name] = img
        review.append((anim, [(name, files[name], base) for name, _ in named]))

    # Idle / Walk / Run: one band per row, one sub-band per direction group.
    for anim, (y0, y1) in cfg["rows"].items():
        named = []
        listing: dict[str, list[str]] = {}
        for direction in DIRECTIONS:
            gx0, gx1 = cfg.get("group_x", {}).get((anim, direction), GROUPS[direction])
            band = Band(sheet, (gx0, y0, gx1, y1))
            count = ROW_COUNTS[anim][direction]
            frames = split_by_gaps(band, count, f"{cls} {anim} {direction}")
            if anim == "idle":
                # The game shows a single standing frame per facing.
                name = f"idle_{direction}.png"
                named.append((name, Frame(band, frames[0])))
                continue
            names = [f"{anim}_{direction}_{i}.png" for i in range(count)]
            named += [(n, Frame(band, k)) for n, k in zip(names, frames)]
            listing[direction] = names
        emit(anim, named)
        entry["animations"][anim] = [n for n, _ in named] if anim == "idle" else listing

    atk = cfg["attack"]
    band = Band(sheet, atk["box"], atk.get("text_y"))
    frames = split_by_cuts(band, atk["cuts"], f"{cls} attack")
    names = [f"attack_right_{i}.png" for i in range(len(frames))]
    emit("attack", [(n, Frame(band, k)) for n, k in zip(names, frames)])
    entry["animations"]["attack"] = {"right": names}

    jmp = cfg["jump"]
    band = Band(sheet, jmp["box"])
    frames = split_by_cuts(band, jmp["cuts"], f"{cls} jump")
    names = [f"jump_{i}.png" for i in range(len(frames))]
    emit("jump", [(n, Frame(band, k)) for n, k in zip(names, frames)])
    entry["animations"]["jump"] = names

    for anim in ("hurt", "dead"):
        spec = cfg[anim]
        band = Band(sheet, spec["box"])
        frames = split_by_gaps(band, spec["count"], f"{cls} {anim}")
        names = [f"{anim}_{i}.png" for i in range(len(frames))]
        built = []
        for n, k in zip(names, frames):
            x0, x1 = _span(k)
            body = _body(k)
            lying = anim == "dead" or (body["x1"] - body["x0"]) > 1.2 * (body["y1"] - body["y0"])
            built.append((n, Frame(band, k, lying=lying)))
        emit(anim, built)
        entry["animations"][anim] = names

    files["portrait.png"] = sheet.crop(cfg["portrait"]).convert("RGBA")
    files["weapon.png"] = key_object(sheet, cfg["weapon"])
    sk = cfg["skills"]
    tiles = skill_tiles(sheet, sk["box"], sk["count"], f"{cls} skills")
    entry["skills"] = []
    for i, tile in enumerate(tiles):
        files[f"skill_{i}.png"] = tile
        entry["skills"].append(f"skill_{i}.png")
    review.append(("art", [(n, files[n], None) for n in ["portrait.png", "weapon.png"] + entry["skills"]]))
    return entry, files, review


def checker(size: tuple[int, int]) -> Image.Image:
    img = Image.new("RGB", size, (200, 200, 200))
    d = ImageDraw.Draw(img)
    for y in range(0, size[1], 8):
        for x in range(0, size[0], 8):
            if (x // 8 + y // 8) % 2:
                d.rectangle([x, y, x + 7, y + 7], fill=(150, 150, 150))
    return img


def contact_sheet(cls: str, review: list) -> None:
    """Every frame on a checkerboard with its file name; red line = anchor
    column, blue line = baseline. Rows wrap at 1500px."""
    rows, max_w = [], 1500
    for anim, items in review:
        line, x, h = [], 0, 0
        for name, img, base in items:
            scale = 0.5 if img.width > 300 else 1
            tile = img if scale == 1 else img.resize((int(img.width * scale), int(img.height * scale)))
            cell_w = max(tile.width, 70) + 8
            if x + cell_w > max_w and line:
                rows.append((anim, line, h))
                line, x, h = [], 0, 0
            line.append((name, tile, base, x))
            x += cell_w
            h = max(h, tile.height + 14)
        rows.append((anim, line, h))
    total_h = sum(h + 16 for _, _, h in rows)
    sheet = Image.new("RGB", (max_w, total_h), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    y = 0
    for anim, line, h in rows:
        d.text((2, y + 2), anim, fill=(0, 0, 0))
        y += 16
        for name, tile, base, x in line:
            bgc = checker(tile.size)
            if base is not None:
                bd = ImageDraw.Draw(bgc)
                bd.line([(tile.width // 2, 0), (tile.width // 2, tile.height)], fill=(230, 80, 80))
                bd.line([(0, base), (tile.width, base)], fill=(80, 80, 230))
            bgc.paste(tile, (0, 0), tile)
            sheet.paste(bgc, (x, y + 12))
            d.text((x, y), name.replace(".png", ""), fill=(0, 0, 0))
        y += h
    CONTACT.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT / f"{cls}.png")


def main() -> int:
    only = sys.argv[1:] or list(CONFIG)
    results = {}
    try:
        for cls in only:
            results[cls] = slice_class(cls, CONFIG[cls])
    except SliceError as err:
        print(f"SLICE FAILED: {err}", file=sys.stderr)
        return 1
    manifest_path = OUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    for cls, (entry, files, review) in results.items():
        target = OUT / cls
        if target.exists():
            for old in target.glob("*.png"):
                old.unlink()
        target.mkdir(parents=True, exist_ok=True)
        for name, img in files.items():
            img.save(target / name)
        for stale in target.glob("*.png.import"):
            if not (target / stale.stem).exists():
                stale.unlink()
        manifest[cls] = entry
        contact_sheet(cls, review)
        counts = {a: (len(v) if isinstance(v, list) else sum(len(x) for x in v.values()))
                  for a, v in entry["animations"].items()}
        print(f"{cls}: {counts} skills={len(entry['skills'])} files={len(files)}")
    manifest = {k: manifest[k] for k in sorted(manifest)}
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
