import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'reciters.dart';

/// Offline audio: verse files are stored at
/// `<app documents>/audio/<reciterId>/<SSSAAA>.mp3`, plus a `<SSS>.done` marker
/// once a whole surah has finished downloading.
class AudioFiles {
  static Directory? _root;

  static Future<Directory> root() async =>
      _root ??= Directory('${(await getApplicationDocumentsDirectory()).path}/audio');

  static Future<File> verseFile(int reciter, int surah, int verse) async =>
      File('${(await root()).path}/$reciter/${Reciter.fileName(surah, verse)}');

  static Future<File> _marker(int reciter, int surah) async => File(
      '${(await root()).path}/$reciter/${surah.toString().padLeft(3, '0')}.done');

  static Future<bool> isSurahDownloaded(int reciter, int surah) async =>
      !kIsWeb && (await _marker(reciter, surah)).existsSync();

  static Future<void> markDone(int reciter, int surah) async =>
      (await _marker(reciter, surah)).writeAsString('ok');

  static Future<void> deleteSurah(int reciter, int surah, int verses) async {
    (await _marker(reciter, surah)).deleteSync();
    for (var v = 1; v <= verses; v++) {
      final f = await verseFile(reciter, surah, v);
      if (f.existsSync()) f.deleteSync();
    }
  }
}

typedef SurahKey = ({int reciter, int surah});

@immutable
class DownloadState {
  const DownloadState({this.progress = const {}, this.done = const {}});

  /// In-progress downloads: 0.0 – 1.0.
  final Map<SurahKey, double> progress;
  final Set<SurahKey> done;
}

class AudioDownloadNotifier extends Notifier<DownloadState> {
  final _cancelled = <SurahKey>{};

  @override
  DownloadState build() => const DownloadState();

  Future<void> refresh(int reciter, int surah) async {
    final k = (reciter: reciter, surah: surah);
    final ok = await AudioFiles.isSurahDownloaded(reciter, surah);
    if (ok != state.done.contains(k)) {
      state = DownloadState(
        progress: state.progress,
        done: ok ? {...state.done, k} : ({...state.done}..remove(k)),
      );
    }
  }

  Future<void> download(Reciter r, int surah, int verses) async {
    final k = (reciter: r.id, surah: surah);
    if (kIsWeb || state.progress.containsKey(k)) return;
    _cancelled.remove(k);
    _set(k, 0);
    final client = http.Client();
    try {
      for (var v = 1; v <= verses; v++) {
        if (_cancelled.contains(k)) break;
        final f = await AudioFiles.verseFile(r.id, surah, v);
        if (!f.existsSync() || f.lengthSync() == 0) {
          final res = await client.get(r.verseUri(surah, v));
          if (res.statusCode != 200) {
            throw HttpException('HTTP ${res.statusCode}', uri: r.verseUri(surah, v));
          }
          await f.parent.create(recursive: true);
          final tmp = File('${f.path}.part');
          await tmp.writeAsBytes(res.bodyBytes, flush: true);
          await tmp.rename(f.path);
        }
        _set(k, v / verses);
      }
      if (!_cancelled.contains(k)) await AudioFiles.markDone(r.id, surah);
    } finally {
      client.close();
      final p = {...state.progress}..remove(k);
      state = DownloadState(progress: p, done: state.done);
      await refresh(r.id, surah);
    }
  }

  void cancel(SurahKey k) => _cancelled.add(k);

  Future<void> delete(int reciter, int surah, int verses) async {
    await AudioFiles.deleteSurah(reciter, surah, verses);
    await refresh(reciter, surah);
  }

  void _set(SurahKey k, double v) =>
      state = DownloadState(progress: {...state.progress, k: v}, done: state.done);
}

final audioDownloadsProvider =
    NotifierProvider<AudioDownloadNotifier, DownloadState>(AudioDownloadNotifier.new);
