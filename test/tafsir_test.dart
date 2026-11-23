import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pori/core/widgets/simple_html.dart';
import 'package:pori/features/tafsir/tafsir_repository.dart';

void main() {
  test('bundled Ahsanul Bayaan covers every verse', () {
    final meta = jsonDecode(File('assets/quran/meta.json').readAsStringSync());
    var total = 0;
    for (final s in meta['surahs'] as List) {
      final n = (s['n'] as int).toString().padLeft(3, '0');
      final v = (jsonDecode(File('assets/tafsir/165/$n.json').readAsStringSync())
          as Map)['v'] as Map;
      expect(v.length, s['verses'], reason: 'surah $n');
      total += v.length;
    }
    expect(total, 6236);
  });

  test('grouped verses fall back to the shared explanation', () {
    final m = {1: '<p>a</p>', 2: '', 3: '', 4: '<p>b</p>'};
    expect(tafsirFor(m, 1)!.fromVerse, 1);
    expect(tafsirFor(m, 2)!.fromVerse, 4);
    expect(tafsirFor({1: 'x', 2: ''}, 2)!.fromVerse, 1);
    expect(tafsirFor({1: ''}, 1), isNull);
  });

  test('simple html parser', () {
    final p = parseSimpleHtml(
        '<p>এক <b>দুই</b> <em>তিন</em> &amp; চার</p><p>পাঁচ<br>ছয়</p><p> </p>');
    expect(p.length, 2);
    expect(p[0].map((s) => s.text).join(), 'এক দুই তিন & চার');
    expect(p[0][1].style!.fontWeight, FontWeight.w700);
    expect(p[0][3].style!.fontStyle, FontStyle.italic);
    expect(p[1].map((s) => s.text).join(), 'পাঁচ\nছয়');
  });
}
