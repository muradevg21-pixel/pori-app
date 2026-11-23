import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/app_router.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../quran/data/quran_repository.dart';
import 'data/learn_models.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen(
      {super.key, required this.courseId, required this.lessonId});
  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref
        .watch(coursesProvider)
        .value
        ?.where((c) => c.id == courseId)
        .firstOrNull;
    final lesson = course?.lessons.where((l) => l.id == lessonId).firstOrNull;
    final fs = ref.watch(settingsProvider.select((s) => s.banglaFontSize));
    if (lesson == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ReviewBanner(lesson: lesson),
          const SizedBox(height: 12),
          for (final b in lesson.blocks) ...[
            switch (b.type) {
              'text' => Text(b.text,
                  style: TextStyle(fontSize: fs + 1, height: 1.75)),
              'tip' => _Tip(b.text),
              'letters' => _LetterGrid(block: b),
              'example' => _QuranExample(block: b),
              _ => const SizedBox.shrink(),
            },
            const SizedBox(height: 14),
          ],
        ],
      ),
      bottomNavigationBar: lesson.quiz.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.emerald700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () =>
                      context.push('/learn/$courseId/$lessonId/quiz'),
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text('কুইজ দিন (${bn(lesson.quiz.length)}টি প্রশ্ন)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final ok = lesson.reviewed;
    final color = ok ? AppColors.emerald600 : AppColors.goldDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.verified_rounded : Icons.pending_actions_rounded,
              color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ok
                  ? 'পর্যালোচনা করেছেন: ${lesson.reviewer ?? ''}'
                  : 'খসড়া পাঠ — আলেমের পর্যালোচনা বাকি',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border(
              left: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.6))),
          ],
        ),
      );
}

class _LetterGrid extends StatelessWidget {
  const _LetterGrid({required this.block});
  final LessonBlock block;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = block.letters;
    final compact = items.every((i) => i.bn.length <= 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (block.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(block.title!,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        if (compact)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in items)
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Text(i.ar,
                            style: TextStyle(
                                fontFamily: AppFonts.arabic,
                                fontSize: 30,
                                height: 1.6,
                                color: cs.primary)),
                        if (i.bn.isNotEmpty)
                          Text(i.bn,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (n, i) in items.indexed) ...[
                  if (n > 0) const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(i.bn, style: const TextStyle(height: 1.5))),
                        const SizedBox(width: 12),
                        Text(i.ar,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontFamily: AppFonts.arabic,
                                fontSize: 24,
                                height: 1.6,
                                color: cs.primary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// A verified verse from the bundled Quran data with the example words
/// highlighted. Nothing Quranic is typed in the lesson content.
class _QuranExample extends ConsumerWidget {
  const _QuranExample({required this.block});
  final LessonBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final parts = block.ref.split(':').map(int.parse).toList();
    final verses = ref.watch(surahVersesProvider(parts[0])).value;
    final meta = ref.watch(quranMetaProvider).value;
    final verse = verses?[parts[1] - 1];
    final highlight = block.words.toSet();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.reader(parts[0], verse: parts[1])),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 16, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                      'উদাহরণ · ${meta?.surah(parts[0]).nameLatin ?? ''} ${bn(parts[0])}:${bn(parts[1])}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              if (verse == null)
                const LinearProgressIndicator()
              else
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final (i, w) in verse.words.indexed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: highlight.contains(i + 1)
                              ? BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Text(w.arabic,
                              style: TextStyle(
                                  fontFamily: AppFonts.arabic,
                                  fontSize: 24,
                                  height: 1.9,
                                  color: highlight.contains(i + 1)
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.75))),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(block.note, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
