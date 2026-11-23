import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn.dart';
import 'data/learn_models.dart';
import 'data/learn_progress.dart';

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider).value;
    final progress = ref.watch(learnProgressProvider);
    final cs = Theme.of(context).colorScheme;
    final course = courses?.where((c) => c.id == courseId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(course?.title ?? '')),
      body: course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: course.lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final l = course.lessons[i];
                final done = isLessonDone(progress, course.id, l.id);
                final score = progress['${course.id}/${l.id}'];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => context.push('/learn/${course.id}/${l.id}'),
                    leading: CircleAvatar(
                      backgroundColor:
                          done ? AppColors.gold : cs.primaryContainer,
                      foregroundColor:
                          done ? AppColors.emerald950 : cs.primary,
                      child: done
                          ? const Icon(Icons.check_rounded)
                          : Text(bn(i + 1),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    title: Text(l.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(score == null
                        ? '${bn(l.quiz.length)}টি কুইজ প্রশ্ন'
                        : 'সেরা স্কোর: ${bn(score)}%'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
    );
  }
}
