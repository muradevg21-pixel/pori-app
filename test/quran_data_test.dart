import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pori/features/quran/data/quran_models.dart';

/// Guards the bundled religious data: counts must match the Mushaf and the
/// Arabic text must be identical to the Tanzil source file.
void main() {
  final meta = QuranMeta.fromJson(
      jsonDecode(File('assets/quran/meta.json').readAsStringSync()));

  final tanzil = <String, String>{};
  for (final l in File('tool/sources/tanzil-uthmani-1.1.txt')
      .readAsLinesSync()) {
    if (l.isEmpty || l.startsWith('#')) continue;
    final p = l.split('|');
    tanzil['${p[0]}:${p[1]}'] = p.sublist(2).join('|');
  }

  test('114 surahs, 30 juz, 6236 verses', () {
    expect(meta.surahs.length, 114);
    expect(meta.juz.length, 30);
    expect(meta.surahs.fold<int>(0, (a, s) => a + s.verseCount), 6236);
    expect(meta.juz.fold<int>(0, (a, j) => a + j.verseCount), 6236);
    expect(tanzil.length, 6236);
  });

  test('Arabic text is verbatim Tanzil and every verse is translated', () {
    var words = 0;
    for (final s in meta.surahs) {
      final f = 'assets/quran/surah/${s.number.toString().padLeft(3, '0')}.json';
      final j = jsonDecode(File(f).readAsStringSync()) as Map<String, dynamic>;
      final verses = j['v'] as List;
      expect(verses.length, s.verseCount, reason: 'surah ${s.number}');
      for (final v in verses) {
        final key = '${s.number}:${v['n']}';
        expect(v['ar'], tanzil[key], reason: key);
        expect((v['bn'] as String).trim(), isNotEmpty, reason: key);
        words += (v['w'] as List).length;
      }
    }
    expect(words, 77429);
  });

  test('Basmala header handling', () {
    expect(meta.bismillah, tanzil['1:1']);
    expect(meta.surah(1).hasBismillah, isFalse);
    expect(meta.surah(9).hasBismillah, isFalse);
  });
}
