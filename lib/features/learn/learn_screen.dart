import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import 'data/learn_models.dart';
import 'data/learn_progress.dart';

IconData courseIcon(String name) => switch (name) {
      'abc' => Icons.text_fields_rounded,
      'voice' => Icons.record_voice_over_rounded,
      _ => Icons.auto_stories_rounded,
    };

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final progress = ref.watch(learnProgressProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('শিখি')),
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final total = list.fold<int>(0, (a, c) => a + c.lessons.length);
          final done = completedLessons(progress);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              EmeraldBanner(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('আপনার শেখার যাত্রা',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream)),
                          const SizedBox(height: 6),
                          Text('${bn(done)} / ${bn(total)} পাঠ সম্পন্ন',
                              style: TextStyle(
                                  color: AppColors.cream.withValues(alpha: 0.85))),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : done / total,
                              minHeight: 6,
                              color: AppColors.gold,
                              backgroundColor:
                                  AppColors.emerald950.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.school_rounded,
                        size: 48, color: AppColors.goldLight),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _DraftNotice(),
              const SizedBox(height: 12),
              for (final c in list) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/learn/${c.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(courseIcon(c.icon), color: cs.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                Text(c.subtitle,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                Builder(builder: (_) {
                                  final d = c.lessons
                                      .where((l) =>
                                          isLessonDone(progress, c.id, l.id))
                                      .length;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: d / c.lessons.length,
                                            minHeight: 4,
                                            color: AppColors.gold,
                                            backgroundColor: cs.outlineVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('${bn(d)}/${bn(c.lessons.length)}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant)),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.pending_actions_rounded, color: AppColors.goldDeep),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'পাঠগুলো খসড়া — একজন অভিজ্ঞ কারী/আলেমের পর্যালোচনা বাকি। '
                'নিশ্চিত হতে উস্তাদের কাছে শুনে শিখুন।',
                style: TextStyle(color: AppColors.goldDeep, height: 1.5),
              ),
            ),
          ],
        ),
      );
}
