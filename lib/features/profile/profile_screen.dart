import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_info.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import '../progress/progress_store.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          EmeraldBanner(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 36, color: AppColors.emerald700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('অতিথি ব্যবহারকারী',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream)),
                      const SizedBox(height: 4),
                      Text('আপনার শেখার অগ্রগতি এখানে সংরক্ষিত থাকবে',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.cream.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                  value: bn(ref.watch(progressProvider
                      .select((p) => p.streak(DateTime.now())))),
                  label: 'দিন ধারাবাহিক'),
              const SizedBox(width: 12),
              _Stat(
                  value: bn(ref.watch(
                      progressProvider.select((p) => p.readVerses.length))),
                  label: 'আয়াত পড়া'),
              const SizedBox(width: 12),
              _Stat(value: bn(0), label: 'পাঠ সম্পন্ন'),
            ],
          ),
          const SectionHeader('দেখার ধরন'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('লাইট')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('অটো')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('ডার্ক')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => n.setThemeMode(v.first),
              ),
            ),
          ),
          const SectionHeader('পড়ার সেটিংস'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        // U+FDFD: the standard Unicode Basmala ligature glyph.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: s.arabicFontSize * 1.6,
                            child: FittedBox(
                              child: Text('﷽',
                                  style: TextStyle(
                                      fontFamily: AppFonts.arabic,
                                      fontSize: s.arabicFontSize,
                                      color: cs.primary)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('বাংলা লেখার নমুনা',
                            style: TextStyle(fontSize: s.banglaFontSize)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SliderRow(
                    label: 'আরবি ফন্টের আকার',
                    value: s.arabicFontSize,
                    min: 22,
                    max: 48,
                    onChanged: n.setArabicFontSize,
                  ),
                  _SliderRow(
                    label: 'বাংলা ফন্টের আকার',
                    value: s.banglaFontSize,
                    min: 13,
                    max: 24,
                    onChanged: n.setBanglaFontSize,
                  ),
                  const SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('বাংলা উচ্চারণ দেখান'),
                    subtitle: Text('যাচাইকৃত উৎস যুক্ত হলে চালু হবে'),
                    value: false,
                    onChanged: null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('বাংলা অনুবাদ দেখান'),
                    value: s.showTranslation,
                    onChanged: n.setShowTranslation,
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('অন্যান্য'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.verified_outlined, color: cs.primary),
                  title: const Text('কনটেন্টের উৎস ও লাইসেন্স'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showSources(context),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: cs.primary),
                  title: const Text('অ্যাপ সম্পর্কে'),
                  subtitle: const Text('তৈরি করেছেন ${AppInfo.developer}'),
                  trailing: Text('v${bn(AppInfo.version)}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.headerGradient,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Center(
              child: Text('প',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream)),
            ),
          ),
          title: const Text(AppInfo.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('সংস্করণ ${bn(AppInfo.version)}'),
              const SizedBox(height: 12),
              const Text('তৈরি করেছেন',
                  style: TextStyle(fontSize: 12)),
              const Text(AppInfo.developer,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDeep)),
              const SizedBox(height: 12),
              const Text('কুরআন পড়ি · কুরআন শিখি',
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ঠিক আছে')),
          ],
        ),
      );

  void _showSources(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Text(
            'আরবি কুরআন টেক্সট: Tanzil Quran Text (Uthmani 1.1), '
            'Tanzil Project — tanzil.net। লাইসেন্স: CC BY 3.0, '
            'টেক্সট অপরিবর্তিত রাখা হয়েছে।\n\n'
            'বাংলা অনুবাদ: তাইসীরুল কুরআন (তাওহীদ পাবলিকেশন্স), '
            'Quran.com-এর মাধ্যমে।\n\n'
            'শব্দে শব্দে অর্থ: Quran.com।\n\n'
            'সূরা ও পারার তথ্য: Quran.com।\n\n'
            'পড়ি অ্যাপে কোনো কুরআন টেক্সট বা অনুবাদ হাতে লেখা হয়নি।',
            style: TextStyle(height: 1.7),
          ),
        ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDeep)),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(bn(value.round()),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ],
      );
}
