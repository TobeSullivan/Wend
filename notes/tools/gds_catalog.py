#!/usr/bin/env python3
"""
gds_catalog.py - scrape the Game Developer Studio store into a CSV index.

Captures PACK-LEVEL data only (name, id, slug, url, standard + GDS+ price). It
does NOT see what is inside a pack - contents get enumerated per-pack from the
downloaded files later, for the handful of packs we adopt.

Note: price_gds_plus == 0.00 means the pack is FREE with your GDS+ membership.

Usage:
    python gds_catalog.py                  # scrape the public store -> gds_catalog.csv
    python gds_catalog.py library.html     # ...and mark which packs you own

To mark ownership: log in, open your Library page (library.php), save it
(Ctrl+S -> "Webpage, HTML only") as library.html in this folder, then pass it
as the argument. The script reads the owned item-ids out of it.

Pure standard library - nothing to install.
"""
import sys, re, csv, time, urllib.request

BASE = "https://www.gamedeveloperstudio.com"
LIST = BASE + "/index.php?page={page}&resultsperpage=56"   # plain paging; orderby breaks it
UA   = "Mozilla/5.0 (asset-catalogue sweep; personal use)"

# Grid cards are emitted inside escaped JS strings -> quotes arrive as \' and \"
def unescape(html):
    return html.replace("\\'", "'").replace('\\"', '"')

# Anchor on the product link; IDs come in two formats (with/without leading _)
LINK  = re.compile(r"viewgraphic\.php\?page-name=(?P<slug>[^&']+)&item=(?P<id>[^']+)'")
NAME  = re.compile(r"title='(?P<name>[^']*)'[^>]*class='thumbnail'", re.S)
STD   = re.compile(r"class='thumbPrice'>\s*\$(\d+\.\d{2})")   # standard price (after link)
GDS   = re.compile(r"<b>\$(\d+\.\d{2})</b>")                  # GDS+ price (before link)
TOTAL = re.compile(r"total of\s+([\d,]+)\s+game asset packs")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def parse_page(html):
    html = unescape(html)
    links = list(LINK.finditer(html))
    rows = []
    for i, m in enumerate(links):
        start = m.start()
        end = links[i + 1].start() if i + 1 < len(links) else len(html)
        seg = html[start:end]
        pre = html[max(0, start - 600):start]
        nm = NAME.search(seg)
        if not nm:                      # e.g. the flash-offer banner link has no thumbnail img
            continue
        s = STD.search(seg)
        bolds = GDS.findall(pre)
        rows.append({
            "name": re.sub(r"\s+", " ", nm.group("name")).strip(),
            "item_id": m.group("id"),
            "slug": m.group("slug"),
            "url": f"{BASE}/graphics/viewgraphic.php?page-name={m.group('slug')}&item={m.group('id')}",
            "price_standard": s.group(1) if s else "",
            "price_gds_plus": bolds[-1] if bolds else "",
        })
    return rows


def owned_ids(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return set(re.findall(r"item=([^'&\"]+)", unescape(f.read())))


def main():
    first = get(LIST.format(page=0))
    tm = TOTAL.search(first)
    total = int(tm.group(1).replace(",", "")) if tm else 0
    pages = (total + 55) // 56 if total else 23
    print(f"store reports {total or '?'} packs -> scraping {pages} pages")

    seen, rows = set(), []
    for p in range(pages):
        html = first if p == 0 else get(LIST.format(page=p))
        new = [r for r in parse_page(html) if r["item_id"] not in seen]
        for r in new:
            seen.add(r["item_id"])
        rows.extend(new)
        print(f"  page {p+1}/{pages}: +{len(new)} (running total {len(rows)})")
        time.sleep(0.6)

    owned = owned_ids(sys.argv[1]) if len(sys.argv) > 1 else set()
    for r in rows:
        r["owned"] = "yes" if r["item_id"] in owned else ""

    with open("gds_catalog.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=[
            "name", "item_id", "slug", "price_standard", "price_gds_plus", "owned", "url"])
        w.writeheader()
        w.writerows(rows)

    owned_n = sum(1 for r in rows if r["owned"])
    free_n  = sum(1 for r in rows if r["price_gds_plus"] == "0.00")
    print(f"\nwrote gds_catalog.csv  ({len(rows)} packs, {owned_n} owned, {free_n} free with GDS+)")
    if total and len(rows) < total * 0.9:
        print("WARNING: parsed far fewer rows than the store total - send me the CSV.")


if __name__ == "__main__":
    main()
