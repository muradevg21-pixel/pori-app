import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import '../progress/progress_store.dart';
import '../quran/data/quran_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('আসসালামু আলাইকুম',
                              style: TextStyle(
                                  fontSize: 14, color: cs.onSurfaceVariant)),
                          const Text('পড়ি',
                              style: TextStyle(
                                  fontSize: 28,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald700)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('${Routes.quran}?search=1'),
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'খুঁজুন',
                    ),
                    IconButton(
                      onPressed: () => context.go(Routes.profile),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'সেটিংস',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: const _ContinueReadingCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('দ্রুত শুরু করুন')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _QuickAction(Icons.menu_book_rounded, 'কুরআন',
                      () => context.go(Routes.quran)),
                  _QuickAction(Icons.auto_stories_rounded, 'তাজবীদ',
                      () => context.push('/learn/tajweed')),
                  _QuickAction(Icons.record_voice_over_rounded, 'মাখরাজ',
                      () => context.push('/learn/makhraj')),
                  _QuickAction(Icons.text_fields_rounded, 'আরবি হরফ',
                      () => context.push('/learn/letters')),
                  _QuickAction(Icons.workspace_premium_rounded, 'কোর্স',
                      () => context.go(Routes.learn)),
                  _QuickAction(Icons.quiz_rounded, 'কুইজ',
                      () => context.go(Routes.learn)),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('আজকের লক্ষ্য')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer(
                  builder: (_, ref, _) => _DailyGoalCard(
                    minutesDone: ref.watch(progressProvider
                        .select((p) => p.minutesOn(DateTime.now()))),
                    minutesGoal: 15,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(progressProvider.select((p) => p.lastRead));
    final totalRead =
        ref.watch(progressProvider.select((p) => p.readVerses.length));
    final meta = ref.watch(quranMetaProvider).value;
    final surah = (last != null && meta != null) ? meta.surah(last.surah) : null;
    final started = surah != null;

    void open() => started
        ? context.push(Routes.reader(last!.surah, verse: last.verse))
        : context.push(Routes.reader(1));

    return GestureDetector(
      onTap: open,
      child: EmeraldBanner(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.goldLight),
                    const SizedBox(width: 6),
                    Text(started ? 'সর্বশেষ পড়া' : 'পড়া শুরু করুন',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.cream.withValues(alpha: 0.85))),
                  ]),
                  const SizedBox(height: 10),
                  Text(started ? surah.nameLatin : 'আজই কুরআন পড়া শুরু করুন',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream)),
                  const SizedBox(height: 6),
                  Text(
                      started
                          ? '${surah.meaningBn} · আয়াত ${bn(last!.verse)} / ${bn(surah.verseCount)}'
                          : 'সূরা আল-ফাতিহা থেকে শুরু করুন',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.cream.withValues(alpha: 0.75))),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emerald950,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: open,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(started ? 'চালিয়ে যান' : 'শুরু করুন',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: totalRead / 6236,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: AppColors.gold,
                    backgroundColor: AppColors.emerald950.withValues(alpha: 0.4),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${bn((totalRead * 100 / 6236).toStringAsFixed(totalRead == 0 ? 0 : 1))}%',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream)),
                        Text('পুরো কুরআন',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.cream.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.minutesDone, required this.minutesGoal});
  final int minutesDone;
  final int minutesGoal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress =
        minutesGoal == 0 ? 0.0 : (minutesDone / minutesGoal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: cs.outlineVariant,
                    color: AppColors.gold,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text('${bn((progress * 100).round())}%',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('প্রতিদিন ${bn(minutesGoal)} মিনিট পড়া',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('আজ ${bn(minutesDone)} মিনিট পড়েছেন',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.local_fire_department_rounded,
                color: AppColors.gold, size: 28),
          ],
        ),
      ),
    );
  }
}
