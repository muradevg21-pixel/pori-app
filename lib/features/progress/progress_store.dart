import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';

@immutable
class VerseRef {
  const VerseRef(this.surah, this.verse);
  final int surah;
  final int verse;

  String get key => '$surah:$verse';

  static VerseRef parse(String k) {
    final p = k.split(':');
    return VerseRef(int.parse(p[0]), int.parse(p[1]));
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRef && other.surah == surah && other.verse == verse;
  @override
  int get hashCode => Object.hash(surah, verse);
}

@immutable
class Bookmark {
  const Bookmark(this.ref, this.createdAt);
  final VerseRef ref;
  final DateTime createdAt;

  Map<String, dynamic> toJson() =>
      {'k': ref.key, 't': createdAt.millisecondsSinceEpoch};
  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
      VerseRef.parse(j['k'] as String),
      DateTime.fromMillisecondsSinceEpoch(j['t'] as int));
}

@immutable
class ProgressState {
  const ProgressState({
    this.lastRead,
    this.bookmarks = const [],
    this.readVerses = const {},
    this.secondsByDay = const {},
  });

  final VerseRef? lastRead;

  /// Newest first.
  final List<Bookmark> bookmarks;
  final Set<String> readVerses;

  /// 'yyyy-mm-dd' -> seconds spent reading.
  final Map<String, int> secondsByDay;

  bool isBookmarked(VerseRef r) => bookmarks.any((b) => b.ref == r);

  int readCountInSurah(int surah) {
    final prefix = '$surah:';
    return readVerses.where((k) => k.startsWith(prefix)).length;
  }

  int minutesOn(DateTime day) => (secondsByDay[dayKey(day)] ?? 0) ~/ 60;

  /// Consecutive days (ending today, or yesterday if today has no reading
  /// yet) with at least one minute of reading.
  int streak(DateTime now) {
    bool active(DateTime d) => (secondsByDay[dayKey(d)] ?? 0) >= 60;
    var day = DateTime(now.year, now.month, now.day);
    if (!active(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (active(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  ProgressState copyWith({
    VerseRef? lastRead,
    List<Bookmark>? bookmarks,
    Set<String>? readVerses,
    Map<String, int>? secondsByDay,
  }) =>
      ProgressState(
        lastRead: lastRead ?? this.lastRead,
        bookmarks: bookmarks ?? this.bookmarks,
        readVerses: readVerses ?? this.readVerses,
        secondsByDay: secondsByDay ?? this.secondsByDay,
      );
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ProgressNotifier extends Notifier<ProgressState> {
  static const _kLast = 'progress_last_read';
  static const _kBookmarks = 'progress_bookmarks';
  static const _kRead = 'progress_read_verses';
  static const _kSeconds = 'progress_seconds_by_day';

  Timer? _saveTimer;

  @override
  ProgressState build() {
    final p = ref.watch(sharedPrefsProvider);
    ref.onDispose(() {
      _saveTimer?.cancel();
    });
    final last = p.getString(_kLast);
    final bm = p.getString(_kBookmarks);
    final secs = p.getString(_kSeconds);
    return ProgressState(
      lastRead: last == null ? null : VerseRef.parse(last),
      bookmarks: bm == null
          ? const []
          : [
              for (final j in jsonDecode(bm) as List)
                Bookmark.fromJson(j as Map<String, dynamic>),
            ],
      readVerses: (p.getStringList(_kRead) ?? const []).toSet(),
      secondsByDay: secs == null
          ? const {}
          : (jsonDecode(secs) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as int)),
    );
  }

  void toggleBookmark(VerseRef r) {
    final list = state.isBookmarked(r)
        ? state.bookmarks.where((b) => b.ref != r).toList()
        : [Bookmark(r, DateTime.now()), ...state.bookmarks];
    state = state.copyWith(bookmarks: list);
    _saveBookmarks();
  }

  void removeBookmark(VerseRef r) {
    state = state.copyWith(
        bookmarks: state.bookmarks.where((b) => b.ref != r).toList());
    _saveBookmarks();
  }

  void restoreBookmark(Bookmark b, int index) {
    final list = [...state.bookmarks]
      ..insert(index.clamp(0, state.bookmarks.length), b);
    state = state.copyWith(bookmarks: list);
    _saveBookmarks();
  }

  /// Called while scrolling: remembers position and marks verses as read.
  void onVersesViewed(int surah, int firstVerse, Iterable<int> fullyVisible) {
    final newKeys = fullyVisible.map((v) => '$surah:$v');
    final added = newKeys.where((k) => !state.readVerses.contains(k));
    final last = VerseRef(surah, firstVerse);
    if (added.isEmpty && state.lastRead == last) return;
    state = state.copyWith(
      lastRead: last,
      readVerses: added.isEmpty ? null : {...state.readVerses, ...added},
    );
    _scheduleSave();
  }

  void addReadingSeconds(int seconds, [DateTime? now]) {
    final k = dayKey(now ?? DateTime.now());
    state = state.copyWith(secondsByDay: {
      ...state.secondsByDay,
      k: (state.secondsByDay[k] ?? 0) + seconds,
    });
    _scheduleSave();
  }

  void _saveBookmarks() => ref.read(sharedPrefsProvider).setString(
      _kBookmarks, jsonEncode([for (final b in state.bookmarks) b.toJson()]));

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), flush);
  }

  /// Writes position, read verses and reading time to disk.
  void flush() {
    _saveTimer?.cancel();
    final p = ref.read(sharedPrefsProvider);
    final last = state.lastRead;
    if (last != null) p.setString(_kLast, last.key);
    p.setStringList(_kRead, state.readVerses.toList());
    p.setString(_kSeconds, jsonEncode(state.secondsByDay));
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, ProgressState>(ProgressNotifier.new);
