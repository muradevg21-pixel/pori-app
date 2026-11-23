import 'package:flutter/foundation.dart';

@immutable
class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.nameLatin,
    required this.meaningBn,
    required this.isMakki,
    required this.verseCount,
    required this.hasBismillah,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        number: j['n'] as int,
        nameArabic: j['ar'] as String,
        nameLatin: j['en'] as String,
        meaningBn: j['bn'] as String,
        isMakki: j['place'] == 'makkah',
        verseCount: j['verses'] as int,
        hasBismillah: j['bismillah'] as bool,
      );

  final int number;
  final String nameArabic;
  final String nameLatin;
  final String meaningBn;
  final bool isMakki;
  final int verseCount;
  final bool hasBismillah;
}

@immutable
class JuzInfo {
  const JuzInfo(this.number, this.startSurah, this.startVerse, this.endSurah,
      this.endVerse, this.verseCount);

  factory JuzInfo.fromJson(Map<String, dynamic> j) {
    final s = (j['start'] as List).cast<int>();
    final e = (j['end'] as List).cast<int>();
    return JuzInfo(j['n'] as int, s[0], s[1], e[0], e[1], j['verses'] as int);
  }

  final int number;
  final int startSurah, startVerse, endSurah, endVerse, verseCount;
}

@immutable
class Word {
  const Word(this.arabic, this.meaningBn);
  final String arabic;
  final String meaningBn;
}

@immutable
class Verse {
  const Verse({
    required this.number,
    required this.arabic,
    required this.translationBn,
    required this.words,
    required this.juz,
    required this.sajdah,
    this.bismillahPrefixLength = 0,
  });

  factory Verse.fromJson(Map<String, dynamic> j, {int bsm = 0}) => Verse(
        number: j['n'] as int,
        arabic: j['ar'] as String,
        translationBn: j['bn'] as String,
        words: [
          for (final w in j['w'] as List)
            Word((w as List)[0] as String, w[1] as String),
        ],
        juz: j['juz'] as int,
        sajdah: j['sajdah'] as bool,
        bismillahPrefixLength: bsm,
      );

  final int number;
  final String arabic;
  final String translationBn;
  final List<Word> words;
  final int juz;
  final bool sajdah;

  /// Characters of the Basmala that Tanzil places at the start of verse 1.
  /// Used only to show it as a header; the text itself is never altered.
  final int bismillahPrefixLength;

  String get arabicForDisplay => bismillahPrefixLength > 0 &&
          arabic.length > bismillahPrefixLength
      ? arabic.substring(bismillahPrefixLength).trimLeft()
      : arabic;
}

@immutable
class QuranMeta {
  const QuranMeta(this.bismillah, this.surahs, this.juz);

  factory QuranMeta.fromJson(Map<String, dynamic> j) => QuranMeta(
        j['bismillah'] as String,
        [for (final s in j['surahs'] as List) SurahInfo.fromJson(s)],
        [for (final s in j['juz'] as List) JuzInfo.fromJson(s)],
      );

  /// Standard Basmala, used as the display header of surahs (not a verse).
  final String bismillah;
  final List<SurahInfo> surahs;
  final List<JuzInfo> juz;

  SurahInfo surah(int n) => surahs[n - 1];
}
