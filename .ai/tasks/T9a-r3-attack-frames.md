# T9a round 3 — split merged attack frames

Continue on this branch (same limits as `.ai/tasks/T9a-slice-character-sheets.md`; run Python with
`C:\Users\qqkiller2006\AppData\Local\Programs\Python\Python313\python.exe` if `python` is missing).
Round 2 is good for idle/walk/run/hurt/dead — do not regress them. QA found that several **attack** frames contain parts of a
neighbouring frame (two characters in one PNG): archer `attack_left_1`, `attack_right_0`, `attack_right_1`, `attack_right_2`,
`attack_down_1`, `attack_down_2`; swordsman `attack_right_0`, `attack_right_1`, `attack_left_1`, `attack_down_1`; check mage too.

Fix the attack grouping: first find the **character bodies** (large components, height ≥ ~45 px) and treat each as one frame;
then attach small effect components (arrows, slash arcs, magic orbs, sparkles) to the nearest body *in the same group*, but never
merge two bodies into one frame. Each group should end with the number of bodies visible in the sheet (usually 3–4).
Keep all frames of one animation on one canvas, bottom-centre aligned.

Verify by viewing every class's `_contact.png`: exactly one character per attack frame, effects kept. Delete `tools/__pycache__`.
Report in English: attack frame counts per direction per class; anything imperfect.
