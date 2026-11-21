import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/media_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../session/people.dart';
import '../session/session_provider.dart';
import '../sync/sync_service.dart';
import 'checklist_repository.dart';
import 'models.dart';

/// Read-only result of a checklist or audit (outlet manager, area manager).
class RunDetailScreen extends ConsumerWidget {
  const RunDetailScreen({super.key, required this.runId});
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final run = ref.watch(runProvider(runId));
    final waiting = ref.watch(syncProvider.select((s) => s.hasPendingSubmit(runId)));

    return Scaffold(
      appBar: AppBar(
        title: run.maybeWhen(
          data: (r) => TwoLineTitle(r.templateName, ref.watch(sessionProvider).value?.outlets[r.outletId]?.name),
          orElse: () => const SizedBox(),
        ),
      ),
      body: AsyncBody(
        value: run,
        onRetry: () => ref.invalidate(runProvider(runId)),
        builder: (r) {
          final items = ref.watch(runItemsProvider(r.templateVersionId));
          final responses = ref.watch(runResponsesProvider(runId));
          final people = ref.watch(peopleProvider(peopleKey([r.submittedBy, r.conductedBy])));
          final who = people.value?[r.submittedBy]?.name;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(runProvider(runId));
              ref.invalidate(runResponsesProvider(runId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoBanner(icon: Icons.cloud_upload_outlined, text: l10n.waitingToSync),
                  ),
                GroupedCard(children: [
                  KeyValueRow(label: l10n.status, value: _statusLabel(context, r), valueColor: _statusColor(r)),
                  KeyValueRow(label: l10n.due, value: Fmt.dayTime(r.dueAt)),
                  if (r.submittedAt != null)
                    KeyValueRow(
                        label: l10n.submitted,
                        value: '${Fmt.dayTime(r.submittedAt!)}${who == null ? '' : ' · $who'}'),
                  if (r.compliancePct != null)
                    KeyValueRow(
                        label: l10n.result,
                        value: l10n.passedOf((r.itemCount ?? 0) - (r.failedCount ?? 0), r.itemCount ?? 0)),
                  if (r.withinGeofence != null)
                    KeyValueRow(
                      label: l10n.location,
                      value: r.withinGeofence! ? l10n.insideOutlet : l10n.outsideOutlet,
                      valueColor: r.withinGeofence! ? AppColors.primary : AppColors.danger,
                    ),
                ]),
                const SizedBox(height: 20),
                if (r.isSubmitted)
                  AsyncBody(
                    value: items,
                    builder: (its) => AsyncBody(
                      value: responses,
                      builder: (resps) {
                        final byItem = {for (final x in resps) x.itemId: x};
                        return Column(
                          children: [
                            for (final it in its)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ResponseCard(item: it, response: byItem[it.id]),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  EmptyState(
                    icon: r.isMissed ? Icons.event_busy_outlined : Icons.hourglass_empty_rounded,
                    message: r.isMissed ? l10n.runMissedInfo : l10n.runNotSubmittedYet,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _statusLabel(BuildContext context, ChecklistRun r) {
    final l10n = context.l10n;
    if (r.isMissed) return l10n.missed;
    if (r.isSubmitted) return r.isLate ? l10n.submittedLate : l10n.submittedOnTime;
    return r.isLate ? l10n.late : l10n.notDoneYet;
  }

  static Color _statusColor(ChecklistRun r) {
    if (r.isMissed || (r.isOpen && r.isLate)) return AppColors.danger;
    if (r.isSubmitted && !r.isLate) return AppColors.primary;
    return AppColors.warning;
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.item, required this.response});
  final ChecklistItem item;
  final ChecklistResponse? response;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = response;
    final failed = r != null && !r.passed;
    String value;
    if (r == null) {
      value = '–';
    } else {
      value = switch (item.answerType) {
        AnswerType.yesNo => r.valueBool == null ? '–' : (r.valueBool! ? l10n.yes : l10n.no),
        AnswerType.number => '${r.valueNumber ?? '–'} ${item.unit ?? ''}'.trim(),
        AnswerType.text => r.valueText ?? '–',
        AnswerType.photo => l10n.photoCount(r.photoMediaIds.length),
      };
    }
    return AppCard(
      radius: 16,
      borderColor: failed ? AppColors.dangerBorder : AppColors.border,
      borderWidth: failed ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: failed ? AppColors.danger : AppColors.text)),
            ],
          ),
          if (failed) ...[
            const SizedBox(height: 6),
            Text(l10n.failedRaisedIssue,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
          ],
          for (final m in r?.photoMediaIds ?? const <String>[]) ...[
            const SizedBox(height: 10),
            MediaImage(m, height: 160, caption: r == null ? null : Fmt.dayTime(r.answeredAt)),
          ],
        ],
      ),
    );
  }
}
