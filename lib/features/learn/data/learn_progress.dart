import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_provider.dart';

/// Best quiz score per lesson ("course/lesson" -> percent 0..100).
/// A lesson counts as completed at [passMark] or above.
class LearnProgressNotifier extends Notifier<Map<String, int>> {
  static const _k = 'learn_best_scores';
  static const passMark = 60;

  @override
  Map<String, int> build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_k);
    if (raw == null) return const {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  void record(String course, String lesson, int percent) {
    final key = '$course/$lesson';
    if ((state[key] ?? -1) >= percent) return;
    state = {...state, key: percent};
    ref.read(sharedPrefsProvider).setString(_k, jsonEncode(state));
  }
}

final learnProgressProvider =
    NotifierProvider<LearnProgressNotifier, Map<String, int>>(
        LearnProgressNotifier.new);

bool isLessonDone(Map<String, int> p, String course, String lesson) =>
    (p['$course/$lesson'] ?? 0) >= LearnProgressNotifier.passMark;

int completedLessons(Map<String, int> p) =>
    p.values.where((v) => v >= LearnProgressNotifier.passMark).length;
