#!/usr/bin/env python3
"""Generate compact, transparent pixel-art battle skill strips."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
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
NAVY, GOLD, WHITE, CYAN, RED, BLUE, GREEN, PURPLE = (
    "#0a1020", "#ffd45a", "#fff6d5", "#8de8ff", "#ff713f", "#61b7ff",
    "#8be35c", "#b873f5",
)


def ease(t):
    """Smoothstep easing for frame travel and scale."""
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def frame(skill, index, n, size):
    # Draw on a logical canvas then nearest-neighbour upscale for ultimate FX.
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    t = index / max(1, n - 1)
    e = ease(t)

    def line(points, fill, width=4):
        d.line(points, fill=fill, width=width)

    def poly(points, fill, outline=NAVY):
        d.polygon(points, fill=fill, outline=outline)

    def diamond(x, y, r, color):
        poly([(int(x), int(y-r)), (int(x+r), int(y)),
              (int(x), int(y+r)), (int(x-r), int(y))], color)

    def outlined(points, fill, width):
        line(points, NAVY, width + 2)
        line(points, fill, width)

    def star(x, y, r, color=WHITE):
        line([(x-r, y), (x+r, y)], NAVY, 6)
        line([(x, y-r), (x, y+r)], NAVY, 6)
        line([(x-r, y), (x+r, y)], color, 3)
        line([(x, y-r), (x, y+r)], color, 3)

    if skill == "power_slash":
        # Crescent grows into a full sweep, then thins while sparks trail it.
        phase = min(1.0, t / .66)
        progress = ease(phase)
        radius = 14 + 26 * progress
        sweep = -1 + 2 * progress
        start_angle = -58 + 16 * progress
        end_angle = 18 + 192 * progress
        pts = []
        for k in range(17):
            a = math.radians(start_angle + (end_angle-start_angle) * k / 16)
            pts.append((int(64 + radius * math.cos(a) + sweep*12),
                        int(64 + radius * math.sin(a) - sweep*10)))
        alpha = 255 if t < .66 else int(255 * (1 - ease((t-.66)/.34)))
        ink = (255, 212, 90, alpha)
        line(pts, NAVY, 11); line(pts, ink, 7)
        if progress > .22:
            line(pts[2:-2], (255, 246, 213, alpha), 3)
        for j in range(4):
            a = math.radians(30 + j*83 + progress*150)
            dist = 23 + j*8
            x, y = 64 + math.cos(a)*dist, 64 + math.sin(a)*dist
            diamond(x, y, 2 + (j % 2), WHITE if alpha > 100 else GOLD)

    elif skill == "aimed_shot":
        # Bolt eases from the left edge into the target; impact star blooms.
        travel = ease(min(1.0, t/.58))
        x = int(25 + 55*travel)
        alpha = 255 if t < .62 else int(255 * (1-ease((t-.62)/.38)))
        if t < .64:
            tail = int(8 + 18*travel)
            line([(x-tail, 64), (x+17, 64)], NAVY, 11)
            line([(x-tail, 64), (x+17, 64)], (141,232,255,alpha), 7)
            poly([(x+25,64),(x+11,55),(x+11,73)], (255,212,90,alpha))
        if t >= .4:
            bloom = ease(min(1.0, (t-.4)/.6))
            r = 5 + int(25*bloom)
            d.ellipse((80-r,64-r,80+r,64+r),outline=GOLD,width=2)
            for dx,dy in [(-1,-1),(0,-1),(1,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0)]:
                diamond(80+dx*r, 64+dy*r, 3+int(6*bloom),
                        WHITE if t < .82 else GOLD)

    elif skill == "fireball":
        # Ember swells and wobbles, then leaves an expanding ring and embers.
        if t < .54:
            q = ease(t/.54)
            r = 5 + 17*q
            x = int(31 + 33*ease(t/.54))
            y = int(64 + math.sin(t*math.pi*5)*4)
            for k in range(8):
                a = k*math.pi/4
                wobble = 1 + .09*math.sin(t*math.pi*8+k)
                xx, yy = x+math.cos(a)*r*wobble, y+math.sin(a)*r*wobble
                d.ellipse((int(xx-r*.55),int(yy-r*.55),int(xx+r*.55),int(yy+r*.55)),
                          fill=RED, outline=NAVY, width=2)
            d.ellipse((x-r*.55,y-r*.55,x+r*.55,y+r*.55),fill=GOLD,outline=NAVY,width=2)
            d.ellipse((x-r*.24,y-r*.24,x+r*.24,y+r*.24),fill=WHITE)
        else:
            q = ease((t-.54)/.46)
            radius = 8 + 43*q
            alpha = int(255*(1-q))
            d.ellipse((64-radius,64-radius,64+radius,64+radius),
                      outline=(255,113,63,alpha),width=5)
            for k in range(8):
                a=k*math.pi/4
                dist=12+40*q
                x,y=64+math.cos(a)*dist,64+math.sin(a)*dist
                diamond(x,y,max(2,4-int(q*2)),WHITE if k%2 else GOLD)

    elif skill == "frost_lance":
        # Spear streaks in; radial shards and an icy ring take over on impact.
        if t < .43:
            q=ease(t/.43)
            tip=int(24+54*q)
            outlined([(14,64),(tip,64)], BLUE, 8)
            poly([(tip+15,64),(tip-2,53),(tip+2,64),(tip-2,75)], CYAN)
            line([(15,58),(max(17,tip-8),58)], WHITE, 2)
        else:
            q=ease((t-.43)/.57)
            radius=8+36*q
            alpha=int(255*(1-.72*q))
            d.ellipse((64-radius,64-radius,64+radius,64+radius),
                      outline=(141,232,255,alpha),width=3)
            for k in range(8):
                a=k*math.pi/4 + .1
                dist=8+radius*.72
                x=64+math.cos(a)*dist
                y=64+math.sin(a)*dist+q*q*10
                shard=[(x,y-7),(x+4,y+3),(x,y+8),(x-4,y+3)]
                poly(shard, WHITE if k%2 else BLUE)
            if t < .7:
                d.ellipse((50,50,78,78),outline=WHITE,width=2)

    elif skill == "protect":
        # Pop from small to a slight overshoot, settle, then one ring pulse.
        scale = .36 + .82*ease(min(1,t/.48)) - (.15*ease(max(0,(t-.48)/.18)))
        cx,cy=64,64
        if t < .82:
            radius=int(8+48*ease(min(1,t/.82)))
            d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=GOLD,width=2)
        pts=[(cx,cy-30),(cx+22,cy-20),(cx+19,cy+8),(cx,cy+30),
             (cx-19,cy+8),(cx-22,cy-20),(cx,cy-30)]
        pts=[(cx+(x-cx)*scale,cy+(y-cy)*scale) for x,y in pts]
        alpha=255 if t<.55 else int(255*(1-ease((t-.55)/.45)))
        outlined(pts,(255,212,90,alpha),6)
        inner=[(cx,cy-14),(cx+11,cy-8),(cx+9,cy+8),(cx,cy+19),
               (cx-9,cy+8),(cx-11,cy-8)]
        poly([(cx+(x-cx)*scale,cy+(y-cy)*scale) for x,y in inner], WHITE)

    elif skill == "shield_wall":
        # Three shields rise and slide in sequentially, with a traveling pulse.
        for j, target_x in enumerate((35,64,93)):
            start=(j*2)/8
            if t < start:
                continue
            q=ease(max(0,min(1,(t-start)/.3)))
            alpha=255 if t<.75 else int(255*(1-ease((t-.75)/.25)))
            x=int(target_x + (j-1)*2*(1-q))
            y=int(89-26*q)
            pts=[(x,y-25),(x+19,y-16),(x+17,y+8),(x,y+27),
                 (x-17,y+8),(x-19,y-16),(x,y-25)]
            color=(97,183,255,alpha)
            outlined(pts,color,6)
            poly([(x,y-10),(x+10,y-5),(x+9,y+7),(x,y+17),(x-9,y+7),(x-10,y-5)],"#356caa")
            pulse_x=25+int(t*115)
            if abs(pulse_x-target_x)<8:
                d.ellipse((x-24,y-31,x+24,y+31),outline=WHITE,width=2)

    elif skill == "stab":
        # Dagger snaps to the hit; glint and rays grow, then contract.
        q=ease(min(1,t/.42))
        shift=int(27*(1-q))
        alpha=255 if t<.65 else int(255*(1-ease((t-.65)/.35)))
        outlined([(22+shift,82),(48+shift//2,64),(82,43)], (141,232,255,alpha), 7)
        line([(47+shift//2,64),(37+shift//2,54)], GOLD, 4)
        hit=(82,43)
        burst=math.sin(math.pi*min(1,t/.8))
        for a in (-2.5,-1.7,-.8,.1,.9,1.8,2.6):
            length=5+26*burst
            line([(hit[0]+math.cos(a)*5,hit[1]+math.sin(a)*5),
                  (hit[0]+math.cos(a)*length,hit[1]+math.sin(a)*length)],WHITE,2)
        star(82,43,4+int(24*burst), GOLD if t<.75 else WHITE)

    elif skill == "prep_time":
        # Blade appears in a quick draw; venom travels down it and drops fall.
        reveal=ease(min(1,t/.38))
        tip_y=int(97-57*reveal)
        outlined([(34,94),(tip_y-4,tip_y+4)], WHITE, 6)
        line([(31,76),(51,96)],GOLD,5)
        diamond(97-tip_y//4,tip_y-2,5,GREEN)
        for j,(x0,y0) in enumerate(((49,55),(58,61),(66,68),(74,73),(81,77))):
            appear=max(0,min(1,(t-(.12+j*.15))/.2))
            y=int(y0+max(0,t-(.12+j*.15))*58)
            if appear>0 and t < .9:
                line([(x0,y0),(x0,y)],GREEN,4)
                diamond(x0,y,4,GREEN)
                if index in (2,4): star(x0+4,y,3,WHITE)
        if t>.62:
            diamond(91,100-int(24*ease((t-.62)/.38)),3,GREEN)

    elif skill == "poke_up":
        # Shaft thrusts from below; hit burst expands and dust drifts outward.
        if t<.55:
            q=ease(t/.55)
            base=114
            tip=int(108-68*q)
            outlined([(64,base),(64,tip+9)], GOLD, 7)
            poly([(64,tip-9),(55,tip+10),(73,tip+10)],WHITE)
        else:
            q=ease((t-.55)/.45)
            radius=5+25*math.sin(math.pi*q)
            alpha=int(255*(1-q))
            star(64,43,int(4+8*math.sin(math.pi*q)),WHITE)
            for a in (-2.8,-2.1,-1.4,-.7,0,.7,1.4,2.1,2.8):
                line([(64+math.cos(a)*5,43+math.sin(a)*5),
                      (64+math.cos(a)*radius,43+math.sin(a)*radius)],(255,212,90,alpha),2)
            for j in range(4):
                x=64+(-1 if j%2 else 1)*(10+25*q)
                y=94+(j//2)*5-int(q*8)
                d.ellipse((x-7,y-3,x+7,y+3),fill=(141,232,255,alpha))

    elif skill == "inject_venom":
        # Syringe plunges down, purple contents flow, then green bubbles pop up.
        if t<.48:
            q=ease(t/.48)
            dy=int(-9+33*q)
            outlined([(34,25+dy),(63,55+dy),(81,82+dy)],PURPLE,8)
            diamond(34,25+dy,7,WHITE)
            line([(54,47+dy),(68,61+dy)],GREEN,4)
            line([(59,54+dy),(73,68+dy)],(184,115,245,255),3)
        else:
            q=ease((t-.48)/.52)
            outlined([(34,20),(63,50),(81,77)],PURPLE,8)
            line([(57,44),(75,63)],GREEN,4)
            for j in range(5):
                phase=(q*1.4+j*.21)%1
                x=80+int(math.sin(j*2.2+q*4)*20)
                y=int(101-phase*70)
                radius=2+(j%3)
                d.ellipse((x-radius,y-radius,x+radius,y+radius),fill=GREEN,outline=NAVY)
                if phase>.86:
                    star(x,y,radius+2,WHITE)

    # Fade the whole effect at the tail without changing palette or outlines.
    fade = 1.0 if t < .78 else max(.12, 1 - .82*ease((t-.78)/.22))
    if fade < .999:
        alpha = im.getchannel("A").point(lambda a: int(a*fade))
        im.putalpha(alpha)
    # Keep an 8px transparent margin at the final frame size.
    bbox=im.getchannel("A").getbbox()
    if bbox:
        margin=math.ceil(8*128/size)
        if bbox[0]<margin or bbox[1]<margin or bbox[2]>128-margin or bbox[3]>128-margin:
            raise ValueError(f"{skill} frame {index} exceeds safe canvas margin: {bbox}")
    if size != 128:
        im=im.resize((size,size),Image.Resampling.NEAREST)
    return im


def make_contact_sheet(source, out, manifest):
    scale, label_w, row_h = 2, 150, 276
    tile = 128*scale
    sheet=Image.new("RGB",(label_w+8*tile,len(manifest)*row_h),"#0e1a33")
    d=ImageDraw.Draw(sheet)
    for j,(skill,info) in enumerate(manifest.items()):
        y=j*row_h
        d.text((5,y+128),skill,fill="white")
        strip=Image.open(source/f"{skill}.png")
        count,size=info["frames"],info["size"][0]
        for i in range(count):
            im=strip.crop((i*size,0,(i+1)*size,size)).resize((tile,tile),Image.Resampling.NEAREST)
            sheet.paste(im,(label_w+i*tile,y+6),im)
        # Grid lines are 8 logical pixels (16 review pixels).
        for gx in range(label_w,label_w+8*tile+1,16):
            d.line((gx,y+5,gx,y+tile+6),fill="#223252")
        for gy in range(y+5,y+tile+7,16):
            d.line((label_w,gy,label_w+8*tile,gy),fill="#223252")
        # Re-paste art over the grid, preserving a clean 2x pixel preview.
        for i in range(count):
            im=strip.crop((i*size,0,(i+1)*size,size)).resize((tile,tile),Image.Resampling.NEAREST)
            sheet.paste(im,(label_w+i*tile,y+6),im)
    sheet.save(out/"_contact.png")


def make_motion_sheet(source, out, manifest):
    scale, label_w, row_h = 2, 150, 276
    tile=128*scale
    sheet=Image.new("RGB",(label_w+8*tile,len(manifest)*row_h),"#0e1a33")
    d=ImageDraw.Draw(sheet)
    for j,(skill,info) in enumerate(manifest.items()):
        y=j*row_h
        d.text((5,y+128),skill,fill="white")
        count,size=info["frames"],info["size"][0]
        strip=Image.open(source/f"{skill}.png").convert("RGBA")
        frames=[strip.crop((i*size,0,(i+1)*size,size)).resize((128,128),Image.Resampling.NEAREST)
                for i in range(count)]
        for i in range(count-1):
            a=Image.new("RGBA",frames[i].size,"#0e1a33"); a.alpha_composite(frames[i])
            b=Image.new("RGBA",frames[i+1].size,"#0e1a33"); b.alpha_composite(frames[i+1])
            diff=ImageChops.difference(a.convert("RGB"),b.convert("RGB"))
            # Boost subtle channel changes while keeping changed pixels legible.
            diff=diff.point(lambda c: min(255,c*3))
            tile_im=diff.resize((tile,tile),Image.Resampling.NEAREST)
            sheet.paste(tile_im,(label_w+i*tile,y+6))
        for gx in range(label_w,label_w+8*tile+1,16):
            d.line((gx,y+5,gx,y+tile+6),fill="#223252")
        for gy in range(y+5,y+tile+7,16):
            d.line((label_w,gy,label_w+8*tile,gy),fill="#223252")
    sheet.save(out/"_motion.png")


def main():
    source=ROOT/"art_source/fx"
    out=ROOT/"assets/fx"
    source.mkdir(parents=True,exist_ok=True)
    out.mkdir(parents=True,exist_ok=True)
    manifest={}
    for skill,(count,size,anchor,tier) in SKILLS.items():
        strip=Image.new("RGBA",(count*size,size),(0,0,0,0))
        for i in range(count):
            strip.alpha_composite(frame(skill,i,count,size),(i*size,0))
        strip.save(source/f"{skill}.png",optimize=True)
        directory=out/skill
        directory.mkdir(parents=True,exist_ok=True)
        for i in range(count):
            strip.crop((i*size,0,(i+1)*size,size)).save(directory/f"frame_{i:02d}.png",optimize=True)
        manifest[skill]={"frames":count,"size":[size,size],"fps":16,"anchor":anchor,"tier":tier}
    (out/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    make_contact_sheet(source,out,manifest)
    make_motion_sheet(source,out,manifest)


if __name__ == "__main__":
    main()
