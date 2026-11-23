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
| Tafsir | _TBD_ | _TBD_ | planned | — | — |
| Recitation audio | _TBD_ | _TBD_ | planned | — | — |
| Tajweed lessons | _TBD_ | _TBD_ | planned | — | — |
| Makhraj lessons | _TBD_ | _TBD_ | planned | — | — |

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
- [ ] Scholar review of the app's presentation of the text (name, date above)
