#!/usr/bin/env python3
"""Builds PORI's offline Quran data from verified sources.

Sources (nothing is typed by hand or generated):
  * Arabic text      : Tanzil Project, Uthmani v1.1 (CC BY 3.0, verbatim only)
  * Surah/Juz meta   : Quran.com API v4
  * Bengali transl.  : Quran.com API v4, translation id 161
                       (Taisirul Quran, Tawheed Publication)
  * Word-by-word (bn): Quran.com API v4 word translations, language=bn

Usage:  python3 -I tool/fetch_quran_data.py <tanzil_uthmani_txt2_file> <out_dir>
"""
import json, re, sys, time, urllib.request
from pathlib import Path

API = "https://api.quran.com/api/v4"
TRANSLATION_ID = 161


def get(path):
    for attempt in range(5):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "pori-data-builder/1.0", "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception as e:  # network hiccup: back off and retry
            if attempt == 4:
                raise
            time.sleep(2 ** attempt)


def clean_translation(html):
    # Remove footnote markers like <sup foot_note=123>1</sup>, then any tags.
    t = re.sub(r"<sup[^>]*>.*?</sup>", "", html)
    t = re.sub(r"<[^>]+>", "", t)
    return re.sub(r"\s+", " ", t).strip()


def main(tanzil_file, out_dir):
    out = Path(out_dir)
    (out / "surah").mkdir(parents=True, exist_ok=True)

    # --- Tanzil Arabic text (kept verbatim) ---
    lines = Path(tanzil_file).read_text(encoding="utf-8").splitlines()
    notice = "\n".join(l for l in lines if l.startswith("#"))
    arabic = {}
    for l in lines:
        if l and not l.startswith("#"):
            s, a, text = l.split("|", 2)
            arabic[(int(s), int(a))] = text
    assert len(arabic) == 6236, len(arabic)
    # The Basmala is taken from Tanzil's own text (verse 1:1), never typed.
    bismillah = arabic[(1, 1)]
    (out / "TANZIL_LICENSE.txt").write_text(notice + "\n", encoding="utf-8")

    # --- Metadata ---
    chapters = get("/chapters?language=bn")["chapters"]
    assert len(chapters) == 114
    juzs = {j["juz_number"]: j for j in get("/juzs")["juzs"]}
    assert sorted(juzs) == list(range(1, 31))

    surahs = []
    total_words = 0
    for c in chapters:
        n = c["id"]
        verses = []
        page = 1
        while True:
            d = get(f"/verses/by_chapter/{n}?language=bn&words=true"
                    f"&word_fields=text_uthmani&translations={TRANSLATION_ID}"
                    f"&per_page=50&page={page}")
            verses += d["verses"]
            if not d["pagination"]["next_page"]:
                break
            page += 1
            time.sleep(0.15)
        assert len(verses) == c["verses_count"], (n, len(verses))
        # Length of the Basmala prefix Tanzil places in verse 1, so the app
        # can show it as a header. Surahs 95 and 97 carry an extra shadda
        # (connected-reading form), hence comparison without U+0651.
        bsm = 0
        if c["bismillah_pre"]:
            prefix = " ".join(arabic[(n, 1)].split(" ")[:4])
            assert prefix.replace("\u0651", "") == bismillah.replace("\u0651", ""), n
            bsm = len(prefix)

        out_verses = []
        for v in verses:
            a = v["verse_number"]
            words = [[w["text_uthmani"], w["translation"]["text"]]
                     for w in v["words"] if w["char_type_name"] == "word"]
            total_words += len(words)
            tr = [t for t in v["translations"] if t["resource_id"] == TRANSLATION_ID]
            assert len(tr) == 1, (n, a)
            out_verses.append({
                "n": a,
                "ar": arabic[(n, a)],
                "bn": clean_translation(tr[0]["text"]),
                "w": words,
                "juz": v["juz_number"],
                "page": v["page_number"],
                "sajdah": v["sajdah_number"] is not None,
            })
        doc = {
            "_source": "Arabic: Tanzil Quran Text (Uthmani 1.1), tanzil.net, "
                       "CC BY 3.0, verbatim. Translation & word meanings: "
                       "Quran.com API v4.",
            "n": n,
            "bsm": bsm,
            "v": out_verses,
        }
        (out / "surah" / f"{n:03d}.json").write_text(
            json.dumps(doc, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8")
        surahs.append({
            "n": n,
            "ar": c["name_arabic"],
            "en": c["name_simple"],
            "bn": c["translated_name"]["name"],
            "place": c["revelation_place"],
            "order": c["revelation_order"],
            "verses": c["verses_count"],
            "bismillah": c["bismillah_pre"],
        })
        print(f"surah {n:3d}: {len(out_verses)} verses", flush=True)

    juz_list = []
    for j in range(1, 31):
        m = juzs[j]["verse_mapping"]
        first_s = min(int(k) for k in m)
        last_s = max(int(k) for k in m)
        juz_list.append({
            "n": j,
            "start": [first_s, int(m[str(first_s)].split("-")[0])],
            "end": [last_s, int(m[str(last_s)].split("-")[1])],
            "verses": juzs[j]["verses_count"],
        })
    assert sum(j["verses"] for j in juz_list) == 6236

    meta = {
        "bismillah": bismillah,
        "sources": {
            "arabic": {"name": "Tanzil Quran Text (Uthmani, v1.1)",
                       "url": "https://tanzil.net", "license": "CC BY 3.0"},
            "translation_bn": {"name": "Taisirul Quran (Tawheed Publication)",
                               "via": "Quran.com API v4 (id 161)"},
            "words_bn": {"name": "Quran.com word-by-word (Bengali)",
                         "via": "Quran.com API v4"},
        },
        "surahs": surahs,
        "juz": juz_list,
    }
    (out / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"OK: 114 surahs, 6236 verses, {total_words} words, 30 juz")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
