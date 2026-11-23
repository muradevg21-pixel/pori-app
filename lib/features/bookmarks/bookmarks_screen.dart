import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import '../progress/progress_store.dart';
import '../quran/data/quran_repository.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(progressProvider.select((p) => p.bookmarks));
    return Scaffold(
      appBar: AppBar(
        title: Text(bookmarks.isEmpty
            ? 'বুকমার্ক'
            : 'বুকমার্ক (${bn(bookmarks.length)})'),
      ),
      body: bookmarks.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'এখনও কোনো বুকমার্ক নেই',
              message:
                  'পড়ার সময় আয়াতের পাশে বুকমার্ক চিহ্নে চাপ দিলে তা এখানে দেখা যাবে।',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: bookmarks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = bookmarks[i];
                return Dismissible(
                  key: ValueKey(b.ref.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  onDismissed: (_) {
                    final n = ref.read(progressProvider.notifier)
                      ..removeBookmark(b.ref);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: const Text('বুকমার্ক মুছে ফেলা হয়েছে'),
                        action: SnackBarAction(
                            label: 'ফিরিয়ে আনুন',
                            onPressed: () => n.restoreBookmark(b, i)),
                      ));
                  },
                  child: _BookmarkTile(bookmark: b),
                );
              },
            ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.bookmark});
  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final r = bookmark.ref;
    final meta = ref.watch(quranMetaProvider).value;
    final verses = ref.watch(surahVersesProvider(r.surah)).value;
    final verse = (verses != null && r.verse <= verses.length)
        ? verses[r.verse - 1]
        : null;
    final name = meta?.surah(r.surah).nameLatin ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.reader(r.surah, verse: r.verse)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_rounded,
                      size: 18, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('$name · আয়াত ${bn(r.verse)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('${bn(r.surah)}:${bn(r.verse)}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
              if (verse != null) ...[
                const SizedBox(height: 10),
                Text(verse.arabicForDisplay,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontFamily: AppFonts.arabic,
                        fontSize: 22,
                        height: 1.9,
                        color: cs.primary)),
                const SizedBox(height: 4),
                Text(verse.translationBn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
