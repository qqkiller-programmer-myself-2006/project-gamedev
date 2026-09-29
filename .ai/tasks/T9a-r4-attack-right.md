# T9a round 4 — attack Right group must have 4 frames

Same limits as before (Python path: `C:\Users\qqkiller2006\AppData\Local\Programs\Python\Python313\python.exe`). Round 3 is
good; only this remains: in the source sheets the Attack **Right** group has **4** character poses for all three classes, but
the output has 3 and `attack_right_2.png` contains two characters (archer and mage; check swordsman). Expected attack counts per
class: Down 4, Left 3, Right 4, Up 3. Make the splitter use these expected counts (e.g. split the widest merged body blob at the
gap/valley in its column-occupancy profile until the count matches) and regenerate. Do not change any other animation's frames.
View the three `_contact.png` files to confirm one character per attack frame. Delete `tools/__pycache__`.
Report: attack counts per direction per class.
