import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_downloads.dart';
import 'reciters.dart';

@immutable
class RecitationState {
  const RecitationState({
    this.surah,
    this.verse,
    this.playing = false,
    this.loading = false,
    this.error,
  });

  final int? surah;
  final int? verse;
  final bool playing;
  final bool loading;
  final String? error;

  bool get active => surah != null;

  bool isPlayingVerse(int s, int v) => surah == s && verse == v;
}

/// Verse-by-verse recitation player. Uses downloaded files when present,
/// otherwise streams from the reciter's server.
class RecitationNotifier extends Notifier<RecitationState> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<dynamic>>[];
  int _startVerse = 1;
  bool _singleVerse = false;

  AudioPlayer get _p {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    _subs
      ..add(p.currentIndexStream.listen((i) {
        if (i != null && state.surah != null) {
          state = RecitationState(
              surah: state.surah,
              verse: _startVerse + i,
              playing: state.playing,
              loading: state.loading);
        }
      }))
      ..add(p.playerStateStream.listen((ps) {
        final done = ps.processingState == ProcessingState.completed;
        if (done) {
          stop();
          return;
        }
        state = RecitationState(
          surah: state.surah,
          verse: state.verse,
          playing: ps.playing,
          loading: ps.processingState == ProcessingState.loading ||
              ps.processingState == ProcessingState.buffering,
        );
      }, onError: (Object e) => _fail(e)));
    return _player = p;
  }

  @override
  RecitationState build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player?.dispose();
    });
    return const RecitationState();
  }

  /// Plays [surah] from [fromVerse] to the end, or only that verse when
  /// [single] is true.
  Future<void> play(int surah, int fromVerse, int verseCount,
      {bool single = false}) async {
    final reciter = await ref.read(reciterFutureProvider.future);
    if (reciter == null) return;
    _startVerse = fromVerse;
    _singleVerse = single;
    final last = single ? fromVerse : verseCount;
    state = RecitationState(surah: surah, verse: fromVerse, loading: true);
    try {
      final sources = <AudioSource>[];
      for (var v = fromVerse; v <= last; v++) {
        final f = kIsWeb ? null : await AudioFiles.verseFile(reciter.id, surah, v);
        sources.add(f != null && f.existsSync()
            ? AudioSource.file(f.path)
            : AudioSource.uri(reciter.verseUri(surah, v)));
      }
      await _p.setAudioSources(sources, initialIndex: 0);
      unawaited(_p.play());
    } catch (e) {
      _fail(e);
    }
  }

  bool get singleVerse => _singleVerse;

  Future<void> toggle() async =>
      _p.playing ? _p.pause() : _p.play();

  Future<void> next() => _p.seekToNext();
  Future<void> previous() => _p.seekToPrevious();

  Future<void> stop() async {
    await _player?.stop();
    state = const RecitationState();
  }

  void _fail(Object e) {
    debugPrint('Recitation error: $e');
    _player?.stop();
    state = const RecitationState(
        error: 'অডিও চালানো যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।');
  }
}

final recitationProvider =
    NotifierProvider<RecitationNotifier, RecitationState>(RecitationNotifier.new);
