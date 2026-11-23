import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class LessonBlock {
  const LessonBlock(this.type, this.raw);
  final String type;
  final Map<String, dynamic> raw;

  String get text => raw['text'] as String? ?? '';
  String? get title => raw['title'] as String?;
  List<({String ar, String bn})> get letters => [
        for (final i in raw['items'] as List? ?? const [])
          (ar: i['ar'] as String, bn: i['bn'] as String),
      ];
  String get ref => raw['ref'] as String;
  List<int> get words => (raw['words'] as List).cast<int>();
  String get note => raw['note'] as String? ?? '';
}

@immutable
class QuizQuestion {
  const QuizQuestion(this.question, this.options, this.answer, this.explain);
  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
      j['q'] as String,
      (j['options'] as List).cast<String>(),
      j['answer'] as int,
      j['explain'] as String);
  final String question;
  final List<String> options;
  final int answer;
  final String explain;
}

@immutable
class Lesson {
  const Lesson(this.id, this.title, this.reviewed, this.reviewer, this.blocks,
      this.quiz);
  factory Lesson.fromJson(Map<String, dynamic> j) {
    final review = j['review'] as Map<String, dynamic>;
    return Lesson(
      j['id'] as String,
      j['title'] as String,
      review['status'] == 'reviewed',
      review['reviewer'] as String?,
      [
        for (final b in j['blocks'] as List)
          LessonBlock(b['type'] as String, b as Map<String, dynamic>),
      ],
      [for (final q in j['quiz'] as List) QuizQuestion.fromJson(q)],
    );
  }
  final String id;
  final String title;

  /// True only after a qualified scholar has reviewed the lesson.
  final bool reviewed;
  final String? reviewer;
  final List<LessonBlock> blocks;
  final List<QuizQuestion> quiz;
}

@immutable
class Course {
  const Course(this.id, this.title, this.subtitle, this.icon, this.lessons);
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        j['id'] as String,
        j['title'] as String,
        j['subtitle'] as String,
        j['icon'] as String,
        [for (final l in j['lessons'] as List) Lesson.fromJson(l)],
      );
  final String id, title, subtitle, icon;
  final List<Lesson> lessons;

  Lesson lesson(String id) => lessons.firstWhere((l) => l.id == id);
}

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final raw = await rootBundle.loadString('assets/learn/courses.json');
  return [
    for (final c in (jsonDecode(raw) as Map<String, dynamic>)['courses'] as List)
      Course.fromJson(c),
  ];
});
