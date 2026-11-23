import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pori/features/learn/data/learn_models.dart';

void main() {
  final doc = jsonDecode(File('assets/learn/courses.json').readAsStringSync())
      as Map<String, dynamic>;
  final courses = [for (final c in doc['courses'] as List) Course.fromJson(c)];

  test('courses, lessons and quizzes are well formed', () {
    expect(courses.map((c) => c.id), ['letters', 'makhraj', 'tajweed']);
    for (final c in courses) {
      expect(c.lessons.map((l) => l.id).toSet().length, c.lessons.length);
      for (final l in c.lessons) {
        expect(l.quiz, isNotEmpty, reason: l.id);
        for (final q in l.quiz) {
          expect(q.answer, inInclusiveRange(0, q.options.length - 1),
              reason: '${l.id}: ${q.question}');
          expect(q.options.toSet().length, q.options.length);
        }
      }
    }
  });

  test('unreviewed lessons are never marked as reviewed', () {
    for (final c in courses) {
      for (final l in c.lessons) {
        if (l.reviewed) expect(l.reviewer, isNotNull, reason: l.id);
      }
    }
  });

  test('every Quran example points at real words in the verified data', () {
    var n = 0;
    for (final c in courses) {
      for (final l in c.lessons) {
        for (final b in l.blocks.where((b) => b.type == 'example')) {
          final p = b.ref.split(':').map(int.parse).toList();
          final f = 'assets/quran/surah/${p[0].toString().padLeft(3, '0')}.json';
          final verses = (jsonDecode(File(f).readAsStringSync()) as Map)['v'] as List;
          final words = (verses[p[1] - 1] as Map)['w'] as List;
          expect(b.words, isNotEmpty);
          for (final w in b.words) {
            expect(w, inInclusiveRange(1, words.length), reason: b.ref);
          }
          n++;
        }
      }
    }
    expect(n, greaterThan(15));
  });
}
