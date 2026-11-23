import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';

@immutable
class Reciter {
  const Reciter(this.id, this.name, this.style, this.urlPrefix);

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
      j['id'] as int, j['name'] as String, j['style'] as String, j['url'] as String);

  final int id;
  final String name;
  final String style;
  final String urlPrefix;

  String label() => style.isEmpty ? name : '$name · $style';

  static String fileName(int surah, int verse) =>
      '${surah.toString().padLeft(3, '0')}${verse.toString().padLeft(3, '0')}.mp3';

  Uri verseUri(int surah, int verse) =>
      Uri.parse('$urlPrefix/${fileName(surah, verse)}');
}

final recitersProvider = FutureProvider<List<Reciter>>((ref) async {
  final raw = await rootBundle.loadString('assets/quran/reciters.json');
  final j = jsonDecode(raw) as Map<String, dynamic>;
  return [for (final r in j['reciters'] as List) Reciter.fromJson(r)];
});

/// The reciter chosen in settings (falls back to the first available).
final currentReciterProvider = Provider<Reciter?>((ref) {
  final list = ref.watch(recitersProvider).value;
  if (list == null || list.isEmpty) return null;
  final id = ref.watch(settingsProvider.select((s) => s.reciterId));
  return list.firstWhere((r) => r.id == id, orElse: () => list.first);
});

/// Same as [currentReciterProvider] but waits for the list to load.
final reciterFutureProvider = FutureProvider<Reciter?>((ref) async {
  final list = await ref.watch(recitersProvider.future);
  if (list.isEmpty) return null;
  final id = ref.watch(settingsProvider.select((s) => s.reciterId));
  return list.firstWhere((r) => r.id == id, orElse: () => list.first);
});
