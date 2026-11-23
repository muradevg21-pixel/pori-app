import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/islamic_pattern.dart';
import 'data/quran_models.dart';
import 'data/quran_repository.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key, this.startSearching = false});
  final bool startSearching;

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String _query = '';
  late bool _searching = widget.startSearching;

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(quranMetaProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _searching
              ? TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'সূরার নাম বা নম্বর',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                )
              : const Text('আল-কুরআন'),
          actions: [
            IconButton(
              onPressed: () => setState(() {
                _searching = !_searching;
                _query = '';
              }),
              icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded),
              tooltip: 'খুঁজুন',
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'সূরা'), Tab(text: 'পারা')]),
        ),
        body: meta.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('ডেটা লোড করা যায়নি\n$e')),
          data: (m) => TabBarView(children: [
            _SurahList(meta: m, query: _query),
            _JuzList(meta: m),
          ]),
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.meta, required this.query});
  final QuranMeta meta;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final list = q.isEmpty
        ? meta.surahs
        : meta.surahs
            .where((s) =>
                s.nameLatin.toLowerCase().contains(q) ||
                s.meaningBn.contains(q) ||
                s.nameArabic.contains(q) ||
                s.number.toString() == q ||
                bn(s.number) == q)
            .toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => SurahTile(surah: list[i]),
    );
  }
}

class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.surah});
  final SurahInfo surah;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.reader(surah.number)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              StarBadge(label: bn(surah.number), size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surah.nameLatin,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.meaningBn} · ${surah.isMakki ? 'মাক্কী' : 'মাদানী'} · ${bn(surah.verseCount)} আয়াত',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: AppFonts.arabic,
                      fontSize: 22,
                      color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.meta});
  final QuranMeta meta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: meta.juz.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final j = meta.juz[i];
        final s = meta.surah(j.startSurah);
        final e = meta.surah(j.endSurah);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                context.push(Routes.reader(j.startSurah, verse: j.startVerse)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  StarBadge(
                      label: bn(j.number), size: 46, color: AppColors.gold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('পারা ${bn(j.number)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${s.nameLatin} ${bn(j.startVerse)} — ${e.nameLatin} ${bn(j.endVerse)}',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text('${bn(j.verseCount)} আয়াত',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
