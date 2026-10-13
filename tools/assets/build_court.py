"""Rebuild pixel-sharp portrait court art from the shared screen projection.
Build-time dependency: Pillow. Gameplay does not use Python.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
LAYOUT = json.loads((ROOT / 'assets/table/layout.json').read_text())
W, H = 360, 640
INK = '#0b1020'
EDGE = '#e4f3d7'

def point(x, depth, height=0):
    far_x, far_y = LAYOUT['far_center']
    near_x, near_y = LAYOUT['near_center']
    cx = far_x + (near_x - far_x) * depth
    cy = far_y + (near_y - far_y) * depth ** LAYOUT['depth_power']
    half = LAYOUT['far_half_width'] + (LAYOUT['near_half_width'] - LAYOUT['far_half_width']) * depth
    skew = LAYOUT['far_skew'] + (LAYOUT['near_skew'] - LAYOUT['far_skew']) * depth
    return round(cx + x * half), round(cy + x * skew - height)

def polygon(draw, points, fill):
    draw.polygon(points, fill=fill)

def line(draw, a, b, fill, width=1):
    draw.line([a, b], fill=fill, width=width)

background = Image.new('RGBA', (W, H), '#101a30')
bg = ImageDraw.Draw(background)
bg.rectangle((0, 0, W, 182), fill='#14233f')
bg.rectangle((0, 155, W, 188), fill='#111d34')
bg.rectangle((0, 188, W, H), fill='#1b2538')
bg.rectangle((0, 184, W, 188), fill='#23314a')
for y in range(190, H, 36):
    bg.line((0, y, W, y), fill='#202b3e', width=1)
for x in (15, 176, 343):
    bg.rectangle((x, 0, x + 3, 158), fill='#101b32')
for x in (72, 266):
    bg.line((x, 188, x - 34, H), fill='#202b3e')
background.save(ROOT / 'assets/backgrounds/background_main.png')

table = Image.new('RGBA', (W, H))
td = ImageDraw.Draw(table)
far_left, far_right = point(-1, 0), point(1, 0)
near_left, near_right = point(-1, 1), point(1, 1)
polygon(td, [point(-1.1, 1), point(1.1, 1), (W, 487), (0, 499)], '#0d1828')
# Legs and deep apron sit behind the playing surface.
polygon(td, [far_left, far_right, near_right, near_left], '#0b1322')
polygon(td, [near_left, near_right, (near_right[0], near_right[1] + 19), (near_left[0], near_left[1] + 19)], '#10283b')
for x in (-0.93, 0.93):
    top = point(x, 0.94)
    td.rectangle((top[0]-4, top[1]+5, top[0]+4, min(H, top[1]+92)), fill='#101a2c')
polygon(td, [far_left, far_right, near_right, near_left], '#146d7a')
polygon(td, [far_left, far_right, point(1, .5), point(-1, .5)], '#168397')
polygon(td, [point(-1, .5), point(1, .5), near_right, near_left], '#176f7e')
# A restrained two-tone sheen preserves the pixel look.
polygon(td, [point(-.72, .03), point(-.58, .03), point(-.66, .98), point(-.87, .98)], '#187d89')
for a,b in [(far_left,far_right),(far_right,near_right),(near_right,near_left),(near_left,far_left)]:
    line(td,a,b,EDGE,3)
line(td, point(0,0), point(0,1), '#b8e8dc', 2)
line(td, (near_left[0],near_left[1]+3), (near_right[0],near_right[1]+3), '#14364b', 3)
table.save(ROOT / 'assets/table/table_main.png')

net = Image.new('RGBA', (W, H))
nd = ImageDraw.Draw(net)
d = LAYOUT['net_depth']
left, right = point(-1.04, d), point(1.04, d)
top_left, top_right = (left[0], left[1]-27), (right[0], right[1]-27)
polygon(nd, [top_left, top_right, right, left], '#09263c')
for i in range(25):
    t = i / 24
    x = round(top_left[0] + (top_right[0]-top_left[0])*t)
    y1 = round(top_left[1] + (top_right[1]-top_left[1])*t)
    y2 = round(left[1] + (right[1]-left[1])*t)
    line(nd,(x,y1+4),(x,y2-2),'#388ba3')
for t in (0.28, 0.52, 0.76):
    a = (left[0], round(top_left[1]+(left[1]-top_left[1])*t))
    b = (right[0], round(top_right[1]+(right[1]-top_right[1])*t))
    line(nd,a,b,'#388ba3')
line(nd, top_left, top_right, EDGE, 3)
line(nd, left, right, '#081b2d', 3)
for a,b in [(top_left,left),(top_right,right)]:
    line(nd,(a[0],a[1]-5),(b[0],b[1]+7),INK,5)
net.save(ROOT / 'assets/table/table_net.png')

ball = Image.new('RGBA',(12,12)); bd=ImageDraw.Draw(ball)
bd.rectangle((3,0,8,11), fill=INK); bd.rectangle((0,3,11,8),fill=INK)
bd.rectangle((1,2,10,9),fill='#fff4d2'); bd.rectangle((2,1,9,10),fill='#fff4d2')
bd.rectangle((3,2,5,3),fill='#ffffff')
ball.save(ROOT / 'assets/ball/ball_main.png')
shadow = Image.new('RGBA',(16,6)); sd=ImageDraw.Draw(shadow)
sd.ellipse((0,1,15,5),fill='#113846')
shadow.save(ROOT / 'assets/ball/ball_shadow.png')
print('Built background/table/net/ball from assets/table/layout.json')
