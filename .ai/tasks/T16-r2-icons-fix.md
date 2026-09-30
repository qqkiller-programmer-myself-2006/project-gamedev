# T16-r2 — Fix the icon set's quality (#61)

The first pass (`tools/art/make_icons.py`, 55 icons) works, and `Icons` + tests are fine — keep them. The art is not good enough.
Look at `assets/icons/_contact.png` yourself before and after. Edit only `tools/art/make_icons.py` (and regenerate
`assets/icons/*.png`, `_contact.png`), plus `docs/design/icons.md` if a description changes.

## Fix
1. **Invisible on navy** (outline only, no fill): focus, dex, con, lck, weak, shield, dodge, armor, accessory, rest, settings,
   back, quit, play. Every icon needs a light/coloured FILL (theme gold `#f0c85a`, text `#f2f2f5`, border `#b3b4c0`, or the bar
   colours) inside the dark `#0a1020` outline, so it reads on `#1c2233`.
2. **Duplicates — each icon must have its own silhouette:**
   - guard = shield with a small check/plus; gold = coin stack; gems = faceted gem (blue/violet); weapon = sword;
     strike = sword with a motion arc; crit = star burst; str = flexed arm/fist; fth = sun/holy symbol;
     skill = open book/rune; elite = skull with horns; story = open book with bookmark; story_mode = book + quill.
3. **Unclear:** fight = crossed swords; flee = running legs/arrow out of a door; ready = check mark in a circle;
   transfer = two opposite arrows; multiplayer = two heads; poison = green drop with bubble; bleed = red drop;
   info = "i" in a circle.
4. Keep: hp, energy, exp, burn, regen, warning, lock, save, combat, treasure, merchant (already good).
5. Keep `con` saved as `_con.png` (Windows reserved name) and make `Icons.texture("con")` map to it (check the helper does).

## Rules
- 16x16, 1-px dark outline, light from top-left, max ~5 colours, no third-party/AI art.
- Add a self-check in `make_icons.py`: no two icons may have identical pixel data, and every icon must have at least 20
  non-outline, non-transparent pixels whose luminance > 0.35 (fails loudly otherwise).
- Verify: `python tools/art/make_icons.py` passes its self-check; view `_contact.png`; `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`
  → 0 failed. ONE Godot process at a time. Report which icons changed and the test line.
