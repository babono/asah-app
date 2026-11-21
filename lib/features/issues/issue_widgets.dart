import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import 'issue_repository.dart';

/// Status pill for an issue as the manager needs to read it.
Pill issueStatusPill(BuildContext context, Issue i, {bool small = true}) {
  final l10n = context.l10n;
  if (i.isClosed) return Pill(l10n.closed, small: small);
  if (i.isFixed) return Pill(l10n.checkFix, tone: Tone.info, small: small);
  if (i.escalatedAt != null) return Pill(l10n.escalated, tone: Tone.danger, small: small);
  if (i.assignedTo == null) return Pill(l10n.notAssigned, tone: Tone.danger, small: small);
  if (i.isLate) return Pill(l10n.late, tone: Tone.danger, small: small);
  return Pill(l10n.assigned, tone: Tone.warning, small: small);
}

Pill severityPill(BuildContext context, String severity) {
  final l10n = context.l10n;
  return switch (severity) {
    'high' => Pill(l10n.severityHigh, tone: Tone.danger),
    'low' => Pill(l10n.severityLow, tone: Tone.neutral),
    _ => Pill(l10n.severityMedium, tone: Tone.warning),
  };
}

String issueSourceLabel(BuildContext context, Issue i) {
  final l10n = context.l10n;
  return switch (i.source) {
    'checklist' => l10n.fromChecklist(i.runName ?? ''),
    'audit' => l10n.fromAudit(i.runName ?? ''),
    _ => l10n.raisedByHand,
  };
}

class IssueCard extends StatelessWidget {
  const IssueCard({super.key, required this.issue, this.outletName, this.ownerName});
  final Issue issue;
  final String? outletName;
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final i = issue;
    final alert = i.isOpen && (i.assignedTo == null || i.isLate);
    String dueLine;
    if (i.isClosed) {
      dueLine = l10n.closedAt(Fmt.dayTime(i.closedAt ?? i.createdAt));
    } else if (i.isFixed) {
      dueLine = l10n.fixWaitingForCheck(Fmt.time(i.fixedAt ?? i.createdAt));
    } else if (i.isLate) {
      dueLine = l10n.lateSince(Fmt.dayTime(i.dueAt));
    } else {
      dueLine = l10n.dueEscalatesAfter(Fmt.dayTime(i.dueAt));
    }
    return AppCard(
      onTap: () => context.push('/issues/${i.id}'),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: alert ? AppColors.dangerBorder : AppColors.border,
      borderWidth: alert ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(i.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              issueStatusPill(context, i),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [issueSourceLabel(context, i), outletName, if (ownerName != null) ownerName].whereType<String>().join(' · '),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            dueLine,
            style: TextStyle(
              fontSize: 13,
              fontWeight: alert ? FontWeight.w600 : FontWeight.w400,
              color: alert ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
