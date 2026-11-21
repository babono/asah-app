import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import 'models.dart';

/// One module in a list: title, category, status and progress.
class AssignmentTile extends StatelessWidget {
  const AssignmentTile({super.key, required this.assignment, this.onTap});
  final Assignment assignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return AppCard(
      onTap: onTap,
      radius: 16,
      borderColor: a.isOverdue ? AppColors.dangerBorder : AppColors.border,
      child: Row(
        children: [
          IconTile(
            a.isCompleted ? Icons.check_rounded : Icons.menu_book_outlined,
            tone: a.isCompleted ? Tone.primary : (a.isOverdue ? Tone.danger : Tone.info),
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [a.category, if (a.estimatedMinutes != null) context.l10n.minutesShort(a.estimatedMinutes!)]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (!a.isCompleted && a.blocksTotal > 0) ...[
                  const SizedBox(height: 8),
                  ProgressBar(value: a.contentProgress, color: a.isOverdue ? AppColors.danger : AppColors.primary),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AssignmentStatusPill(a),
        ],
      ),
    );
  }
}

class AssignmentStatusPill extends StatelessWidget {
  const AssignmentStatusPill(this.a, {super.key});
  final Assignment a;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (a.isCompleted) return Pill(l10n.done, small: true);
    if (a.isOverdue) return Pill(l10n.overdue, tone: Tone.danger, small: true);
    if (a.source == 'refresher' || a.source == 'retraining') {
      return Pill(a.source == 'refresher' ? l10n.refresher : l10n.updated, tone: Tone.warning, small: true);
    }
    if (a.dueAt != null) return Pill(l10n.dueDate(Fmt.day(a.dueAt!)), tone: Tone.neutral, small: true);
    return const SizedBox.shrink();
  }
}
