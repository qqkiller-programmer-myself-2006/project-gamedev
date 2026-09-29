# Pixel icon set

Icons are authored in `tools/art/make_icons.py` as small pixel grids, rendered at 16×16, and displayed with nearest-neighbour filtering. The Navy + Gold palette follows `ui-style.md`. Every icon used by the UI should stay beside its text or have a tooltip. The `con` icon is stored as `_con.png` because `CON` is a reserved Windows device name; `Icons.texture("con")` handles that mapping.

| Icon | Meaning and phase 2 use |
| --- | --- |
| `fight` | Crossed blades; battle Fight action. |
| `items` | Inventory case; battle Items action. |
| `focus` | Target reticle; battle Focus action. |
| `strike` | Diagonal blade; basic skill card. |
| `guard` | Guard mark; skill card. |
| `defend` | Shield; defend action and skill card. |
| `flee` | Exit arrow; flee action. |
| `skill` | Spark; skill menu and cards. |
| `ready` | Check mark; camp readiness. |
| `transfer` | Two-way arrows; camp item and gold transfer. |
| `hp` | Heart; HP display and bars. |
| `energy` | Blue energy cell; Energy display and bars. |
| `gold` | Gold coin; currency displays and rewards. |
| `gems` | Cut gem; gem currency and costs. |
| `exp` | Green growth badge; experience and rewards. |
| `level` | Rising marker; character level. |
| `str` | Strength mark; attribute sheet. |
| `dex` | Dexterity mark; attribute sheet. |
| `con` | Constitution mark; attribute sheet. |
| `int` | Intelligence mark; attribute sheet. |
| `fth` | Faith mark; attribute sheet. |
| `cha` | Charisma mark; attribute sheet. |
| `lck` | Luck mark; attribute sheet. |
| `poison` | Toxin drop; status badges. |
| `bleed` | Blood drop; status badges. |
| `burn` | Flame; status badges. |
| `stun` | Lightning; status badges. |
| `weak` | Fading ring; status badges. |
| `shield` | Protected shield; status badges. |
| `regen` | Healing growth; status badges. |
| `dodge` | Evade motion; status badges. |
| `crit` | Critical slash; status badges. |
| `weapon` | Blade; equipment slot. |
| `armor` | Chest armor; equipment slot. |
| `accessory` | Pendant; accessory slots. |
| `consumable` | Flask; consumable slot. |
| `combat` | Crossed weapons; combat path vote. |
| `elite` | Enhanced spark; elite path vote. |
| `merchant` | Trader; merchant encounter. |
| `rest` | Campfire; rest encounter. |
| `treasure` | Chest; treasure path and reward. |
| `story` | Open page; story encounter. |
| `class_trial` | Trial sigil; class trial encounter. |
| `boss` | Horned mask; boss encounter. |
| `play` | Play arrow; title menu. |
| `multiplayer` | Party figures; title menu. |
| `story_mode` | Open page; title menu. |
| `settings` | Gear; settings menu. |
| `credits` | Plaque; credits menu. |
| `back` | Return arrow; submenus. |
| `quit` | Exit mark; title menu. |
| `save` | Save disk; save controls. |
| `lock` | Padlock; locked options and rewards. |
| `info` | Information mark; help and tooltips. |
| `warning` | Alert badge; caution notices. |

Regenerate the PNGs and labelled contact sheet by running `python tools/art/make_icons.py` from the repository root. Godot PNG import metadata is generated with `Godot --headless --path . --import`.
