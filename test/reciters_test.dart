import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pori/features/audio/reciters.dart';

void main() {
  final j = jsonDecode(File('assets/quran/reciters.json').readAsStringSync())
      as Map<String, dynamic>;
  final list = [for (final r in j['reciters'] as List) Reciter.fromJson(r)];

  test('reciter list is valid', () {
    expect(list, isNotEmpty);
    expect(list.map((r) => r.id).toSet().length, list.length);
    expect(list.any((r) => r.id == j['default']), isTrue);
    for (final r in list) {
      expect(r.urlPrefix, startsWith('https://'));
    }
  });

  test('verse audio URL pattern', () {
    final alafasy = list.firstWhere((r) => r.id == 7);
    expect(alafasy.verseUri(1, 1).toString(),
        'https://verses.quran.com/Alafasy/mp3/001001.mp3');
    expect(alafasy.verseUri(114, 6).toString(),
        'https://verses.quran.com/Alafasy/mp3/114006.mp3');
  });
}
