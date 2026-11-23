#!/usr/bin/env python3
"""Downloads a Bengali tafsir from the Quran.com API v4 and stores it verbatim
(HTML as published) as assets/tafsir/<id>/<SSS>.json = {"v": {"1": html, ...}}.

Usage: python3 -I tool/fetch_tafsir.py <tafsir_id> <out_dir>
"""
import json, sys, time, urllib.request
from pathlib import Path

API = "https://api.quran.com/api/v4"
UA = {"User-Agent": "pori-data-builder/1.0", "Accept": "application/json"}


def get(path):
    for attempt in range(5):
        try:
            req = urllib.request.Request(API + path, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception:
            if attempt == 4:
                raise
            time.sleep(2 ** attempt)


def main(tid, out_dir):
    out = Path(out_dir) / str(tid)
    out.mkdir(parents=True, exist_ok=True)
    chapters = get("/chapters")["chapters"]
    total = empty = 0
    for c in chapters:
        n, verses = c["id"], {}
        page = 1
        while True:
            d = get(f"/tafsirs/{tid}/by_chapter/{n}?per_page=50&page={page}")
            for t in d["tafsirs"]:
                s, a = map(int, t["verse_key"].split(":"))
                assert s == n
                verses[str(a)] = t["text"] or ""
            if not d["pagination"]["next_page"]:
                break
            page += 1
            time.sleep(0.1)
        assert len(verses) == c["verses_count"], (n, len(verses))
        total += len(verses)
        empty += sum(1 for v in verses.values() if not v.strip())
        (out / f"{n:03d}.json").write_text(
            json.dumps({"v": verses}, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8")
    print(f"OK tafsir {tid}: {total} verses, {empty} empty (grouped with neighbours)")


if __name__ == "__main__":
    main(int(sys.argv[1]), sys.argv[2])
