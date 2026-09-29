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
           "W": WARN, "D": DANGER, "H": HP, "E": ENERGY}

# Each symbol is a hand-drawn 8x8 pixel grid. Doubling each cell creates the
# authored 16x16 source pixels while keeping the outline exactly one pixel wide
# in the logical design (two output pixels at native resolution).
PATTERNS = {
    "fight": ("G......K", ".G...K..", "..G.K...", "...GG...", "...GG...", "..K.G...", ".K...G..", "K......G"),
    "items": ("........", ".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", "KTTTTTTK", ".KKKKKK.", "........"),
    "focus": ("KK....KK", "K.K..K.K", "..K..K..", "...KK...", "...KK...", "..K..K..", "K.K..K.K", "KK....KK"),
    "strike": (".......K", "......KG", ".....KGG", "....KGGK", "...KGGK.", "..KGGK..", ".KGGK...", "KKKK...."),
    "guard": ("........", "...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK..."),
    "defend": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTTTTTK", "KTTTTTTK", ".KTTTTK.", "..KTTK..", "...KK..."),
    "flee": ("K.......", "KG......", "KGG.....", "KGGG....", "KGGGG...", "KGGGGG..", "KGGGGGG.", "KKKKKKKK"),
    "skill": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGKKGGK", "..KGGK..", "..KGGK..", "...KK...", "...KK..."),
    "ready": ("........", "G.......", ".G......", "..G.....", "...G...G", "....G.G.", "....GG..", ".....G.."),
    "transfer": ("........", ".GGG....", "G...G..G", "....G.G.", "....G.G.", "G...G..G", ".GGG....", "........"),
    "hp": ("........", ".KK..KK.", "KHHKKHHK", "KHHHHHHK", ".KHHHHK.", "..KHHK..", "...K....", "........"),
    "energy": ("...KK...", "..KEEK..", ".KEEEEK.", "KEEEEEEK", "KEEEEEEK", ".KEEEEK.", "..KEEK..", "...KK..."),
    "gold": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK..."),
    "gems": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGGGGGK", ".KGGGGK.", "..KGGK..", "...KK...", "........"),
    "exp": ("...KK...", "..KSSK..", ".KSSSSK.", "KSSSSSSK", ".KSSSSK.", "..KSSK..", "...KK...", "........"),
    "level": ("...KK...", "..KGGK..", ".KGGGGK.", "..KGGK..", "..KGGK..", "..KGGK..", "..KGGK..", "KKKKKKKK"),
    "str": ("...KK...", "..KTTK..", ".KTTTTK.", "..KTTK..", "..KTTK..", "..KTTK..", "..KTTK..", "...KK..."),
    "dex": ("........", "K......K", ".K....K.", "..K..K..", "...KK...", "..K..K..", ".K....K.", "K......K"),
    "con": ("..KKKK..", ".K....K.", "K......K", "K..KK..K", "K..KK..K", ".K....K.", "..K..K..", "...KK..."),
    "int": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTKKTTK", "KTTKKTTK", ".KTTTTK.", "..K..K..", "...KK..."),
    "fth": ("...KK...", "..KGGK..", ".KGGGGK.", "..KGGK..", "..KGGK..", "..KGGK..", "..KGGK..", "...KK..."),
    "cha": (".KKKKKK.", "K......K", "K.K..K.K", "K......K", "K..KK..K", ".K....K.", "..KKKK..", "........"),
    "lck": (".K..K...", ".K..K...", ".K..K...", "..KK....", "...K....", "..K.K...", ".K...K..", "K.....K."),
    "poison": ("....K...", "...KSK..", "..KSSSK.", "..KSSSK.", "...KSK..", "....K...", "...K....", "........"),
    "bleed": ("...KK...", "..KDDK..", "..KDDK..", "...KDK..", "...KDK..", "....K...", "....K...", "........"),
    "burn": ("...K....", "..KDK...", "..KDDK..", ".KDDDK..", ".KDDDK..", "KDDDDDK.", "KDDDDDK.", ".KKKKK.."),
    "stun": ("...K....", "..KWK...", ".KWWK...", "..KWKK..", "...KWWK.", "...KKW..", "....K...", "........"),
    "weak": ("...KK...", "..K..K..", ".K....K.", "K......K", "K......K", ".K....K.", "..K..K..", "...KK..."),
    "shield": ("..KKKK..", ".K....K.", "K......K", "K..GG..K", ".K....K.", "..K..K..", "...KK...", "....K..."),
    "regen": ("...KK...", "..KSSK..", ".KSSSSK.", "KSSSSSSK", "..KSSK..", "..KSSK..", "...KK...", "........"),
    "dodge": ("K......K", "KK....KK", "K.K..K.K", "..K..K..", "...KK...", "..K..K..", ".K....K.", "K......K"),
    "crit": ("......KK", ".....KGG", "....KGGK", "...KGGK.", "..KGGK..", ".KGGK...", "KKKK....", "........"),
    "weapon": ("......K.", ".....KGK", "....KGGK", "...KGGK.", "..KGGK..", ".KGGK...", "KGGK....", "KKK....."),
    "armor": ("..KKKK..", ".K....K.", "K......K", "K..KK..K", "K..KK..K", ".K....K.", "..K..K..", "...KK..."),
    "accessory": ("...KK...", "..KGGK..", ".K....K.", "K......K", ".K....K.", "..KGGK..", "...KK...", "........"),
    "consumable": ("..KKKK..", ".K....K.", "K..SS..K", "K..SS..K", "K..SS..K", ".K....K.", "..KKKK..", "........"),
    "combat": ("...KK...", "..KDDK..", ".KDDDDK.", "KDDDDDDK", ".KDDDDK.", "..KDDK..", "...KK...", "........"),
    "elite": ("...KK...", "..KGGK..", ".KGGGGK.", "KGGKKGGK", "..KGGK..", "..KGGK..", "...KK...", "...KK..."),
    "merchant": ("...KK...", "..KTTK..", ".KTTTTK.", "KTTTTTTK", "...KK...", "..KGGK..", ".K....K.", "K......K"),
    "rest": ("........", "..KSSK..", ".K....K.", "K..KK..K", "K..K...K", ".K.K..K.", "..KKKK..", "........"),
    "treasure": ("..KKKK..", ".KGGGGK.", "KGGGGGGK", "KGGKKGGK", "KGGGGGGK", ".KGGGGK.", "..KKKK..", "........"),
    "story": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTTTTTK", ".KKKKKK."),
    "class_trial": ("...KK...", "..KGGK..", ".KGGGGK.", "..KGGK..", "...KK...", "..KGGK..", ".K....K.", "K......K"),
    "boss": ("K......K", "KK....KK", "K.K..K.K", "..KGGK..", "..KGGK..", "..K..K..", ".K....K.", "K......K"),
    "play": ("........", "...K....", "...KKK..", "...KKKK.", "...KKKK.", "...KKK..", "...K....", "........"),
    "multiplayer": ("..KK..KK", ".KTTK.KT", "KTTTTKKT", ".KTTK.KT", "..KK..KK", "..K..K..", ".K....K.", "K......K"),
    "story_mode": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTTTTTK", "KTTTTTTK", ".KKKKKK."),
    "settings": ("..K..K..", ".K.KK.K.", "K..GG..K", ".K....K.", ".K....K.", "K..GG..K", ".K.KK.K.", "..K..K.."),
    "credits": (".KKKKKK.", "KTTTTTTK", "K..KK..K", "K..KK..K", "K..KK..K", "KTTTTTTK", ".KKKKKK.", "........"),
    "back": ("...K....", "..KK....", ".K......", "KKKKKKKK", ".K......", "..KK....", "...K....", "........"),
    "quit": ("K......K", ".K....K.", "..K..K..", "...KK...", "..K..K..", ".K....K.", "K......K", "........"),
    "save": (".KKKKKK.", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", "KTTTTTTK", "KTTKKTTK", "KTTKKTTK", ".KKKKKK."),
    "lock": ("..KKKK..", ".K....K.", ".K....K.", "K......K", "K..GG..K", "K..GG..K", "K......K", "KKKKKKKK"),
    "info": ("...KK...", "..KGGK..", "...KK...", "...KK...", "...KK...", "...KK...", "..KKKK..", "........"),
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


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    names = list(PATTERNS)
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
