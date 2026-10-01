#!/usr/bin/env python3
"""Generate compact, transparent pixel-art battle skill strips."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
import math

ROOT = Path(__file__).resolve().parents[2]
SKILLS = {
    "power_slash": (8, 192, "target", "ultimate"),
    "aimed_shot": (6, 128, "target", "normal"),
    "fireball": (8, 192, "target", "ultimate"),
    "frost_lance": (8, 192, "target", "ultimate"),
    "protect": (6, 128, "target", "normal"),
    "shield_wall": (8, 192, "party", "ultimate"),
    "stab": (6, 128, "target", "normal"),
    "prep_time": (6, 128, "actor", "normal"),
    "poke_up": (6, 128, "target", "normal"),
    "inject_venom": (8, 192, "target", "ultimate"),
}
NAVY, GOLD, WHITE, CYAN, RED, BLUE, GREEN, PURPLE = "#0a1020", "#ffd45a", "#fff6d5", "#8de8ff", "#ff713f", "#61b7ff", "#8be35c", "#b873f5"

def frame(skill, index, n, size):
    # Draw on a 128px logical canvas then nearest-neighbour upscale. This keeps
    # the same chunky pixels at both normal (128) and ultimate (192) sizes.
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = 64; t = index / max(1, n-1)
    def line(points, fill, width=4):
        d.line(points, fill=fill, width=width)
    def diamond(x,y,r,color):
        d.polygon([(x,y-r),(x+r,y),(x,y+r),(x-r,y)],fill=color,outline=NAVY)
    def outlined(points, fill, width):
        line(points, NAVY, width+2); line(points, fill, width)
    if skill == "power_slash":
        # Thick diagonal crescent sweeping from upper-right to lower-left.
        sweep = (t-.5)*8
        pts=[]
        for k in range(17):
            a=math.radians(-50 + k*(180/16))
            pts.append((int(64+45*math.cos(a)+sweep), int(64+45*math.sin(a)-sweep)))
        outlined(pts, GOLD, 7); line(pts[2:-2], WHITE, 3)
        for x,y,r in [(30+int(t*8),39,3),(93-int(t*7),84,3),(54,24+int(t*8),2)]: diamond(x,y,r,WHITE)
    elif skill in ("stab", "poke_up"):
        if skill == "stab":
            outlined([(28,74),(48,63),(83,45)], CYAN, 8)
            # Cross-shaped glint and three radial pierce rays.
            line([(82,34),(82,56)], WHITE, 4); line([(71,45),(93,45)], GOLD, 4)
            for pts in [[(95,35),(104,28)],[(98,47),(110,47)],[(94,56),(103,64)]]: line(pts,WHITE,3)
        else:
            outlined([(64,99),(64,40)], GOLD, 8); d.polygon([(64,27),(50,48),(78,48)],fill=WHITE,outline=NAVY)
            for dx,dy in [(-19,55),(19,55),(-27,75),(27,75)]:
                line([(64+dx//2,dy+12),(64+dx,dy)],CYAN,3)
            for x,y in [(42,91),(86,91),(52,105),(76,105)]: diamond(x,y,3,GOLD)
    elif skill == "aimed_shot":
        x=36+int(40*t); outlined([(x-27,64),(x+24,64)], CYAN, 7)
        d.polygon([(x+34,64),(x+17,54),(x+17,74)],fill=GOLD,outline=NAVY)
        if t>.55:
            for dx,dy in [(-12,-12),(0,-19),(13,-11),(15,8),(0,17),(-13,10)]: diamond(96+dx,64+dy,4,GOLD)
    elif skill == "fireball":
        r=int(13+19*t); x=int(64+(t-.5)*14); y=62
        d.ellipse((x-r,y-r,x+r,y+r),fill=RED,outline=NAVY,width=3)
        rr=int(r*.68); d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=GOLD); rr=max(3,int(r*.32)); d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=WHITE)
        for a in range(8):
            ang=a*math.pi/4; l=8+int(t*9)
            line([(int(x+math.cos(ang)*(r+2)),int(y+math.sin(ang)*(r+2))),(int(x+math.cos(ang)*(r+l)),int(y+math.sin(ang)*(r+l)))],GOLD,3)
    elif skill == "frost_lance":
        x=38+int(t*16)
        outlined([(22,64),(x+27,64)],BLUE,10)
        d.polygon([(x+47,64),(x+22,45),(x+30,64),(x+22,83)],fill=CYAN,outline=NAVY)
        for dx,dy in [(-3,-23),(4,23),(16,-16),(18,16)]: diamond(x+dx,64+dy,6,WHITE if index%2 else BLUE)
    elif skill in ("protect", "shield_wall"):
        r=37+int(5*abs(.5-t)); color=GOLD if skill=="protect" else CYAN
        if skill=="protect":
            d.ellipse((64-r,64-r,64+r,64+r),outline=GOLD,width=2)
            pts=[(64,34),(86,44),(83,72),(64,94),(45,72),(42,44),(64,34)]
            outlined(pts,GOLD,6); d.polygon([(64,49),(76,56),(73,72),(64,82),(55,72),(52,56)],fill=WHITE,outline=NAVY)
        else:
            for x in (35,64,93):
                pts=[(x,27),(x+22,37),(x+19,67),(x,88),(x-19,67),(x-22,37),(x,27)]
                outlined(pts,CYAN,7); d.polygon([(x,43),(x+12,49),(x+10,65),(x,76),(x-10,65),(x-12,49)],fill="#356caa")
    elif skill == "prep_time":
        # Dagger receiving a fresh venom coat.
        outlined([(34,92),(83,43)],WHITE,7); line([(29,72),(53,96)],GOLD,6); diamond(84,42,7,GREEN)
        for x,y in [(54,38),(96,57),(44,57),(93,89)]: diamond(x+int(t*3),y,4,GREEN)
    elif skill == "inject_venom":
        # Distinct poison syringe/dagger plunged downward with toxic droplets.
        outlined([(39,30),(66,61),(83,96)],PURPLE,9); diamond(39,29,8,WHITE)
        line([(59,53),(73,67)],GREEN,5)
        for x,y in [(44,83),(94,77),(95,43),(27,68),(70,30)]: diamond(x,y+int((index%4)*2),5,GREEN)
        if index in (3,5,6,7):
            for dx in (-18,0,18): line([(83+dx,96),(83+dx,108)],GREEN,4)
    if im.getbbox():
        # Dark outline is included in alpha. Leave at least 8px at final size.
        margin=math.ceil(8*128/size)
        box=im.getbbox()
        if box[0]<margin or box[1]<margin or box[2]>128-margin or box[3]>128-margin:
            raise ValueError(f"{skill} frame {index} exceeds safe canvas margin: {box}")
    if size != 128: im=im.resize((size,size),Image.Resampling.NEAREST)
    return im

def main():
    source=ROOT/"art_source/fx"; out=ROOT/"assets/fx"; source.mkdir(parents=True,exist_ok=True); manifest={}
    for skill,(count,size,anchor,tier) in SKILLS.items():
        strip=Image.new("RGBA",(count*size,size),(0,0,0,0))
        for i in range(count): strip.alpha_composite(frame(skill,i,count,size),(i*size,0))
        strip.save(source/f"{skill}.png",optimize=True)
        directory=out/skill; directory.mkdir(parents=True,exist_ok=True)
        for i in range(count): strip.crop((i*size,0,(i+1)*size,size)).save(directory/f"frame_{i:02d}.png",optimize=True)
        manifest[skill]={"frames":count,"size":[size,size],"fps":14,"anchor":anchor,"tier":tier}
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    # A single review sheet against the required dark navy field.
    row_h=140; frame_px=128; label_w=118
    sheet=Image.new("RGB",(label_w+8*frame_px,len(SKILLS)*row_h),"#0e1a33"); d=ImageDraw.Draw(sheet)
    for j,(skill,(count,size,_,_)) in enumerate(SKILLS.items()):
        y=j*row_h; d.text((5,y+62),skill,fill="#ffffff")
        strip=Image.open(source/f"{skill}.png")
        for i in range(count):
            tile=strip.crop((i*size,0,(i+1)*size,size)).resize((frame_px,frame_px),Image.Resampling.NEAREST)
            sheet.paste(tile,(label_w+i*frame_px,y+6),tile)
        # 8px review grid, drawn over the navy background behind each tile.
        for gx in range(label_w, label_w+8*frame_px+1, 8): d.line((gx,y+5,gx,y+134),fill="#223252")
        for gy in range(y+5,y+135,8): d.line((label_w,gy,label_w+8*frame_px,gy),fill="#223252")
        for i in range(count):
            tile=strip.crop((i*size,0,(i+1)*size,size)).resize((frame_px,frame_px),Image.Resampling.NEAREST)
            sheet.paste(tile,(label_w+i*frame_px,y+6),tile)
    sheet.save(out/"_contact.png")

if __name__ == "__main__": main()
