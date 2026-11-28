import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../checklists/checklist_repository.dart';
import '../checklists/models.dart';
import '../issues/issue_repository.dart';
import '../issues/issue_widgets.dart';
import '../mentorship/formal_training_repository.dart';
import '../mentorship/formal_training_screens.dart';
import '../mentorship/mentorship_repository.dart';
import '../notifications/notifications_screen.dart';
import '../session/people.dart';
import '../session/session_provider.dart';
import '../../app/home_shell.dart';
import 'today_widgets.dart';

/// People at an outlet with overdue modules (v_training_progress).
final behindAtOutletProvider = FutureProvider.family<List<({String userId, int overdue})>, String>((ref, outletId) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('v_training_progress')
      .select('user_id, overdue')
      .eq('outlet_id', outletId)
      .gt('overdue', 0);
  return (rows as List).map((r) => (userId: r['user_id'] as String, overdue: (r['overdue'] as num).toInt())).toList();
});

final outletMentorshipsProvider = FutureProvider.family<List<Mentorship>, String>(
  (ref, outletId) => ref.watch(mentorshipRepositoryProvider).atOutlet(outletId),
);

/// Outlet manager Today: checklist status, open issues and training
/// escalations on one page (A7, S1, M4; design screen 6). Area managers open
/// it for any outlet in their area.
class ManagerTodayScreen extends ConsumerWidget {
  const ManagerTodayScreen({super.key, this.outletId});
  final String? outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final outlet = outletId == null ? session.managedOutlet : session.outlets[outletId];
    if (outlet == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noOutletAssigned)));
    }
    final runs = ref.watch(outletRunsTodayProvider(outlet.id));
    final issues = ref.watch(outletIssuesProvider(outlet.id));
    final standalone = outletId != null;

    Future<void> refresh() async {
      ref.invalidate(outletRunsTodayProvider(outlet.id));
      ref.invalidate(outletIssuesProvider(outlet.id));
      ref.invalidate(behindAtOutletProvider(outlet.id));
      ref.invalidate(outletMentorshipsProvider(outlet.id));
      ref.invalidate(outletFormalTrainingsProvider(outlet.id));
      ref.invalidate(myRunsTodayProvider);
    }

    final content = RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (!standalone)
            TabHeader(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              overline: '${l10n.outletManager} · ${DateFormat.EEEE(Localizations.localeOf(context).toString()).format(DateTime.now())}',
              title: l10n.outletToday(outlet.name),
              trailing: const NotificationBell(),
            )
          else
            const SizedBox(height: 16),
          if (!standalone) const SyncBanner(),
          _Stats(runs: runs.value, issues: issues.value),
          const SizedBox(height: 24),
          SectionTitle(l10n.checklistsByShift),
          AsyncBody(
            value: runs,
            onRetry: () => ref.invalidate(outletRunsTodayProvider(outlet.id)),
            builder: (list) => list.isEmpty
                ? EmptyState(icon: Icons.fact_check_outlined, message: l10n.noChecklistsScheduledToday)
                : _ShiftList(runs: list),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            l10n.openIssues,
            trailing: standalone
                ? null
                : TextButton(
                    onPressed: () => ref.read(homeTabProvider.notifier).select(HomeTab.issues),
                    child: Text(l10n.allIssues),
                  ),
          ),
          AsyncBody(
            value: issues,
            onRetry: () => ref.invalidate(outletIssuesProvider(outlet.id)),
            builder: (list) {
              if (list.isEmpty) return EmptyState(icon: Icons.check_circle_outline, message: l10n.noOpenIssues);
              final names = ref.watch(peopleProvider(peopleKey(list.map((i) => i.assignedTo)))).value ?? {};
              return Column(
                children: [
                  for (final i in list.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IssueCard(issue: i, ownerName: names[i.assignedTo]?.name),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _TrainingSection(outletId: outlet.id),
          _FormalTrainingsSection(outletId: outlet.id),
          if (!standalone && session.canFill) ...[
            const SizedBox(height: 24),
            const _MyTasks(),
          ],
        ],
      ),
    );

    if (!standalone) return SafeArea(bottom: false, child: content);
    return Scaffold(appBar: AppBar(title: TwoLineTitle(outlet.name, l10n.today)), body: content);
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.runs, required this.issues});
  final List<ChecklistRun>? runs;
  final List<Issue>? issues;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = runs ?? [];
    final done = r.where((x) => x.isSubmitted).length;
    final late = r.where((x) => x.isMissed || (x.isOpen && x.isLate)).length;
    final open = (issues ?? []).length;
    return Row(
      children: [
        Expanded(child: StatTile(value: runs == null ? '–' : '$done/${r.length}', label: l10n.checklistsDone)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(value: issues == null ? '–' : '$open', label: l10n.openIssues)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(value: runs == null ? '–' : '$late', label: l10n.lateChecklists, alert: late > 0)),
      ],
    );
  }
}

class _ShiftList extends StatelessWidget {
  const _ShiftList({required this.runs});
  final List<ChecklistRun> runs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GroupedCard(children: [
      for (final r in runs)
        InkWell(
          onTap: () => context.push('/run/${r.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: r.isSubmitted && !r.isLate
                        ? AppColors.primary
                        : (r.isMissed || r.isLate ? AppColors.danger : AppColors.dashed),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${shiftLabel(context, r.shift)} · ${r.templateName}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Text(
                  r.isMissed
                      ? l10n.missed
                      : r.isSubmitted
                          ? (r.failedCount != null && r.failedCount! > 0
                              ? l10n.doneFailedItems(r.failedCount!)
                              : (r.isLate ? l10n.doneLate : l10n.done))
                          : (r.isLate ? l10n.lateDue(Fmt.time(r.dueAt)) : l10n.dueAt(Fmt.time(r.dueAt))),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: r.isMissed || (r.isOpen && r.isLate) || (r.failedCount ?? 0) > 0
                        ? AppColors.danger
                        : r.isSubmitted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
    ]);
  }
}

class _TrainingSection extends ConsumerWidget {
  const _TrainingSection({required this.outletId});
  final String outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final behind = ref.watch(behindAtOutletProvider(outletId));
    final mentorships = ref.watch(outletMentorshipsProvider(outletId)).value ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.training),
        AsyncBody(
          value: behind,
          builder: (list) {
            if (list.isEmpty) return EmptyState(icon: Icons.school_outlined, message: l10n.everyoneOnSchedule);
            final names = ref.watch(peopleProvider(peopleKey(list.map((b) => b.userId)))).value ?? {};
            return Column(
              children: [
                for (final b in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Avatar(names[b.userId]?.name ?? '?', tone: Tone.danger, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.personBehind(names[b.userId]?.name ?? ''),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Text(
                                  [
                                    l10n.modulesOverdue(b.overdue),
                                    if (mentorships.where((m) => m.traineeId == b.userId).firstOrNull?.mentorName
                                        case final mentor?)
                                      l10n.mentorName(mentor),
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => context.push('/team/${b.userId}'),
                            child: Text(l10n.review),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Approved formal trainings at the outlet, so managers can drop in.
class _FormalTrainingsSection extends ConsumerWidget {
  const _FormalTrainingsSection({required this.outletId});
  final String outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(outletFormalTrainingsProvider(outletId)).value ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        SectionTitle(context.l10n.formalTrainingsScheduled),
        for (final t in list.take(6)) FormalTrainingTile(training: t, showPeople: true),
      ],
    );
  }
}

class _MyTasks extends ConsumerWidget {
  const _MyTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final runs = ref.watch(myRunsTodayProvider).value ?? [];
    final stats = ref.watch(templateStatsProvider).value ?? {};
    if (runs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.myTasks),
        for (final r in runs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TaskCard(run: r, stats: stats[r.templateVersionId]),
          ),
      ],
    );
  }
}
