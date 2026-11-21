import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../checklists/checklist_repository.dart';
import '../learning/learn_screen.dart';
import '../learning/learning_repository.dart';
import '../mentorship/mentorship_repository.dart';
import '../notifications/notifications_screen.dart';
import '../session/session_provider.dart';
import '../sync/sync_service.dart';
import 'today_widgets.dart';

/// Staff Today: tasks due this shift above, learning path and mentor below
/// (Aksi + Asuh; design screen 1).
class StaffTodayScreen extends ConsumerWidget {
  const StaffTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final runs = ref.watch(myRunsTodayProvider);
    final stats = ref.watch(templateStatsProvider).value ?? {};
    final firstOpen = runs.value?.where((r) => r.isOpen).firstOrNull;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(syncProvider.notifier).processAll();
          ref.invalidate(myRunsTodayProvider);
          ref.invalidate(myAssignmentsProvider);
          ref.invalidate(myMentorshipsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            TabHeader(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              overline: [
                DateFormat.EEEE(Localizations.localeOf(context).toString()).format(DateTime.now()),
                if (firstOpen != null) shiftLabel(context, firstOpen.shift),
              ].join(' · '),
              title: l10n.hiName(session.profile.firstName),
              caption: [session.profile.positionName, session.outlet?.name].whereType<String>().join(' · '),
              trailing: const NotificationBell(),
            ),
            const SyncBanner(),
            if (session.canFill || session.isAreaManager) ...[
              SectionTitle(
                l10n.todaysTasks,
                trailing: runs.maybeWhen(
                  data: (list) => Text(
                    l10n.doneOfTotal(list.where((r) => r.isSubmitted).length, list.length),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  orElse: () => null,
                ),
              ),
              AsyncBody(
                value: runs,
                onRetry: () => ref.invalidate(myRunsTodayProvider),
                builder: (list) {
                  if (list.isEmpty) return EmptyState(icon: Icons.task_alt_rounded, message: l10n.noTasksToday);
                  final ordered = [...list.where((r) => r.isOpen), ...list.where((r) => !r.isOpen)];
                  return Column(
                    children: [
                      for (final r in ordered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(run: r, stats: stats[r.templateVersionId], featured: r == firstOpen),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (session.canLearn) ...[
              SectionTitle(l10n.myLearning),
              const _LearningSummary(),
              const SizedBox(height: 12),
              const MentorCard(),
            ],
            if (!session.canFill && !session.canLearn && session.hasAdminAccess)
              EmptyState(icon: Icons.desktop_windows_outlined, message: l10n.useAdminWeb),
          ],
        ),
      ),
    );
  }
}

class _LearningSummary extends ConsumerWidget {
  const _LearningSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final assignments = ref.watch(myAssignmentsProvider);
    final pathName = ref.watch(myPathNameProvider).value;
    return AsyncBody(
      value: assignments,
      onRetry: () => ref.invalidate(myAssignmentsProvider),
      builder: (list) {
        if (list.isEmpty) return EmptyState(icon: Icons.menu_book_outlined, message: l10n.noModulesYet);
        final path = list.where((a) => a.isPathModule).toList();
        final next = list.where((a) => !a.isCompleted).firstOrNull;
        return PathProgressCard(
          title: pathName ?? l10n.myPath,
          done: path.where((a) => a.isCompleted).length,
          total: path.length,
          next: next,
          onOpenNext: () => context.push(next == null ? '/learn' : '/module/${next.id}'),
        );
      },
    );
  }
}

/// "Your mentor: Made · Weekly check-in on Friday" (design screen 1).
class MentorCard extends ConsumerWidget {
  const MentorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final ms = ref.watch(myMentorshipsProvider).value?.where((m) => m.active).firstOrNull;
    if (ms == null) return const SizedBox.shrink();
    final day = session.profile.dayNumber ?? ms.traineeDay;
    return AppCard(
      onTap: () => context.push('/my-mentor/${ms.id}'),
      child: Row(
        children: [
          Avatar(ms.mentorName ?? '?', tone: Tone.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.yourMentor,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(ms.mentorName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(l10n.weeklyCheckinWithMentor,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Pill(l10n.dayN(day)),
        ],
      ),
    );
  }
}
