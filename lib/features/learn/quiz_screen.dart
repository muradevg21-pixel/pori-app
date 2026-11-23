import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import 'data/learn_models.dart';
import 'data/learn_progress.dart';

final _arabic = RegExp(r'[؀-ۿ]');

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.courseId, required this.lessonId});
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final lesson = ref
        .watch(coursesProvider)
        .value
        ?.where((c) => c.id == widget.courseId)
        .firstOrNull
        ?.lessons
        .where((l) => l.id == widget.lessonId)
        .firstOrNull;
    if (lesson == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final total = lesson.quiz.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('কুইজ · ${lesson.title}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _finished ? 1 : _index / total,
            color: AppColors.gold,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: _finished ? _result(total) : _question(lesson.quiz[_index], total),
    );
  }

  Widget _question(QuizQuestion q, int total) {
    final cs = Theme.of(context).colorScheme;
    final answered = _picked != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('প্রশ্ন ${bn(_index + 1)} / ${bn(total)}',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(q.question,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, height: 1.5)),
        const SizedBox(height: 20),
        for (final (i, opt) in q.options.indexed) ...[
          _OptionTile(
            text: opt,
            state: !answered
                ? _OptState.idle
                : i == q.answer
                    ? _OptState.correct
                    : i == _picked
                        ? _OptState.wrong
                        : _OptState.dim,
            onTap: answered
                ? null
                : () => setState(() {
                      _picked = i;
                      if (i == q.answer) _correct++;
                    }),
          ),
          const SizedBox(height: 10),
        ],
        if (answered) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(q.explain, style: const TextStyle(height: 1.6)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.emerald700,
            ),
            onPressed: () => setState(() {
              if (_index + 1 >= total) {
                _finished = true;
                ref.read(learnProgressProvider.notifier).record(
                    widget.courseId, widget.lessonId, _correct * 100 ~/ total);
              } else {
                _index++;
                _picked = null;
              }
            }),
            child: Text(_index + 1 >= total ? 'ফলাফল দেখুন' : 'পরের প্রশ্ন',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _result(int total) {
    final percent = _correct * 100 ~/ total;
    final passed = percent >= LearnProgressNotifier.passMark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 72, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('${bn(_correct)} / ${bn(total)} সঠিক',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              passed
                  ? 'মাশাআল্লাহ! পাঠটি সম্পন্ন হয়েছে।'
                  : 'পাঠটি আরেকবার পড়ে আবার চেষ্টা করুন (পাস: ${bn(LearnProgressNotifier.passMark)}%)।',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _index = 0;
                    _correct = 0;
                    _picked = null;
                    _finished = false;
                  }),
                  child: const Text('আবার দিন'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald700),
                  onPressed: () => context.pop(),
                  child: const Text('পাঠে ফিরুন'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dim }

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.text, required this.state, this.onTap});
  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, border, icon) = switch (state) {
      _OptState.correct => (
          AppColors.emerald500.withValues(alpha: 0.15),
          AppColors.emerald500,
          Icons.check_circle_rounded
        ),
      _OptState.wrong => (
          cs.error.withValues(alpha: 0.1),
          cs.error,
          Icons.cancel_rounded
        ),
      _ => (cs.surfaceContainerLow, cs.outlineVariant, null),
    };
    final isArabic = _arabic.hasMatch(text);
    return Opacity(
      opacity: state == _OptState.dim ? 0.55 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(text,
                      style: isArabic
                          ? TextStyle(
                              fontFamily: AppFonts.arabic,
                              fontSize: 24,
                              height: 1.5,
                              color: cs.primary)
                          : const TextStyle(fontSize: 16)),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
