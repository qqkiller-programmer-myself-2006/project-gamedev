# T37a — Thai runtime: locale, font, catalog wiring, UiText (issue: "project ใช้ไทยทั้งหมด")

## Goal
ทำให้เกมแสดงภาษาไทยเป็นค่าเริ่มต้น (phase B ต่อจาก phase A = commit dc57b17 ที่มี `i18n/th.po` 355 ข้อความของ content แล้ว).
อังกฤษยังเป็น source (msgid = ข้อความอังกฤษเดิม) และยังเปิดใช้ได้ด้วย `--lang=en` / `?lang=en`.

## Read first
- `docs/design/thai-glossary.md` (ศัพท์มาตรฐาน — ต้องใช้ตามนี้), `docs/adr/0007-english-in-game-text-in-content-data.md`
- `tools/i18n/extract_strings.gd`, `tools/i18n/check_po.gd`, `tests/i18n/test_thai_catalog.gd`
- `src/client/ui/ui_text.gd`, `src/client/ui/ui_kit.gd`, `src/client/client_app.gd`, `src/app/launch_options.gd`
- Fonts: `assets/fonts/NotoSansThai-{Regular,Bold}.ttf`, `assets/fonts/PixelifySans.ttf`

## Do
1. **Locale**: load `res://i18n/th.po` into `TranslationServer` at client start (Godot 4.7). Default locale `th`; `--lang=en` / `?lang=en` (see `LaunchOptions`) selects `en`. Persist nothing new. The headless server must not depend on it.
2. **Font**: add Noto Sans Thai as a fallback for the project's UI font (theme font `fallbacks`) so Thai glyphs render on desktop AND web export (no system fonts on web). Keep Pixelify for Latin/digits. Thai text must not clip at 1.45× text scale (check line height / vertical clipping of Thai tone marks in Labels and buttons).
3. **Translate at display time**: add one small helper (e.g. `Tr.t(msgid)` wrapping `TranslationServer.translate`, with `{placeholder}`/`%s` formatting kept) and use it for:
   - every string in `UiText` (errors, encounter labels, hints) — extend `tools/i18n/extract_strings.gd` (or add a sibling extractor) so UI strings in `ui_text.gd` are also emitted into `i18n/messages.pot` and merged into `i18n/th.po`.
   - content strings coming from the server (hero/enemy/skill/item names, descriptions, dialogue) — these are English msgids already in th.po; translate when they are shown on the client (NOT on the server; server stays English and authoritative).
4. **Translate UiText into Thai** following the glossary (keep hotkeys like `[F]`, digits, placeholders). Every new th.po entry must be non-empty, placeholders identical to msgid, no stray English except hotkeys.
5. **Tests**: test runner and all existing tests must keep passing in English: make `tests/run_tests.gd` (or `tests/test_case.gd`) force locale `en` for every test. Add `tests/i18n/` tests: th.po covers every `UiText` string, locale switch works (`th` → Thai, `en` → English), placeholders preserved.
6. Do NOT mass-edit hard-coded strings in `src/client/**/*.gd` other than `ui_text.gd` — that is T37b (a later task). Do not touch battle/camp layout (another executor is changing it in parallel).

## Verify
```
export GODOT='D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
bash tools/run_tests.sh                 # all must pass
"$GODOT" --headless --path . -s tools/i18n/extract_strings.gd   # deterministic; run twice, byte-identical
"$GODOT" --headless --path . -s tools/i18n/check_po.gd          # exit 0
```
Also run the UI preview (`tools/dev/ui_preview.gd --seed=11`) once with default locale and once with `--lang=en`, open 2-3 PNGs and confirm Thai renders (no tofu boxes) on Title/Lobby.

## Report
Files changed, counts (msgids total/translated), test totals, anything left untranslated and why.
