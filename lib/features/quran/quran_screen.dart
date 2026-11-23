import 'package:material_ui/material_ui.dart';

import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/islamic_pattern.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('আল-কুরআন'),
          actions: [
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                tooltip: 'খুঁজুন'),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'সূরা'), Tab(text: 'পারা')]),
        ),
        body: const TabBarView(children: [_SurahTab(), _JuzTab()]),
      ),
    );
  }
}

class _SurahTab extends StatelessWidget {
  const _SurahTab();

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: Icons.menu_book_rounded,
        title: '১১৪টি সূরা শীঘ্রই আসছে',
        message:
            'যাচাইকৃত উৎস থেকে আরবি টেক্সট, উচ্চারণ ও বাংলা অনুবাদ পরবর্তী ধাপে যুক্ত করা হবে।',
      );
}

class _JuzTab extends StatelessWidget {
  const _JuzTab();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: 30,
      itemBuilder: (context, i) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StarBadge(label: bn(i + 1), size: 46),
              const SizedBox(height: 8),
              Text('পারা ${bn(i + 1)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
