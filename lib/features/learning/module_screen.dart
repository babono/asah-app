import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/media_repository.dart';
import '../../core/media/media_widgets.dart';
import '../../core/media/offline_videos.dart';
import '../../core/offline/connectivity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../sync/sync_service.dart';
import 'learning_repository.dart';
import 'models.dart';

/// A module: videos, SOP cards and PDFs, then quiz and practical test
/// (T1, T2, T3, T10; design screen 3).
class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(moduleDetailProvider(assignmentId));
    return Scaffold(
      appBar: AppBar(
        title: detail.maybeWhen(
          data: (d) => TwoLineTitle(
            d.assignment.title,
            d.positionInPath != null && d.pathLength != null
                ? l10n.moduleOfPath(d.positionInPath!, d.pathLength!, d.pathName ?? '')
                : d.assignment.category,
          ),
          orElse: () => const SizedBox(),
        ),
        actions: [
          detail.maybeWhen(data: (d) => _OfflineToggle(detail: d), orElse: () => const SizedBox()),
        ],
      ),
      body: AsyncBody(
        value: detail,
        onRetry: () => ref.invalidate(moduleDetailProvider(assignmentId)),
        builder: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(moduleDetailProvider(assignmentId)),
          child: _ModuleBody(detail: d),
        ),
      ),
    );
  }
}

class _ModuleBody extends ConsumerWidget {
  const _ModuleBody({required this.detail});
  final ModuleDetail detail;

  Future<void> _complete(BuildContext context, WidgetRef ref, ContentBlock block) async {
    if (detail.completedBlockIds.contains(block.id)) return;
    final a = detail.assignment;
    final repo = ref.read(learningRepositoryProvider);
    try {
      await repo.completeBlock(a.id, block.id);
    } catch (e) {
      if (!isNetworkError(e)) {
        if (context.mounted) showSnack(context, friendlyError(e), error: true);
        return;
      }
      // Offline: remember it and send later (F7).
      await ref.read(syncProvider.notifier).enqueue('complete_block', {
        'label': a.title,
        'assignment_id': a.id,
        'block_id': block.id,
      });
      await repo.markBlockDoneLocally(a.id, block.id);
    }
    ref.invalidate(moduleDetailProvider(a.id));
    ref.invalidate(myAssignmentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = detail;
    final a = d.assignment;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (a.isCompleted)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InfoBanner(
              icon: Icons.verified_outlined,
              text: d.certificateValidDays != null ? l10n.moduleCompletedCertificate : l10n.moduleCompleted,
            ),
          )
        else if (a.summary != null && a.summary!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(a.summary!, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textStrong)),
          ),
        for (final b in d.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _BlockView(
              block: b,
              done: d.completedBlockIds.contains(b.id),
              onDone: () => _complete(context, ref, b),
            ),
          ),
        if (d.quiz != null) ...[
          _QuizCard(detail: d),
          const SizedBox(height: 16),
        ],
        if (d.rubric.isNotEmpty) _PracticalCard(detail: d),
      ],
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.done, required this.onDone});
  final ContentBlock block;
  final bool done;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (block.type) {
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamVideo(
              mediaId: block.mediaFileId!,
              caption: block.durationSeconds == null
                  ? l10n.video
                  : '${l10n.video} · ${Fmt.duration(block.durationSeconds!)}',
              onFinished: onDone,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(block.title ?? l10n.video,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                _DoneButton(done: done, label: l10n.markWatched, onTap: onDone),
              ],
            ),
          ],
        );
      case 'document':
        return AppCard(
          radius: 16,
          child: Row(
            children: [
              const IconTile(Icons.picture_as_pdf_outlined, tone: Tone.danger, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(block.title ?? l10n.document,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async {
                    try {
                      final url = await ref.read(mediaRepositoryProvider).signedUrl(block.mediaFileId!);
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      onDone();
                    } catch (e) {
                      if (context.mounted) showSnack(context, friendlyError(e), error: true);
                    }
                  },
                  child: Text(done ? l10n.openAgain : l10n.open),
                ),
              ),
            ],
          ),
        );
      default: // sop_card
        return AppCard(
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(block.title ?? l10n.sopCard,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  if (done) Pill(l10n.read, small: true),
                ],
              ),
              if (block.mediaFileId != null) ...[
                const SizedBox(height: 12),
                MediaImage(block.mediaFileId!, height: 180),
              ],
              const SizedBox(height: 8),
              MarkdownBody(
                data: block.body ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, height: 1.5),
                  listBullet: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              if (!done) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onDone, child: Text(l10n.markAsRead)),
              ],
            ],
          ),
        );
    }
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.done, required this.label, required this.onTap});
  final bool done;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (done) return Pill(context.l10n.done, icon: Icons.check_rounded, small: true);
    return TextButton(onPressed: onTap, child: Text(label));
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.detail});
  final ModuleDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = detail;
    final quiz = d.quiz!;
    final last = d.lastAttempt;
    final left = d.attemptsLeft;
    final canStart = !d.quizPassed && (left == null || left > 0);

    return AppCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.quizPassMark(quiz.passMarkPct),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (d.quizPassed)
                Pill(l10n.passed, small: true)
              else if (left != null)
                Pill(l10n.attemptsLeft(left), tone: left == 0 ? Tone.danger : Tone.neutral, small: true),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.lastScore(Fmt.pct(last.scorePct)),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: last.passed == true ? AppColors.primary : AppColors.danger,
              ),
            ),
          ],
          if (!d.contentDone && !d.quizPassed) ...[
            const SizedBox(height: 8),
            Text(l10n.finishLessonsFirst, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          if (left == 0 && !d.quizPassed) ...[
            const SizedBox(height: 8),
            Text(l10n.noAttemptsLeft, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          if (canStart) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/module/${d.assignment.id}/quiz'),
              child: Text(last == null ? l10n.startQuiz : l10n.retakeQuiz),
            ),
          ],
        ],
      ),
    );
  }
}

class _PracticalCard extends StatelessWidget {
  const _PracticalCard({required this.detail});
  final ModuleDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = detail;
    final last = d.lastSubmission;
    final scores = {for (final s in last?.scores ?? <PracticalScore>[]) s.criterionId: s};

    Widget status;
    if (last == null) {
      status = Text(l10n.practicalHowTo, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary));
    } else if (last.status == 'pending') {
      status = InfoBanner(icon: Icons.hourglass_top_rounded, text: l10n.practicalWaiting);
    } else if (last.status == 'passed') {
      status = InfoBanner(icon: Icons.verified_outlined, text: l10n.practicalPassed);
    } else {
      status = InfoBanner(icon: Icons.replay_rounded, text: l10n.practicalRedo, danger: true);
    }

    return AppCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.practicalTest, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          status,
          const SizedBox(height: 12),
          for (final c in d.rubric)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (scores[c.id]?.note != null)
                          Text(scores[c.id]!.note!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (scores[c.id] != null)
                    Pill(scores[c.id]!.result == 'pass' ? l10n.pass : l10n.redo,
                        tone: scores[c.id]!.result == 'pass' ? Tone.primary : Tone.danger, small: true),
                ],
              ),
            ),
          if (last?.feedback != null && last!.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.mentorFeedback, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(last.feedback!, style: const TextStyle(fontSize: 14, height: 1.45)),
          ],
          if (!d.practicalPassed && !d.practicalPending) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/module/${d.assignment.id}/practical'),
              icon: const Icon(Icons.videocam_outlined),
              label: Text(last == null ? l10n.recordPracticalTest : l10n.recordAgain),
            ),
          ],
        ],
      ),
    );
  }
}

/// Download every video in the module for offline viewing (F7).
class _OfflineToggle extends ConsumerStatefulWidget {
  const _OfflineToggle({required this.detail});
  final ModuleDetail detail;

  @override
  ConsumerState<_OfflineToggle> createState() => _OfflineToggleState();
}

class _OfflineToggleState extends ConsumerState<_OfflineToggle> {
  bool _busy = false;
  double _progress = 0;

  List<String> get _videoIds =>
      widget.detail.blocks.where((b) => b.type == 'video' && b.mediaFileId != null).map((b) => b.mediaFileId!).toList();

  Future<void> _download() async {
    final l10n = context.l10n;
    final offline = ref.read(offlineVideosProvider);
    setState(() => _busy = true);
    try {
      final ids = _videoIds.where((id) => !offline.isDownloaded(id)).toList();
      for (var i = 0; i < ids.length; i++) {
        await offline.download(ids[i], onProgress: (p) {
          if (mounted) setState(() => _progress = (i + p) / ids.length);
        });
      }
      if (mounted) showSnack(context, l10n.savedForOffline);
    } on DownloadNotReady {
      if (mounted) showSnack(context, l10n.downloadPreparing);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_videoIds.isEmpty) return const SizedBox();
    final offline = ref.watch(offlineVideosProvider);
    final all = _videoIds.every(offline.isDownloaded);
    if (all) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Pill(l10n.offline, icon: Icons.download_done_rounded),
      );
    }
    if (_busy) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
            width: 22, height: 22, child: CircularProgressIndicator(value: _progress == 0 ? null : _progress, strokeWidth: 2.5)),
      );
    }
    final online = ref.watch(isOnlineProvider).value ?? true;
    return IconButton(
      tooltip: l10n.saveForOffline,
      onPressed: online ? _download : null,
      icon: const Icon(Icons.download_rounded),
    );
  }
}
