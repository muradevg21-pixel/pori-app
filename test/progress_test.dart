import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pori/core/settings/settings_provider.dart';
import 'package:pori/features/progress/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bookmark toggle, remove, restore and persistence', () async {
    var c = await makeContainer();
    final n = c.read(progressProvider.notifier);
    n.toggleBookmark(const VerseRef(2, 255));
    n.toggleBookmark(const VerseRef(1, 1));
    expect(c.read(progressProvider).bookmarks.first.ref, const VerseRef(1, 1));
    final b = c.read(progressProvider).bookmarks.first;
    n.removeBookmark(b.ref);
    expect(c.read(progressProvider).bookmarks.length, 1);
    n.restoreBookmark(b, 0);
    n.toggleBookmark(const VerseRef(2, 255)); // un-bookmark
    expect(c.read(progressProvider).bookmarks.map((e) => e.ref.key), ['1:1']);
    c.dispose();

    c = await makeContainer(); // simulate app restart
    expect(c.read(progressProvider).isBookmarked(const VerseRef(1, 1)), isTrue);
    c.dispose();
  });

  test('last read, read verses and reading time persist after flush',
      () async {
    var c = await makeContainer();
    final n = c.read(progressProvider.notifier);
    n.onVersesViewed(2, 5, [5, 6, 7]);
    n.onVersesViewed(2, 6, [6, 7, 8]);
    n.addReadingSeconds(90, DateTime(2026, 11, 23));
    n.flush();
    c.dispose();

    c = await makeContainer();
    final s = c.read(progressProvider);
    expect(s.lastRead, const VerseRef(2, 6));
    expect(s.readCountInSurah(2), 4);
    expect(s.readCountInSurah(1), 0);
    expect(s.minutesOn(DateTime(2026, 11, 23)), 1);
    c.dispose();
  });

  test('streak counts consecutive days', () {
    final now = DateTime(2026, 11, 23, 20);
    final s = ProgressState(secondsByDay: {
      dayKey(DateTime(2026, 11, 21)): 300,
      dayKey(DateTime(2026, 11, 22)): 120,
      dayKey(DateTime(2026, 11, 23)): 61,
      dayKey(DateTime(2026, 11, 19)): 600, // gap on the 20th
    });
    expect(s.streak(now), 3);
    // Nothing yet today: streak still counts up to yesterday.
    expect(s.streak(DateTime(2026, 11, 24, 8)), 3);
    expect(s.streak(DateTime(2026, 11, 26)), 0);
  });
}
