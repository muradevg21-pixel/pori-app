#!/usr/bin/env python3
"""Builds assets/quran/reciters.json from the Quran.com API v4.

For every recitation it checks that all 6236 verse audio URLs follow the
pattern <path>/SSSAAA.mp3, so the app can build URLs offline, and spot-checks
that the first and last files exist on verses.quran.com.

Usage: python3 -I tool/fetch_reciters.py assets/quran/reciters.json
"""
import json, re, sys, urllib.request

API = "https://api.quran.com/api/v4"
AUDIO = "https://verses.quran.com/"
UA = {"User-Agent": "pori-data-builder/1.0"}
STYLE_BN = {"Murattal": "মুরাত্তাল", "Mujawwad": "মুজাওয়াদ", "Muallim": "মুআল্লিম (শিক্ষামূলক)"}


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return json.load(r)


def exists(url):
    req = urllib.request.Request(url, headers={**UA, "Range": "bytes=0-1"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.status in (200, 206) and "audio" in r.headers.get("Content-Type", "")


def main(out):
    recs = get(f"{API}/resources/recitations?language=en")["recitations"]
    result = []
    for r in sorted(recs, key=lambda x: x["id"]):
        files = get(f"{API}/quran/recitations/{r['id']}")["audio_files"]
        assert len(files) == 6236, (r["id"], len(files))
        path = None
        for f in files:
            s, a = map(int, f["verse_key"].split(":"))
            url = f["url"]
            url = "https:" + url if url.startswith("//") else AUDIO + url
            m = re.fullmatch(r"(.+)/(\d{3})(\d{3})\.mp3", url)
            assert m and int(m[2]) == s and int(m[3]) == a, f
            path = path or m[1]
            assert m[1] == path, (r["id"], url)
        try:
            ok = exists(f"{path}/001001.mp3") and exists(f"{path}/114006.mp3")
        except Exception as e:
            ok = False
        if not ok:
            print(f"SKIP {r['id']} {r['reciter_name']}: audio not verified at {path}")
            continue
        result.append({
            "id": r["id"],
            "name": r["reciter_name"],
            "style": STYLE_BN.get(r.get("style") or "", ""),
            "url": path,
        })
        print(f"{r['id']:3d} {r['reciter_name']} ({r.get('style')}) -> {path}", flush=True)
    doc = {
        "_source": "Quran.com API v4 recitations; audio served from verses.quran.com",
        "default": 7,
        "reciters": result,
    }
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=1)
    print(f"OK: {len(result)} reciters")


if __name__ == "__main__":
    main(sys.argv[1])
