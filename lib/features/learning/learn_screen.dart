import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../session/session_provider.dart';
import 'learning_repository.dart';
import 'models.dart';
import 'widgets.dart';

/// My learning path: progress, next module, modules by due window (T6, T10).
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final assignments = ref.watch(myAssignmentsProvider);
    final pathName = ref.watch(myPathNameProvider).value;

    final body = RefreshIndicator(
      onRefresh: () async => ref.invalidate(myAssignmentsProvider),
      child: AsyncBody(
        value: assignments,
        onRetry: () => ref.invalidate(myAssignmentsProvider),
        builder: (list) {
          final path = list.where((a) => a.isPathModule).toList();
          final extra = list.where((a) => !a.isPathModule && !a.isCompleted).toList();
          final done = path.where((a) => a.isCompleted).length;
          final next = list.where((a) => !a.isCompleted).firstOrNull;

          List<Assignment> window(bool Function(int d) test) =>
              path.where((a) => a.dueDays != null && test(a.dueDays!)).toList();
          final groups = <(String, List<Assignment>)>[
            (l10n.day1, window((d) => d <= 1)),
            (l10n.week1, window((d) => d > 1 && d <= 7)),
            (l10n.month1, window((d) => d > 7 && d <= 30)),
            (l10n.later, [...window((d) => d > 30), ...path.where((a) => a.dueDays == null)]),
          ].where((g) => g.$2.isNotEmpty).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (!standalone)
                TabHeader(
                  title: l10n.myLearning,
                  overline: session.profile.positionName,
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
                ),
              if (standalone) const SizedBox(height: 16),
              if (list.isEmpty)
                EmptyState(icon: Icons.menu_book_outlined, message: l10n.noModulesYet)
              else ...[
                PathProgressCard(
                  title: pathName ?? l10n.myPath,
                  done: done,
                  total: path.length,
                  next: next,
                  onOpenNext: next == null ? null : () => context.push('/module/${next.id}'),
                ),
                if (extra.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionTitle(l10n.assignedToYou),
                  for (final a in extra)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AssignmentTile(assignment: a, onTap: () => context.push('/module/${a.id}')),
                    ),
                ],
                for (final g in groups) ...[
                  const SizedBox(height: 24),
                  SectionTitle(g.$1,
                      trailing: Text('${g.$2.where((a) => a.isCompleted).length}/${g.$2.length}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  for (final a in g.$2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AssignmentTile(assignment: a, onTap: () => context.push('/module/${a.id}')),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );

    if (!standalone) return SafeArea(bottom: false, child: body);
    return Scaffold(appBar: AppBar(title: Text(l10n.myLearning)), body: body);
  }
}

/// The green "Server path · Week 1 · 40%" card from the Today design.
class PathProgressCard extends StatelessWidget {
  const PathProgressCard({super.key, required this.title, required this.done, required this.total, this.next, this.onOpenNext});
  final String title;
  final int done;
  final int total;
  final Assignment? next;
  final VoidCallback? onOpenNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = total == 0 ? 0 : (done * 100 / total).round();
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenNext,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppColors.onPrimaryMuted)),
                  ),
                  Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 14),
              ProgressBar(value: total == 0 ? 0 : done / total, color: AppColors.accent, background: Colors.white24),
              const SizedBox(height: 14),
              if (next != null)
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next!.pathSort != null && total > 0
                                ? l10n.upNextModuleOf((next!.pathSort ?? 0).clamp(1, total), total)
                                : l10n.upNext,
                            style: const TextStyle(fontSize: 12, color: AppColors.onPrimaryMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(next!.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Text(l10n.pathComplete,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
