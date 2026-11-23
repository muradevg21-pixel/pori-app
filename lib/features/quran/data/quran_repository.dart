import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quran_models.dart';

/// Loads the bundled, verified Quran data (see CONTENT_SOURCES.md).
/// Everything is offline: files live in assets/quran/.
class QuranRepository {
  final _surahCache = <int, List<Verse>>{};

  Future<QuranMeta> loadMeta() async {
    final raw = await rootBundle.loadString('assets/quran/meta.json');
    return QuranMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<Verse>> loadSurah(int n) async {
    final cached = _surahCache[n];
    if (cached != null) return cached;
    final file = n.toString().padLeft(3, '0');
    final raw = await rootBundle.loadString('assets/quran/surah/$file.json');
    final verses = await compute(_parseSurah, raw);
    _surahCache[n] = verses;
    return verses;
  }
}

List<Verse> _parseSurah(String raw) {
  final j = jsonDecode(raw) as Map<String, dynamic>;
  final bsm = j['bsm'] as int;
  return [
    for (final v in j['v'] as List)
      Verse.fromJson(v, bsm: v['n'] == 1 ? bsm : 0),
  ];
}

final quranRepositoryProvider = Provider((_) => QuranRepository());

final quranMetaProvider = FutureProvider<QuranMeta>(
    (ref) => ref.watch(quranRepositoryProvider).loadMeta());

final surahVersesProvider = FutureProvider.family<List<Verse>, int>(
    (ref, n) => ref.watch(quranRepositoryProvider).loadSurah(n));

/// Arabic-Indic digits for verse-end ornaments, e.g. 12 -> ١٢.
String arabicDigits(int n) => n
    .toString()
    .split('')
    .map((c) => String.fromCharCode(0x0660 + int.parse(c)))
    .join();
