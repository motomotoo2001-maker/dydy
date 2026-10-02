#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
FILES=[
 ("PAWN","capture_pawn.png"),("KNIGHT","capture_knight.png"),("BISHOP","capture_bishop.png"),
 ("ROOK","capture_rook.png"),("QUEEN","capture_queen.png"),("KING","capture_king.png")
]
thumb_w,thumb_h=640,360
canvas=Image.new("RGB",(thumb_w*3,thumb_h*2),(18,18,18))
draw=ImageDraw.Draw(canvas)
for i,(label,name) in enumerate(FILES):
    im=Image.open(ROOT/name).convert("RGB").resize((thumb_w,thumb_h),Image.Resampling.LANCZOS)
    x=(i%3)*thumb_w; y=(i//3)*thumb_h
    canvas.paste(im,(x,y))
    draw.rectangle((x+12,y+12,x+180,y+52),fill=(0,0,0))
    draw.text((x+22,y+20),label,fill="white")
out=ROOT/"capture_contact_sheet.png"
canvas.save(out,quality=95)
print(f"CAPTURE_CONTACT_SHEET_PASS {out} {canvas.size[0]}x{canvas.size[1]}")
