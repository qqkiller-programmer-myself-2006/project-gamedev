# UI style guide: Navy + Gold (issue #60)

One theme on every screen. The owner picked **Navy + Gold** (2026-09-29). The theme lives in one place,
`src/client/ui/ui_kit.gd` (`UiKit` tokens + `UiKit.make_theme()`). Screens pick a **type variation**; they never build
their own StyleBoxes and never write hex colours. Art inside the battle figures (`battle_token.gd` drawings),
`battle_backdrop.gd` and `home_backdrop.gd` is scenery, not UI, and keeps its own colours.

## Tokens

| Token (`UiKit.`) | Value | Use |
| --- | --- | --- |
| `BG` | `#11162a` | app background behind every screen, chapter card |
| `NAVY` (`PANEL`) | `#1c2233` | every panel / card background |
| `NAVY_RAISED` (`PANEL_LIGHT`) | `#2a3147` | rows, title tags, inputs and cards inside panels |
| `NAVY_FOCUS` (`PANEL_FOCUS`) | `#333c57` | selected / highlighted panel (with a gold border) |
| `BORDER` | `#b3b4c0` | 2 px panel border and the corner diamonds |
| `SLATE` / `SLATE_HOVER` | `#454b5e` / `#58607a` | secondary buttons |
| `GOLD` (`ACCENT`) | `#f0c85a` | primary action, focus ring, heading accent, selected state |
| `TEXT` / `TEXT_DIM` | `#f2f2f5` / `#a9abb8` | body / secondary text |
| `SUCCESS` (`GOOD`) / `WARN` / `DANGER` | `#83df76` / `#f0a040` / `#e05a4f` | positive, caution (DEV, unaffordable), destructive (Leave) |
| `ALLY` / `ENEMY` | `#8fd0f0` / `#f8aca0` | text naming players / enemies (always with a word or tag too) |
| `DISABLED_BG` / `DISABLED_TEXT` | `#1f2536` / `#8a8fa3` | disabled controls (≥ 3:1) |
| `BAR_HP` / `BAR_ENERGY` / `BAR_BACK` | unchanged | HP (red) and Energy (blue) bars |
| `HUD_BG` | `NAVY` at 88 % alpha | combat and camp overlays, readable over the field |

Every text colour reaches WCAG AA 4.5:1 on `BG`, `NAVY`, `NAVY_RAISED` and `NAVY_FOCUS`
(`tests/client/test_ui_contrast.gd`). `DANGER` is a fill/border colour only; destructive *text* uses `TEXT` on the
danger button or `ENEMY`.

## Type variations

| Variation | Base | Look | Use |
| --- | --- | --- | --- |
| *(default)* / `NavyPanel` | PanelContainer | `NAVY`, 2 px `BORDER`, square corners, corner diamonds, margin 14 | every screen panel, dialogs, the dialogue box |
| `CardPanel` / `CompactPanel` | PanelContainer | `NAVY_RAISED`, 1 px dim border | rows and cards inside a panel |
| `HighlightPanel` / `CompactHighlightPanel` | PanelContainer | `NAVY_FOCUS`, 2 px `GOLD` | the selected / acting / "you" card, tips |
| `TitleTag` | PanelContainer | `NAVY_RAISED`, 2 px `BORDER` | small floating title box above a column ("Class", "Races") |
| `HudPanel` | PanelContainer | `HUD_BG` (88 %), 2 px `BORDER` | combat HUD, nameplates, timeline, camp columns |
| `HudHighlightPanel` / `HudWarnPanel` | PanelContainer | `HUD_BG`, 2 px `GOLD` / `WARN` | acting unit, Boss warning |
| `HudCard` | PanelContainer | `NAVY_RAISED` 92 %, no border | rows inside HUD panels |
| `BannerPanel` | PanelContainer | `NAVY` 94 %, gold top and bottom rule | action band in battle |
| `ToastPanel` | PanelContainer | `NAVY`, 2 px `GOLD` | toasts (always top centre) |
| `BadgePanel` | PanelContainer | dark fill, 1 px dim border | tags such as YOU, AI, HOST |
| *(default)* / `SecondaryButton` | Button | `SLATE`, `BORDER` edge, hover `SLATE_HOVER` | every ordinary action |
| `PrimaryButton` | Button | `GOLD` fill, `NAVY` text | the one main action of a panel |
| `DangerButton` | Button | dark red fill, `DANGER` edge | Leave, Reset Skills (always confirmed) |
| `BigButton` / `BigPrimaryButton` / `BigDangerButton` | the above | heading-size text | menu-sized buttons |
| `SmallButton` | Button | small text, tight padding | dense rows (camp, battle menu) |
| `SelectedButton` | Button | `NAVY_FOCUS`, 2 px `GOLD` | the current choice in a set (text size, tab, tree node) |
| `TabButton` / `TabButtonSelected` | Button | round navy medallion; gold edge when selected | Character setup tabs |
| `HudButton` | Button | `NAVY_RAISED` 92 %, thin border | battle action row and cards |

Every button's `focus` style is a 2 px **gold ring drawn 3 px outside** the button, so it shows on gold, slate and navy
alike. `LineEdit`, `OptionButton`, `CheckButton`, `HSlider`, scrollbars, `HSeparator` and tooltips are styled in the
same theme (`NAVY_RAISED` inputs, gold focus edge and caret, slate scrollbar grabbers, `NAVY` tooltip with a gold
edge).

Helpers: `UiKit.button(text, callback, big, kind)` with `kind` = `"secondary"` (default), `"primary"`, `"danger"`,
`"small"`; `UiKit.disable(button, reason)` disables a control and explains why in its tooltip;
`UiKit.navy_box()` is the navy StyleBox (for custom-drawn controls such as the dialogue box); `ConfirmDialog` asks
before destructive actions.

## Spacing and typography

- Screen edge gutter 12–40 px; panel content margin 14; rows inside a panel 6–10 apart; button rows 8–12 apart.
- Sizes only from `UiKit.SIZES` × the text-size setting: tiny 11, small 15, body 18, heading 23, title 34, huge 52.
- Pixelify Sans (`PixelXxxLabel`, headings, buttons, names, numbers); the default font for long, wrapping text.
- Headings may be `GOLD`; body text is `TEXT`; hints and secondary lines are `TEXT_DIM` (`"dim"` style).

## UX rules

1. **One gold primary action per panel** (Play, Begin Story, Create a room, Start the Match, Finish, Ready, Continue).
   Choice lists (paths, Story options, Skill cards) have no primary: every option is secondary and the chosen one gets
   `HighlightPanel` / `SelectedButton`.
2. **Key hints** are written `[Key]` after the label, only for keys that really work: `Settings [F2]`, `Back [Esc]`,
   `Ready [R]`, `Clues [C]`, `Fight [F]`, `Got it [H]`.
3. **Focus is always visible**: gold ring; every screen focuses its primary (or first) control when it opens.
4. **Esc = back** everywhere: title sub-menus go back one step, Character setup finishes, overlays (Settings, Clues,
   dialogs, battle target picking) close, battle and camp toggle their menu, and on the Match list or the lobby Esc asks
   to leave.
5. **Empty states say what to do next** (texts in `UiText.EMPTY`).
6. **Disabled controls explain why** in a tooltip (`UiKit.disable`).
7. **Destructive actions ask first**: Leave room, Leave match, Reset Skills (`ConfirmDialog`, Cancel is focused).
8. **Toasts at top centre** on every screen; banners just below the top bar, never over buttons for long.
9. Nothing overlaps at 1280×720, 1920×1080 and text size 1.4; long lists scroll; rows wrap.
10. Reduced motion turns off fades, slides and floating motion.

## Icons

The authored 16×16 pixel icons in `assets/icons/` use the Navy + Gold tokens and bar colours, with a dark outline and top-left light. Render them with nearest-neighbour filtering through `Icons.rect()` or pair them with text using `Icons.with_text()`; keep their meaning available in text or a tooltip. See [`icons.md`](icons.md) for the set and regeneration command.

## Checking a UI change

```bash
GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe
"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ux --seed=3 --speed=10          # add --scale=1.4, --seed=11,
                                                                                    # --class=mage, --resolution=1920x1080
"$GODOT" --path . -s tools/dev/story_preview.gd -- --out=build/ux_story --full
```

`ui_preview` also captures the Leave confirmation (`02f`) and Settings (`02g`). Open the PNGs and look for clipped text,
overlaps and more than one gold button per panel. Run one Godot process at a time.

## Audit: before → after (2026-09-29, `tools/dev/ui_preview.gd` seeds 3 and 11, `tools/dev/story_preview.gd --full`)

| Screen | Before | After |
| --- | --- | --- |
| Base theme (lobby, voting, clue log, settings, summary, class/story panels) | green: `BG #141d18`, `PANEL #1f2c25`, `BORDER #5f8065`, rounded corners | Navy + Gold tokens, square navy panels with diamonds |
| Home page | navy via a local `_navy()` + `CornerDiamonds` + per-button restyle; OptionButtons still green; several big equal buttons; Esc always jumped to the main menu | default theme only; one primary per panel; Esc goes back one step |
| Lobby | green; Start and Character Setup both big; Leave unconfirmed; toast bottom centre | Start = primary, Leave = danger + confirm, toast top centre |
| Character setup | ~12 `flat_box(Color("#…"))` literals, brown striped background, green disabled buttons, green "Purchase" fill; Reset Skills unconfirmed; disabled buttons silent | variations (`TitleTag`, `TabButton`, `SelectedButton`, `PrimaryButton`), navy background, disabled reasons, Reset confirmed, 1–5 switch tabs |
| Camp (Merchant / Rest) | AAC grey `#5c5c5c` panels and own `_flat_box`; fixed 11–13 px fonts; "Jumpscare" placeholder; "Consumable <null>"; × button labelled Leave but closed tips | navy HUD columns (3-column layout kept), theme sizes, real Encounter name, "Empty", shared ≡ menu with confirmed Leave, empty states |
| Battle HUD | grey translucent; banner / warning / acting card built from literals; toast moved by hand each tick | `HudPanel` navy 88 %, `BannerPanel`, `HudWarnPanel`, `HudHighlightPanel`; Items disabled reason |
| Match list (voting, travel, class, story, summary) | green; app banner covered the top bar; Leave unconfirmed | navy; banner below the top bar; Leave confirmed; disabled vote buttons explain why |
| Story dialogue / chapter card | own navy/gold constants (`1c2233`, `c9ced8`, `e8c56a`, `101624`) and fixed font sizes | UiKit tokens and `SIZES` |
| Settings | "> Normal" text marker for the current size | `SelectedButton` for the current size, Close = primary |
