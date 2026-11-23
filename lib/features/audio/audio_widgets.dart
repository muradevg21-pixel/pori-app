import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn.dart';
import 'audio_downloads.dart';
import 'audio_player.dart';
import 'reciters.dart';

/// Bottom bar shown in the reader while a recitation is active.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.surahName});
  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(recitationProvider);
    if (!st.active) return const SizedBox.shrink();
    final n = ref.read(recitationProvider.notifier);
    final reciter = ref.watch(currentReciterProvider);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => showReciterPicker(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$surahName · আয়াত ${bn(st.verse ?? 1)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.cream,
                            fontWeight: FontWeight.w700)),
                    Text(reciter?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.goldLight.withValues(alpha: 0.9))),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'আগের আয়াত',
              onPressed: n.previous,
              icon: const Icon(Icons.skip_previous_rounded, color: AppColors.cream),
            ),
            SizedBox.square(
              dimension: 48,
              child: st.loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.gold))
                  : IconButton.filled(
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emerald950),
                      tooltip: st.playing ? 'বিরতি' : 'চালান',
                      onPressed: n.toggle,
                      icon: Icon(st.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                    ),
            ),
            IconButton(
              tooltip: 'পরের আয়াত',
              onPressed: n.next,
              icon: const Icon(Icons.skip_next_rounded,
                  color: AppColors.cream),
            ),
            IconButton(
              tooltip: 'বন্ধ করুন',
              onPressed: n.stop,
              icon: Icon(Icons.close_rounded,
                  color: AppColors.cream.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showReciterPicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ReciterSheet(),
    );

class _ReciterSheet extends ConsumerWidget {
  const _ReciterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(recitersProvider).value ?? const [];
    final current = ref.watch(currentReciterProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('ক্বারী নির্বাচন করুন',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final r in list)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(
                  r.id == current?.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: r.id == current?.id ? AppColors.gold : null,
                ),
                title: Text(r.name),
                subtitle: r.style.isEmpty ? null : Text(r.style),
                onTap: () {
                  final playing = ref.read(recitationProvider);
                  ref.read(settingsProvider.notifier).setReciter(r.id);
                  if (playing.active) {
                    ref.read(recitationProvider.notifier).stop();
                  }
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// App-bar action: download the current surah's recitation for offline use.
class DownloadSurahButton extends ConsumerStatefulWidget {
  const DownloadSurahButton(
      {super.key, required this.surah, required this.verseCount});
  final int surah;
  final int verseCount;

  @override
  ConsumerState<DownloadSurahButton> createState() =>
      _DownloadSurahButtonState();
}

class _DownloadSurahButtonState extends ConsumerState<DownloadSurahButton> {
  int? _checkedFor;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final reciter = ref.watch(currentReciterProvider);
    if (reciter == null) return const SizedBox.shrink();
    final key = (reciter: reciter.id, surah: widget.surah);
    if (_checkedFor != reciter.id) {
      _checkedFor = reciter.id;
      ref.read(audioDownloadsProvider.notifier).refresh(reciter.id, widget.surah);
    }
    final st = ref.watch(audioDownloadsProvider);
    final progress = st.progress[key];
    final done = st.done.contains(key);
    final n = ref.read(audioDownloadsProvider.notifier);

    if (progress != null) {
      return IconButton(
        tooltip: 'ডাউনলোড বাতিল',
        onPressed: () => n.cancel(key),
        icon: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
              value: progress, strokeWidth: 2.5, color: AppColors.gold),
        ),
      );
    }
    return IconButton(
      tooltip: done ? 'অফলাইনে আছে' : 'অফলাইনের জন্য ডাউনলোড',
      icon: Icon(
        done ? Icons.download_done_rounded : Icons.download_rounded,
        color: done ? AppColors.gold : null,
      ),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (done) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('ডাউনলোড মুছবেন?'),
              content: Text('${reciter.name}-এর এই সূরার অডিও ফোন থেকে মুছে যাবে।'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('না')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('মুছুন')),
              ],
            ),
          );
          if (ok == true) await n.delete(reciter.id, widget.surah, widget.verseCount);
          return;
        }
        messenger.showSnackBar(SnackBar(
            content: Text('${reciter.name}-এর তিলাওয়াত ডাউনলোড হচ্ছে…')));
        try {
          await n.download(reciter, widget.surah, widget.verseCount);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text('ডাউনলোড সম্পন্ন — এখন অফলাইনে শোনা যাবে')));
        } catch (_) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text('ডাউনলোড ব্যর্থ। ইন্টারনেট সংযোগ পরীক্ষা করুন।')));
        }
      },
    );
  }
}
