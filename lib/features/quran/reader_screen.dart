import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bn.dart';
import '../../core/widgets/common.dart';
import '../audio/audio_player.dart';
import '../audio/audio_widgets.dart';
import '../progress/progress_store.dart';
import 'data/quran_models.dart';
import 'data/quran_repository.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.initialVerse});
  final int surah;
  final int? initialVerse;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  bool _wordByWord = false;
  int _verseCount = 0;
  int _firstVisibleVerse = 1;

  // Reading time: counted in 15 s ticks while the app is in the foreground.
  static const _tick = 15;
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  late final ProgressNotifier _progress;
  late final RecitationNotifier _recitation;

  @override
  void initState() {
    super.initState();
    _progress = ref.read(progressProvider.notifier);
    _recitation = ref.read(recitationProvider.notifier);
    _positions.itemPositions.addListener(_onScroll);
    _startTimer();
    _lifecycle = AppLifecycleListener(
      onResume: _startTimer,
      onPause: () {
        _timer?.cancel();
        _progress.flush();
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: _tick),
        (_) => _progress.addReadingSeconds(_tick));
  }

  void _onScroll() {
    if (_verseCount == 0) return;
    final items = _positions.itemPositions.value
        .where((p) => p.index >= 1 && p.index <= _verseCount);
    if (items.isEmpty) return;
    final visible = items.where((p) => p.itemTrailingEdge > 0.05).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    if (visible.isEmpty) return;
    _firstVisibleVerse = visible.first.index;
    final fully = items
        .where((p) => p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 1)
        .map((p) => p.index);
    _progress.onVersesViewed(widget.surah, visible.first.index, fully);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    _positions.itemPositions.removeListener(_onScroll);
    _progress.flush();
    _recitation.stop();
    super.dispose();
  }

  void _followRecitation(RecitationState? prev, RecitationState next) {
    if (next.error != null && prev?.error != next.error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(next.error!)));
    }
    final v = next.verse;
    if (next.surah != widget.surah || v == null || v == prev?.verse) return;
    final shown = _positions.itemPositions.value.any((p) =>
        p.index == v && p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 0.9);
    if (!shown && _scroll.isAttached) {
      _scroll.scrollTo(
          index: v,
          alignment: 0.05,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recitationProvider, _followRecitation);
    final meta = ref.watch(quranMetaProvider).value;
    final verses = ref.watch(surahVersesProvider(widget.surah));
    final info = meta?.surah(widget.surah);

    return Scaffold(
      appBar: AppBar(
        title: Text(info?.nameLatin ?? ''),
        actions: [
          if (info != null) ...[
            _PlaySurahButton(info: info, firstVisible: () => _firstVisibleVerse),
            DownloadSurahButton(
                surah: info.number, verseCount: info.verseCount),
          ],
          IconButton(
            tooltip: 'শব্দে শব্দে অর্থ',
            isSelected: _wordByWord,
            icon: const Icon(Icons.translate_rounded),
            selectedIcon: const Icon(Icons.translate_rounded,
                color: AppColors.gold),
            onPressed: () => setState(() => _wordByWord = !_wordByWord),
          ),
          IconButton(
            tooltip: 'আয়াতে যান',
            icon: const Icon(Icons.format_list_numbered_rounded),
            onPressed: info == null ? null : () => _jumpDialog(info),
          ),
        ],
      ),
      bottomNavigationBar: MiniPlayer(surahName: info?.nameLatin ?? ''),
      body: (meta == null || info == null)
          ? const Center(child: CircularProgressIndicator())
          : verses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('লোড করা যায়নি: $e')),
              data: (list) => ScrollablePositionedList.builder(
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                initialScrollIndex: (widget.initialVerse ?? 0)
                    .clamp(0, list.length),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: list.length + 2,
                itemBuilder: (context, i) {
                  _verseCount = list.length;
                  if (i == 0) return _SurahHeader(info: info, meta: meta);
                  if (i == list.length + 1) return const _SourceFooter();
                  return _VerseCard(
                    surah: info,
                    verse: list[i - 1],
                    wordByWord: _wordByWord,
                  );
                },
              ),
            ),
    );
  }

  Future<void> _jumpDialog(SurahInfo info) async {
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('আয়াত নম্বর'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '১ - ${bn(info.verseCount)}'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: const Text('যান')),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= info.verseCount && _scroll.isAttached) {
      _scroll.scrollTo(
          index: n, duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    }
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.info, required this.meta});
  final SurahInfo info;
  final QuranMeta meta;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: EmeraldBanner(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Text(info.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontFamily: AppFonts.arabic,
                        fontSize: 36,
                        color: AppColors.goldLight)),
                Text(info.nameLatin,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream)),
                const SizedBox(height: 4),
                Text(
                  '${info.meaningBn} · ${info.isMakki ? 'মাক্কী' : 'মাদানী'} · ${bn(info.verseCount)} আয়াত',
                  style: TextStyle(
                      color: AppColors.cream.withValues(alpha: 0.8)),
                ),
                if (info.hasBismillah) ...[
                  const SizedBox(height: 16),
                  Container(
                      height: 1,
                      width: 120,
                      color: AppColors.gold.withValues(alpha: 0.5)),
                  const SizedBox(height: 14),
                  Text(meta.bismillah,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: AppFonts.arabic,
                          fontSize: 26,
                          height: 1.8,
                          color: AppColors.cream)),
                ],
              ],
            ),
          ),
        ),
      );
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({
    required this.surah,
    required this.verse,
    required this.wordByWord,
  });
  final SurahInfo surah;
  final Verse verse;
  final bool wordByWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final playing = ref.watch(recitationProvider
        .select((r) => r.isPlayingVerse(surah.number, verse.number)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Card(
        color: playing ? cs.primaryContainer.withValues(alpha: 0.55) : null,
        shape: playing
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.gold, width: 1.5))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${bn(surah.number)}:${bn(verse.number)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                  if (verse.sajdah) ...[
                    const SizedBox(width: 8),
                    const Text('সিজদা',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDeep)),
                  ],
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'এই আয়াত থেকে শুনুন',
                    icon: Icon(
                        playing
                            ? Icons.graphic_eq_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 20,
                        color: playing ? AppColors.gold : cs.onSurfaceVariant),
                    onPressed: () => ref
                        .read(recitationProvider.notifier)
                        .play(surah.number, verse.number, surah.verseCount),
                  ),
                  _BookmarkButton(ref: VerseRef(surah.number, verse.number)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'কপি',
                    icon: Icon(Icons.copy_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: '${verse.arabic}\n\n${verse.translationBn}\n'
                              '— ${surah.nameLatin} ${surah.number}:${verse.number}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('কপি হয়েছে')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (wordByWord)
                _WordGrid(words: verse.words, arabicSize: s.arabicFontSize)
              else
                Text(
                  '${verse.arabicForDisplay} ۝${arabicDigits(verse.number)}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFonts.arabic,
                    fontSize: s.arabicFontSize,
                    height: 2.0,
                    color: cs.onSurface,
                  ),
                ),
              if (s.showTranslation) ...[
                const SizedBox(height: 10),
                Text(verse.translationBn,
                    style: TextStyle(
                        fontSize: s.banglaFontSize,
                        height: 1.7,
                        color: cs.onSurface.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({required this.words, required this.arabicSize});
  final List<Word> words;
  final double arabicSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in words)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(w.arabic,
                      style: TextStyle(
                          fontFamily: AppFonts.arabic,
                          fontSize: arabicSize * 0.8,
                          height: 1.7,
                          color: cs.primary)),
                  Text(w.meaningBn,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceFooter extends StatelessWidget {
  const _SourceFooter();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          'আরবি টেক্সট: Tanzil Project (tanzil.net) · '
          'অনুবাদ: তাইসীরুল কুরআন · শব্দার্থ: Quran.com',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

class _BookmarkButton extends ConsumerWidget {
  const _BookmarkButton({required this.ref});
  final VerseRef ref;

  @override
  Widget build(BuildContext context, WidgetRef wr) {
    final marked =
        wr.watch(progressProvider.select((p) => p.isBookmarked(ref)));
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: marked ? 'বুকমার্ক সরান' : 'বুকমার্ক করুন',
      icon: Icon(
        marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 20,
        color: marked
            ? AppColors.gold
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () {
        wr.read(progressProvider.notifier).toggleBookmark(ref);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(marked ? 'বুকমার্ক সরানো হয়েছে' : 'বুকমার্ক করা হয়েছে'),
          ));
      },
    );
  }
}

class _PlaySurahButton extends ConsumerWidget {
  const _PlaySurahButton({required this.info, required this.firstVisible});
  final SurahInfo info;
  final int Function() firstVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(recitationProvider);
    final mine = st.active && st.surah == info.number;
    final n = ref.read(recitationProvider.notifier);
    return IconButton(
      tooltip: mine ? 'তিলাওয়াত বন্ধ' : 'তিলাওয়াত শুনুন',
      icon: Icon(
        mine ? Icons.stop_circle_outlined : Icons.headphones_rounded,
        color: mine ? AppColors.gold : null,
      ),
      onPressed: () => mine
          ? n.stop()
          : n.play(info.number, firstVisible().clamp(1, info.verseCount),
              info.verseCount),
    );
  }
}
