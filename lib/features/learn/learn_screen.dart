import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _modules = [
    (Icons.auto_stories_rounded, 'তাজবীদ শিক্ষা',
        'সঠিক নিয়মে কুরআন তিলাওয়াতের নিয়মকানুন'),
    (Icons.record_voice_over_rounded, 'মাখরাজ শিক্ষা',
        'আরবি হরফের সঠিক উচ্চারণস্থল'),
    (Icons.abc_rounded, 'আরবি হরফ পরিচিতি', 'শুরু থেকে ধাপে ধাপে'),
    (Icons.translate_rounded, 'শব্দে শব্দে অর্থ',
        'কুরআনের শব্দ চিনে অর্থ বুঝি'),
    (Icons.quiz_rounded, 'কুইজ', 'শেখা যাচাই করুন'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('শিখি')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          EmeraldBanner(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আপনার শেখার যাত্রা',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream)),
                const SizedBox(height: 6),
                Text('যাচাইকৃত পাঠ ও কোর্স ধাপে ধাপে যুক্ত হবে',
                    style: TextStyle(
                        color: AppColors.cream.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, sub) in _modules) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: cs.primary),
                ),
                title: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                subtitle: Text(sub),
                trailing: const ComingSoonChip(),
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text('$title — যাচাইকৃত পাঠ শীঘ্রই আসছে'))),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
