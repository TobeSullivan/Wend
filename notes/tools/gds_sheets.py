#!/usr/bin/env python3
"""
gds_sheets.py - build labeled contact-sheet montages of GDS store thumbnails,
grouped by Wend slot, so the art can be reviewed at a glance.

Scrapes the store for thumbnails (public CDN, no login), buckets packs into
slots, downloads the thumbnails for each slot, and tiles them into labeled
PNG sheets: sheet_<slot>_<n>.png. Each cell shows the pack name + price.

Run:
    pip install pillow
    python gds_sheets.py
Then upload the sheet_*.png files.

Optional: python gds_sheets.py library.html   # marks owned packs in the labels
"""
import sys, re, csv, time, io, urllib.request
from PIL import Image, ImageDraw, ImageFont

BASE = "https://www.gamedeveloperstudio.com"
LIST = BASE + "/index.php?page={page}&resultsperpage=56"
UA   = "Mozilla/5.0 (asset-catalogue sweep; personal use)"

LINK  = re.compile(r"viewgraphic\.php\?page-name=(?P<slug>[^&']+)&item=(?P<id>[^']+)'")
NAME  = re.compile(r"title='(?P<name>[^']*)'[^>]*class='thumbnail'", re.S)
THUMB = re.compile(r"<img[^>]*?src='(https://gdsthumbnails\.b-cdn\.net/[^']+)'[^>]*class='thumbnail'", re.S)
STD   = re.compile(r"class='thumbPrice'>\s*\$(\d+\.\d{2})")
GDS   = re.compile(r"<b>\$(\d+\.\d{2})</b>")
TOTAL = re.compile(r"total of\s+([\d,]+)\s+game asset packs")

# slot filters (kept a touch tighter than the catalogue to cut sheet noise)
SLOTS = {
 "tower": r"tower|turret|\bfort\b|ballista|catapult|trebuch|\bcannon|castle",
 "mob":   r"top.?down.*(monster|enemy|creature|character|animal|animated)|animated.*(monster|enemy|creature|slime|zombie|skeleton|goblin|orc|dragon|fish|shark|crab|octopus|spider|bug|insect|cow|pig|sheep|horse|chicken|cat|dog|bird|frog|bear|wolf|fox|rabbit|whale|turtle|mech|robot)|monster|\bboss\b|slime|zombie|skeleton|goblin|undead|ghoul",
 "board": r"top.?down.*(tile|environment|level|ground|grass|sand|water|road|path|biome|terrain)|tile\s?set|background creator|map (making|maker)|sea level|underwater|beach|brick|asphalt",
 "fx":    r"\beffect|explosion|projectile|fireball|\bspark|impact|\bblast|\bbeam|charge|flame|lightning|particle|\bmagic\b",
 "flair": r"\bgui\b|interface|button|\bframe\b|banner|\bpanel\b|\bhud\b|speech bubble|sign ?post|icon",
}

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")

def scrape():
    first = get(LIST.format(page=0))
    tm = TOTAL.search(first); total = int(tm.group(1).replace(",","")) if tm else 0
    pages = (total+55)//56 if total else 23
    seen, rows = set(), []
    for p in range(pages):
        html = (first if p==0 else get(LIST.format(page=p))).replace("\\'","'").replace('\\"','"')
        links = list(LINK.finditer(html))
        for i,m in enumerate(links):
            start=m.start(); end=links[i+1].start() if i+1<len(links) else len(html)
            seg=html[start:end]; pre=html[max(0,start-600):start]
            nm=NAME.search(seg); th=THUMB.search(seg)
            if not nm or not th or m.group('id') in seen: continue
            seen.add(m.group('id'))
            s=STD.search(seg); b=GDS.findall(pre)
            rows.append({"name":re.sub(r"\s+"," ",nm.group('name')).strip(),
                         "id":m.group('id'),"thumb":th.group(1),
                         "std":s.group(1) if s else "","gds":b[-1] if b else ""})
        print(f"  page {p+1}/{pages}: {len(rows)} packs"); time.sleep(0.5)
    return rows

def fetch_img(url):
    try:
        req=urllib.request.Request(url, headers={"User-Agent":UA})
        with urllib.request.urlopen(req,timeout=30) as r:
            return Image.open(io.BytesIO(r.read())).convert("RGB")
    except Exception as e:
        print("   ! thumb failed:", url, e); return None

def make_sheets(slot, rows, owned, cols=6, cell=190, pad=8, lab=34, per=48):
    try: font=ImageFont.truetype("arial.ttf",12)
    except Exception: font=ImageFont.load_default()
    for pg in range((len(rows)+per-1)//per):
        chunk=rows[pg*per:(pg+1)*per]
        n=len(chunk); rowsN=(n+cols-1)//cols
        W=cols*(cell+pad)+pad; H=rowsN*(cell+lab+pad)+pad
        sheet=Image.new("RGB",(W,H),(36,51,62)); d=ImageDraw.Draw(sheet)
        for i,r in enumerate(chunk):
            cx=pad+(i%cols)*(cell+pad); cy=pad+(i//cols)*(cell+lab+pad)
            im=fetch_img(r["thumb"])
            if im:
                im.thumbnail((cell,cell)); ox=cx+(cell-im.width)//2; oy=cy+(cell-im.height)//2
                sheet.paste(im,(ox,oy))
            tags=[]
            if r["id"] in owned: tags.append("OWNED")
            if r["gds"]=="0.00": tags.append("FREE+")
            price=f"${r['std']}" if r["std"] else "$?"
            nm=r["name"][:34]
            d.text((cx,cy+cell+2),nm,fill=(235,235,235),font=font)
            d.text((cx,cy+cell+16),f"{price} {' '.join(tags)}".strip(),fill=(255,210,120),font=font)
        out=f"sheet_{slot}_{pg+1}.png"; sheet.save(out); print("wrote",out)

def main():
    owned=set()
    if len(sys.argv)>1:
        owned=set(re.findall(r"item=([^'&\"]+)", open(sys.argv[1],encoding='utf-8',errors='replace').read().replace("\\'","'")))
    print("scraping store for thumbnails...")
    rows=scrape()
    for slot,pat in SLOTS.items():
        sel=[r for r in rows if re.search(pat,r["name"].lower())]
        print(f"\n{slot}: {len(sel)} packs -> sheets")
        make_sheets(slot,sel,owned)

if __name__=="__main__":
    main()
