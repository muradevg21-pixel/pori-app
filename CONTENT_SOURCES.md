# PORI — Content Sources, Licensing & Scholarly Review

**Rule:** No Quranic text, translation, transliteration, word meaning, Tafsir or
Hadith may be written by hand or generated. Every religious text in the app must
come from a verified, attributed source listed below, and must be reviewed by a
qualified scholar before release.

## Status legend
- `planned` — candidate source, not yet imported
- `imported` — data in the app, review pending
- `reviewed` — checked by a named scholar (date recorded)

## Religious content

| Content | Source | License / permission | Status | Reviewed by | Date |
|---|---|---|---|---|---|
| Arabic Quran text | Tanzil Quran Text, Uthmani v1.1 (tanzil.net). Raw file: `tool/sources/tanzil-uthmani-1.1.txt`, SHA-256 `7f30c647…a7f326` | CC BY 3.0, verbatim only, attribution + link required (`assets/quran/TANZIL_LICENSE.txt`) ✅ | imported | — | — |
| Surah & Juz metadata | Quran.com API v4 (`/chapters?language=bn`, `/juzs`) | Factual data | imported | — | — |
| Bengali translation | Taisirul Quran (Tawheed Publication) via Quran.com API v4, id 161 | ⚠️ Publisher copyright. **Written permission from Tawheed Publication / Quran.com needed before Play Store release** | imported | — | — |
| Bengali pronunciation | _No verified source chosen yet_ | _TBD_ | planned | — | — |
| Word-by-word meaning (bn) | Quran.com API v4 word translations | ⚠️ Confirm reuse terms with Quran.com before release | imported | — | — |
| Tafsir (bundled, offline) | Tafsir Ahsanul Bayaan (Bayaan Foundation) via Quran.com API v4, id 165. Stored verbatim (HTML) in `assets/tafsir/165/`, built by `tool/fetch_tafsir.py` | ⚠️ Publisher copyright. **Permission needed before Play Store release** | imported | — | — |
| Tafsir (online, cached on device) | Abu Bakr Zakaria (id 166), Ibn Kathir – Tawheed Publication (id 164), Fathul Majid (id 381), fetched from Quran.com API on first use | ⚠️ Publisher copyright. Confirm with Quran.com / publishers before release | available on demand | — | — |
| Recitation audio | Quran.com API v4 recitations; files from verses.quran.com (9 reciters, list in `assets/quran/reciters.json`, built by `tool/fetch_reciters.py`) | ⚠️ Reciters'/publishers' rights. Confirm reuse terms with Quran.com / QuranicAudio before release | imported (streamed / downloaded on demand, not bundled) | — | — |
| Tajweed lessons (7) | DRAFT written for PORI (`tool/build_lessons.py` → `assets/learn/courses.json`). Quran examples are verse references, words shown from the verified data | Own content | ⚠️ draft — **needs Qari/Alim review** | — | — |
| Makhraj lessons (4) + Arabic letters (2) + quizzes (33 questions) | DRAFT written for PORI (same file) | Own content | ⚠️ draft — **needs Qari/Alim review** | — | — |

## Fonts & assets

| Asset | Source | License |
|---|---|---|
| Amiri (Arabic) | github.com/aliftype/amiri via Google Fonts | SIL OFL 1.1 (`assets/fonts/OFL-Amiri.txt`) |
| Hind Siliguri (Bengali) | Indian Type Foundry via Google Fonts | SIL OFL 1.1 (`assets/fonts/OFL-HindSiliguri.txt`) |
| Icons | Flutter Material Icons | Apache 2.0 |

The Basmala preview on the settings screen uses the standard Unicode
character U+FDFD rendered with the Amiri font. It is not hand-typed text.

## Data build & integrity

- Built by `tool/fetch_quran_data.py` (reproducible).
- Arabic text is stored exactly as Tanzil publishes it. The Basmala that Tanzil
  places at the start of verse 1 is shown as a surah header in the reader; this
  is display only, the stored text is unchanged.
- Translation: HTML tags/footnote markers would be stripped (none present in id 161).
- `test/quran_data_test.dart` checks: 114 surahs, 30 juz, 6236 verses,
  77,429 words, and every Arabic verse identical to the Tanzil source file.

## Before Play Store release (checklist)

- [ ] Written permission for the Bengali translation
- [ ] Confirm Quran.com word-by-word reuse terms
- [ ] Confirm recitation audio reuse terms (Quran.com / QuranicAudio)
- [ ] Permission for tafsir texts (Ahsanul Bayaan bundled; others streamed)
- [ ] Qari/Alim review of every lesson and quiz. To mark one reviewed, set its
      `review` to `{"status": "reviewed", "reviewer": "<name>", "date": "<yyyy-mm-dd>"}`
      in `tool/build_lessons.py` and rebuild.
- [ ] Scholar review of the app's presentation of the text (name, date above)
