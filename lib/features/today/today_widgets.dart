import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../checklists/draft_store.dart';
import '../checklists/models.dart';
import '../sync/sync_service.dart';

String shiftLabel(BuildContext context, String shift) {
  final l10n = context.l10n;
  return switch (shift) {
    'opening' => l10n.shiftOpening,
    'mid' => l10n.shiftMid,
    'closing' => l10n.shiftClosing,
    _ => l10n.shiftOther,
  };
}

/// "Opening checklist · Due 09:00 · Start" card (design screen 1).
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.run, this.stats, this.featured = false});
  final ChecklistRun run;
  final TemplateStats? stats;
  final bool featured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waiting = ref.watch(syncProvider.select((s) => s.hasPendingSubmit(run.id)));
    final draft = ref.watch(checklistDraftStoreProvider).load(run.id);
    final items = stats?.items ?? 0;
    final done = draft.length.clamp(0, items == 0 ? draft.length : items);
    final icon = run.isAudit
        ? Icons.assignment_turned_in_outlined
        : (run.templateName.toLowerCase().contains('temp') ? Icons.thermostat_outlined : Icons.fact_check_outlined);

    Widget pill;
    if (waiting) {
      pill = Pill(l10n.waitingToSyncShort, tone: Tone.info, icon: Icons.cloud_upload_outlined);
    } else if (run.isSubmitted) {
      pill = Pill(run.isLate ? l10n.doneLate : l10n.done, tone: run.isLate ? Tone.warning : Tone.primary);
    } else if (run.isMissed) {
      pill = Pill(l10n.missed, tone: Tone.danger);
    } else if (run.isLate) {
      pill = Pill(l10n.lateDue(Fmt.time(run.dueAt)), tone: Tone.danger);
    } else {
      pill = Pill(l10n.dueAt(Fmt.time(run.dueAt)), tone: Tone.warning);
    }

    final subtitle = run.isOpen
        ? (stats == null
            ? shiftLabel(context, run.shift)
            : [
                l10n.itemsCount(items),
                if (stats!.photos > 0) l10n.needPhotoCount(stats!.photos),
                if (draft.isNotEmpty) l10n.startedCount(done),
              ].join(' · '))
        : run.isSubmitted
            ? l10n.submittedAtTime(Fmt.time(run.submittedAt ?? run.dueAt))
            : shiftLabel(context, run.shift);

    void open() => context.push('/checklist/${run.id}');

    if (!featured || !run.isOpen || waiting) {
      return AppCard(
        onTap: open,
        child: Row(
          children: [
            IconTile(icon, tone: run.isSubmitted ? Tone.primary : Tone.info),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(run.templateName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            pill,
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(run.templateName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              pill,
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: items == 0 ? 0 : done / items),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: open,
              child: Text(draft.isEmpty
                  ? (run.isAudit ? l10n.startAudit : l10n.startChecklist)
                  : l10n.continueChecklist),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner for work still waiting to sync, or that failed to sync.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.watch(syncProvider);
    if (sync.failed.isNotEmpty) {
      final job = sync.failed.first;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard(
          color: AppColors.dangerSoft,
          borderColor: AppColors.dangerBorder,
          radius: 14,
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.syncFailed(job.label, job.error ?? ''),
                    style: const TextStyle(fontSize: 13, color: AppColors.dangerDark)),
              ),
              TextButton(
                onPressed: () => ref.read(syncProvider.notifier).discard(job.id),
                child: Text(l10n.dismiss),
              ),
            ],
          ),
        ),
      );
    }
    if (sync.pending == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InfoBanner(
        icon: sync.running ? Icons.sync_rounded : Icons.cloud_upload_outlined,
        text: l10n.itemsWaitingToSync(sync.pending),
      ),
    );
  }
}
