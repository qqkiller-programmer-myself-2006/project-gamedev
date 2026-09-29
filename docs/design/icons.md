# Pixel icon set

Icons are authored in `tools/art/make_icons.py` as native 16×16 pixel grids and displayed with nearest-neighbour filtering. Only the fill is authored: the generator adds the 1-px `#0a1020` outline around every silhouette and lights uppercase colours from the top-left (highlight on up/left edges, shadow on down/right edges), so the whole set shares one outline weight and one light direction. Colours come from the Navy + Gold palette in `ui-style.md` plus the HP/Energy bar colours, at most 5 per icon besides the outline. Every icon used by the UI should stay beside its text or have a tooltip. The `con` icon is stored as `_con.png` because `CON` is a reserved Windows device name; `Icons.texture("con")` handles that mapping.

The generator refuses to write the set if two icons have identical pixels, if two alpha silhouettes differ in fewer than 16 pixels, if an icon uses more than 5 colours besides the outline, if it has fewer than 20 bright pixels, or if a fill pixel touches the 16×16 border (no room for the outline).

| Icon | Picture | Meaning and use |
| --- | --- | --- |
| `fight` | One raised sword | Battle Fight action. |
| `items` | Backpack | Battle Items action. |
| `focus` | Blue-irised eye | Battle Focus action. |
| `strike` | Three slash marks | Basic skill card. |
| `guard` | Gold heater shield with a white plus | Guard skill card. |
| `defend` | Tall silver tower shield, gold rim and boss | Defend action and skill card. |
| `flee` | Running figure with motion lines | Flee action. |
| `skill` | Blue four-point spark with a twinkle | Skill menu and cards. |
| `ready` | Green circle with a check breaking out of it | Camp readiness. |
| `transfer` | Gold arrow out, white arrow back | Camp item and gold transfer. |
| `hp` | Red heart | HP display and bars. |
| `energy` | Blue crystal with a bolt | Energy display and bars. |
| `gold` | Coin stack with a coin in front | Currency displays and rewards. |
| `gems` | Brilliant-cut blue gem | Gem currency and costs. |
| `exp` | Green five-point star | Experience and rewards. |
| `level` | Gold up arrow over a step | Character level. |
| `str` | Flexed arm | Strength attribute. |
| `dex` | Winged boot | Dexterity attribute. |
| `con` | Heart guarded by a shield | Constitution attribute. |
| `int` | Brain | Intelligence attribute. |
| `fth` | White cross on a rayed gold sun | Faith attribute. |
| `cha` | Speech bubble with a heart | Charisma attribute. |
| `lck` | Four-leaf clover | Luck attribute. |
| `poison` | Green drop with bubbles | Status badge. |
| `bleed` | Large and small blood drops | Status badge. |
| `burn` | Layered flame | Status badge. |
| `stun` | Lightning bolt | Status badge. |
| `weak` | Broken sword with a red down arrow | Status badge. |
| `shield` | Blue kite shield | Status badge. |
| `regen` | Green heart with a plus | Status badge. |
| `dodge` | Swerving blue arrow with speed lines | Status badge. |
| `crit` | Orange starburst with an exclamation mark | Status badge. |
| `weapon` | Diagonal sword | Equipment slot. |
| `armor` | Breastplate with a belt | Equipment slot. |
| `accessory` | Pendant on a chain | Accessory slots. |
| `consumable` | Red potion bottle | Consumable slot. |
| `combat` | Crossed swords | Combat path vote. |
| `elite` | Horned skull | Elite path vote. |
| `merchant` | Market stall with a striped awning | Merchant encounter. |
| `rest` | Campfire on crossed logs | Rest encounter. |
| `treasure` | Chest with a lock | Treasure path and reward. |
| `story` | Open book with a bookmark | Story encounter. |
| `class_trial` | Challenge banner on a pole | Class trial encounter. |
| `boss` | Crowned skull with red eyes | Boss encounter. |
| `play` | Bold play triangle | Title menu. |
| `multiplayer` | Two party members | Title menu. |
| `story_mode` | Closed blue book with a bookmark | Title menu. |
| `settings` | Gear | Settings menu. |
| `credits` | Scroll of names | Credits menu. |
| `back` | Bold left arrow | Submenus. |
| `quit` | Power symbol | Title menu. |
| `save` | Floppy disk | Save controls. |
| `lock` | Padlock | Locked options and rewards. |
| `info` | Bold letter i | Help and tooltips. |
| `warning` | Alert triangle | Caution notices. |

Regenerate the PNGs and the labelled contact sheet (`assets/icons/_contact.png`, every icon at 1× and 3× on navy) by running `python tools/art/make_icons.py` from the repository root. Godot PNG import metadata is generated with `Godot --headless --path . --import`.
