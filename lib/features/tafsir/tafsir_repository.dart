import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

@immutable
class TafsirSource {
  const TafsirSource(this.id, this.name, this.publisher, {this.bundled = false});
  final int id;
  final String name;
  final String publisher;

  /// Bundled in the app (offline). Others are downloaded per surah from
  /// Quran.com on first use and then kept on the device.
  final bool bundled;
}

/// Bengali tafsirs available from the Quran.com API v4 (ids from
/// /resources/tafsirs). See CONTENT_SOURCES.md.
const tafsirSources = [
  TafsirSource(165, 'তাফসীরে আহসানুল বায়ান', 'Bayaan Foundation', bundled: true),
  TafsirSource(166, 'তাফসীরে আবু বকর যাকারিয়া', 'King Fahd Quran Printing Complex'),
  TafsirSource(164, 'তাফসীর ইবনে কাসীর', 'Tawheed Publication'),
  TafsirSource(381, 'তাফসীর ফাতহুল মাজীদ', 'AbdulRahman Bin Hasan Al-Alshaikh'),
];

TafsirSource tafsirById(int id) =>
    tafsirSources.firstWhere((t) => t.id == id, orElse: () => tafsirSources.first);

class TafsirRepository {
  final _mem = <(int, int), Map<int, String>>{};

  Future<Map<int, String>> load(int tafsirId, int surah) async {
    final key = (tafsirId, surah);
    final cached = _mem[key];
    if (cached != null) return cached;
    final file = surah.toString().padLeft(3, '0');
    String raw;
    if (tafsirById(tafsirId).bundled) {
      raw = await rootBundle.loadString('assets/tafsir/$tafsirId/$file.json');
    } else {
      final disk = kIsWeb ? null : await _cacheFile(tafsirId, file);
      if (disk != null && disk.existsSync()) {
        raw = await disk.readAsString();
      } else {
        raw = await _download(tafsirId, surah);
        if (disk != null) {
          await disk.parent.create(recursive: true);
          await disk.writeAsString(raw);
        }
      }
    }
    final result = await compute(_parse, raw);
    return _mem[key] = result;
  }

  Future<File> _cacheFile(int id, String file) async => File(
      '${(await getApplicationDocumentsDirectory()).path}/tafsir/$id/$file.json');

  Future<String> _download(int id, int surah) async {
    final verses = <String, String>{};
    final client = http.Client();
    try {
      var page = 1;
      while (true) {
        final uri = Uri.parse('https://api.quran.com/api/v4/tafsirs/$id'
            '/by_chapter/$surah?per_page=50&page=$page');
        final res = await client.get(uri);
        if (res.statusCode != 200) {
          throw HttpException('HTTP ${res.statusCode}', uri: uri);
        }
        final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        for (final t in d['tafsirs'] as List) {
          final k = (t['verse_key'] as String).split(':')[1];
          verses[k] = (t['text'] as String?) ?? '';
        }
        if ((d['pagination'] as Map)['next_page'] == null) break;
        page++;
      }
    } finally {
      client.close();
    }
    return jsonEncode({'v': verses});
  }
}

Map<int, String> _parse(String raw) {
  final v = (jsonDecode(raw) as Map<String, dynamic>)['v'] as Map<String, dynamic>;
  return v.map((k, t) => MapEntry(int.parse(k), t as String));
}

final tafsirRepositoryProvider = Provider((_) => TafsirRepository());

final tafsirSurahProvider =
    FutureProvider.family<Map<int, String>, (int, int)>((ref, key) =>
        ref.watch(tafsirRepositoryProvider).load(key.$1, key.$2));

/// Text for one verse. Some tafsirs explain several verses together and
/// leave the others empty; then the shared text and its verse are returned.
({int fromVerse, String html})? tafsirFor(Map<int, String> surah, int verse) {
  final own = surah[verse];
  if (own != null && own.trim().isNotEmpty) return (fromVerse: verse, html: own);
  for (var v = verse + 1; surah.containsKey(v); v++) {
    final t = surah[v]!;
    if (t.trim().isNotEmpty) return (fromVerse: v, html: t);
  }
  for (var v = verse - 1; v >= 1; v--) {
    final t = surah[v];
    if (t != null && t.trim().isNotEmpty) return (fromVerse: v, html: t);
  }
  return null;
}
