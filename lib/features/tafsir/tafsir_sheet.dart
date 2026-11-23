import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/simple_html.dart';
import '../quran/data/quran_models.dart';
import 'tafsir_repository.dart';

Future<void> showTafsir(BuildContext context, SurahInfo surah, Verse verse) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scroll) =>
            _TafsirView(surah: surah, verse: verse, scroll: scroll),
      ),
    );

class _TafsirView extends ConsumerWidget {
  const _TafsirView(
      {required this.surah, required this.verse, required this.scroll});
  final SurahInfo surah;
  final Verse verse;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final source = tafsirById(settings.tafsirId);
    final data = ref.watch(tafsirSurahProvider((source.id, surah.number)));

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text('তাফসীর · ${surah.nameLatin} ${bn(surah.number)}:${bn(verse.number)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final t in tafsirSources)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.name),
                    selected: t.id == source.id,
                    showCheckmark: false,
                    selectedColor: cs.primaryContainer,
                    avatar: t.bundled
                        ? Icon(Icons.offline_pin_rounded,
                            size: 16, color: cs.primary)
                        : null,
                    onSelected: (_) =>
                        ref.read(settingsProvider.notifier).setTafsir(t.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            verse.arabicForDisplay,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: AppFonts.arabic,
                fontSize: 24,
                height: 1.9,
                color: cs.primary),
          ),
        ),
        const SizedBox(height: 16),
        data.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(source.bundled ? 'লোড হচ্ছে…' : 'ডাউনলোড হচ্ছে… (একবারই লাগবে)',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          error: (e, _) => _Message(
            icon: Icons.wifi_off_rounded,
            text: 'এই তাফসীরটি প্রথমবার পড়তে ইন্টারনেট লাগবে। '
                'সংযোগ পরীক্ষা করে আবার চেষ্টা করুন, অথবা অফলাইন '
                '"আহসানুল বায়ান" বেছে নিন।',
            onRetry: () =>
                ref.invalidate(tafsirSurahProvider((source.id, surah.number))),
          ),
          data: (map) {
            final t = tafsirFor(map, verse.number);
            if (t == null) {
              return const _Message(
                  icon: Icons.info_outline_rounded,
                  text: 'এই আয়াতের তাফসীর এই উৎসে পাওয়া যায়নি।');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (t.fromVerse != verse.number)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'এই আয়াতের ব্যাখ্যা আয়াত ${bn(t.fromVerse)}-এর সাথে একত্রে দেওয়া হয়েছে।',
                      style: const TextStyle(color: AppColors.goldDeep),
                    ),
                  ),
                SimpleHtml(
                  t.html,
                  style: TextStyle(
                      fontSize: settings.banglaFontSize,
                      height: 1.75,
                      color: cs.onSurface),
                ),
              ],
            );
          },
        ),
        const Divider(),
        const SizedBox(height: 8),
        Text('উৎস: ${source.name} (${source.publisher}) · Quran.com',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(height: 1.6)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('আবার চেষ্টা')),
            ],
          ],
        ),
      );
}
