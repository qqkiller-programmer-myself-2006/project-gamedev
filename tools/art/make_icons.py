#!/usr/bin/env python3
"""Render the hand-authored 8x8 pixel patterns as 16x16 game icons."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "icons"
INK, GOLD, TEXT, SUCCESS, WARN, DANGER, HP, ENERGY, BG = (
    "#0a1020", "#f0c85a", "#f2f2f5", "#83df76", "#f0a040", "#e05a4f",
    "#d8453c", "#3b9ae1", "#1c2233",
)
PALETTE = {".": None, "K": INK, "G": GOLD, "T": TEXT, "S": SUCCESS,
           "W": WARN, "D": DANGER, "H": HP, "E": ENERGY, "V": "#9a79e8"}

# Each symbol is a hand-drawn 8x8 pixel grid. Doubling each cell creates the
# authored 16x16 source pixels while keeping the outline exactly one pixel wide
# in the logical design (two output pixels at native resolution).
PATTERNS = {
    "fight": ("G.....K.", ".G...K..", "..G.K...", "...GK...", "...KG...", "..K.G...", ".K...G..", "K.....G."),
    "items": ("........", ".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", "KTTTTTTK", ".KKKKKK.", "........"),
    "focus": ("..KKKK..", ".KTTTTK.", "KTTKKTTK", "KTTKKTTK", "KTTKKTTK", "KTTKKTTK", ".KTTTTK.", "..KKKK.."),
    "strike": ("....K..K", "...KG.KG", "..KGGKG.", ".KGGKG..", "KGGKG...", "KKKG....", "..KK....", "........"),
    "guard": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKGGGK", "KGGKGGGK", ".KGGGKK.", "..KK..K.", "...KKKK."),
    "defend": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTTTTTK", "KTTTTTTK", ".KTTTTK.", "..KTTK..", "...KK..."),
    "flee": ("KK......", "KGGK....", "KGGGK...", "..KGK...", "...KGG..", "..KGGG..", ".KGG.KG.", "KK...KKK"),
    "skill": ("..KKKK..", ".KTTTTK.", "KTTGTTTK", "KTTGTTTK", "KTTGTTTK", "KTTGTTTK", ".KTTTTK.", "..KKKK.."),
    "ready": ("..KKKK..", ".KTTTTK.", "KTTTTTTK", "KTTTTGKK", "KTTTGKK.", ".KTTGK..", "..KKKK..", "........"),
    "transfer": (".KK..KK.", "KGGKKG.K", "KGGK..KG", ".KK...KK", "KK...KK.", "GKK..KGG", "K.GKKGGK", ".KK..KK."),
    "hp": ("........", ".KK..KK.", "KHHKKHHK", "KHHHHHHK", ".KHHHHK.", "..KHHK..", "...K....", "........"),
    "energy": ("...KK...", "..KEEK..", ".KEEEEK.", "KEEEEEEK", "KEEEEEEK", ".KEEEEK.", "..KEEK..", "...KK..."),
    "gold": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKKGGK", "KGGKKGGK", "KGGGGGGK", ".KGGGGK.", "..KKKK.."),
    "gems": ("...KK...", "..KEEK..", ".KEEEEK.", "KEEVEEEK", "KEEVEEEK", ".KEEEEK.", "..KEEK..", "...KK..."),
    "exp": ("...KK...", "..KSSK..", ".KSSSSK.", "KSSSSSSK", ".KSSSSK.", "..KSSK..", "...KK...", "........"),
    "level": ("...KK...", "..KGGK..", ".KGGGGK.", "..KGGK..", "..KGGK..", "..KGGK..", "..KGGK..", "KKKKKKKK"),
    "str": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTTTTTK", "KTTTKTTK", ".KTTKK..", "..KTTK..", "...KK..."),
    "dex": ("..KKKK..", ".KTTTTK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", ".KTTKK..", "..KTTK..", "...KK..."),
    "con": ("..KKKK..", ".KTTTTK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", ".KTTTTK.", "..KTTK..", "...KK..."),
    "int": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTKKTTK", "KTTKKTTK", ".KTTTTK.", "..K..K..", "...KK..."),
    "fth": ("...KK...", "..KGK...", ".KGGGK..", "KGGGGGK.", ".KGGGK..", "..KGK...", "...K....", "........"),
    "cha": (".KKKKKK.", "KGGGGGGK", "KGK..KGK", "KGGGGGGK", "KGGKKGGK", ".KGGGGK.", "..KKKK..", "........"),
    "lck": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK...", "........"),
    "poison": ("...KK...", "..KSSK..", ".KSSSSK.", "KSSSSSSK", ".KSSSSK.", "..KSSK..", "..K..K..", "........"),
    "bleed": ("...KK...", "..KDDK..", ".KDDDDK.", "KDDDDDK.", ".KDDDK..", "..KDK...", "...K....", "........"),
    "burn": ("...K....", "..KDK...", "..KDDK..", ".KDDDK..", ".KDDDK..", "KDDDDDK.", "KDDDDDK.", ".KKKKK.."),
    "stun": ("...K....", "..KWK...", ".KWWK...", "..KWKK..", "...KWWK.", "...KKW..", "....K...", "........"),
    "weak": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK..."),
    "shield": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKKGGK", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK..."),
    "regen": ("...KK...", "..KSSK..", ".KSSSSK.", "KSSSSSSK", "..KSSK..", "..KSSK..", "...KK...", "........"),
    "dodge": ("K......K", "KK....KK", "K.KGGK.K", "..KGGK..", "...KK...", "..KTTK..", ".KTTTTK.", "K......K"),
    "crit": ("...K.K..", "..KGKGK.", ".KGGGGGK", "KGGGGGGK", ".KGGGGGK", "..KGKGK.", "...K.K..", "........"),
    "weapon": ("......K.", ".....KGK", "....KGGK", "...KGGK.", "..KGGK..", ".KGGK...", "KGGK....", "KKK....."),
    "armor": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKKGGK", "KGGKKGGK", "KGGGGGGK", ".KGGGGK.", "..KGGK.."),
    "accessory": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGKKGGK", ".KGGGGK.", "..KGGK..", "...KK...", "........"),
    "consumable": ("..KKKK..", ".K....K.", "K..SS..K", "K..SS..K", "K..SS..K", ".K....K.", "..KKKK..", "........"),
    "combat": ("...KK...", "..KDDK..", ".KDDDDK.", "KDDDDDDK", ".KDDDDK.", "..KDDK..", "...KK...", "........"),
    "elite": ("K......K", "KK....KK", "K.K..K.K", "..KTTK..", ".KTTTTK.", "KTTKKTTK", ".KTTTTK.", "..KKKK.."),
    "merchant": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTTTTTK", "...KK...", "..KGGK..", ".K....K.", "K......K"),
    "rest": ("........", "..KSSK..", ".KSSSSK.", "KSSSSSSK", "KSSSSSSK", ".KSSSSK.", "..KSSK..", "...KK..."),
    "treasure": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKKGGK", "KGGGGGGK", ".KGGGGK.", "..KKKK..", "........"),
    "story": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTGGTTK", ".KKGGKKK"),
    "class_trial": ("...KK...", "..KGGK..", ".KGGGGK.", "..KGGK..", "...KK...", "..KGGK..", ".K....K.", "K......K"),
    "boss": ("K......K", "KK....KK", "K.KGGK.K", "..KGGK..", "..KGGK..", "..KGGK..", ".K....K.", "K......K"),
    "play": ("........", "...K....", "...KKK..", "..KGGGKK", ".KGGGGKK", "...KKK..", "...K....", "........"),
    "multiplayer": (".KK..KK.", ".KTTK.KT", "KTTTKTTK", ".KTTK.KT", ".KK..KK.", "..K..K..", ".K....K.", "K......K"),
    "story_mode": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTTTTTK", "KKKGGKKK"),
    "settings": ("..K..K..", ".K.GK.K.", "K..GG..K", ".K.GG.K.", ".K.GG.K.", "K..GG..K", ".K.GK.K.", "..K..K.."),
    "credits": (".KKKKKK.", "KTTTTTTK", "K..KK..K", "K..KK..K", "K..KK..K", "KTTTTTTK", ".KKKKKK.", "........"),
    "back": ("...K....", "..KK....", ".KGG....", "KKGGGGKK", ".KGG....", "..KK....", "...K....", "........"),
    "quit": ("K......K", ".K....K.", "..K..K..", "...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", "........"),
    "save": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", ".KKKKKK."),
    "lock": ("..KKKK..", ".K....K.", ".K....K.", "K......K", "K.GGG.K.", "K.GGG.K.", "K......K", "KKKKKKKK"),
    "info": ("..KKKK..", ".KTTTTK.", "KTTTTTTK", "KTTKKTTK", "..KTTK..", "..KTTK..", ".KTTTTK.", "..KKKK.."),
    "warning": ("...KK...", "..KWWK..", ".KWWWWK.", "KWWWWWWK", "KWWKKWWK", "KWWKKWWK", "KWWWWWWK", "KKKKKKKK"),
}


def render_icon(pattern):
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for y, row in enumerate(pattern):
        if len(row) != 8:
            raise ValueError(f"expected 8 cells per row: {row!r}")
        for x, pixel in enumerate(row):
            color = PALETTE[pixel]
            if color:
                draw.rectangle((x * 2, y * 2, x * 2 + 1, y * 2 + 1), fill=color)
    return image


def filename(name):
    # CON is a reserved DOS device name, even with an extension. Prefix it so
    # Godot can import and export the Constitution icon on Windows.
    return "_con" if name == "con" else name


def self_check(names):
    seen = {}
    for name in names:
        image = render_icon(PATTERNS[name]).convert("RGBA")
        pixels = tuple(image.getdata())
        if pixels in seen:
            raise ValueError(f"duplicate icon pixels: {name} and {seen[pixels]}")
        seen[pixels] = name
        bright = 0
        for pixel in pixels:
            if pixel[3] == 0 or pixel[:3] == Image.new("RGB", (1, 1), INK).getpixel((0, 0)):
                continue
            luminance = (0.2126 * pixel[0] + 0.7152 * pixel[1] + 0.0722 * pixel[2]) / 255
            if luminance > 0.35:
                bright += 1
        if bright < 20:
            raise ValueError(f"{name} has only {bright} bright non-outline pixels (need 20)")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    names = list(PATTERNS)
    self_check(names)
    for name, pattern in PATTERNS.items():
        render_icon(pattern).save(OUT / f"{filename(name)}.png")

    cell_w, cell_h, scale = 150, 66, 3
    cols = 4
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), BG)
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 12)
    except OSError:
        font = ImageFont.load_default()
    for index, name in enumerate(names):
        x, y = (index % cols) * cell_w, (index // cols) * cell_h
        icon = Image.open(OUT / f"{filename(name)}.png").convert("RGBA").resize((16 * scale, 16 * scale), Image.Resampling.NEAREST)
        sheet.paste(icon, (x + 8, y + 8), icon)
        draw.text((x + 68, y + 21), name, fill=TEXT, font=font)
    sheet.save(OUT / "_contact.png")
    print(f"Wrote {len(names)} icons to {OUT}")


if __name__ == "__main__":
    main()
