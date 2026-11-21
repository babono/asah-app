import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../issues/issue_repository.dart';
import '../learning/learning_repository.dart';
import '../learning/models.dart';
import '../mentorship/mentorship_repository.dart';
import '../session/models.dart';
import '../session/session_provider.dart';
import '../today/manager_today_screen.dart';

final teamSummariesProvider = FutureProvider.family<Map<String, TrainingSummary>, String>((ref, outletId) async {
  final staff = await ref.watch(outletStaffProvider(outletId).future);
  return ref.watch(learningRepositoryProvider).summaries(staff.map((p) => p.id).toList());
});

final signoffsProvider = FutureProvider.family<List<({PracticalSubmission submission, bool checked})>, String>(
  (ref, outletId) async {
    final staff = await ref.watch(outletStaffProvider(outletId).future);
    return ref.watch(mentorshipRepositoryProvider).recentSignoffs(staff.map((p) => p.id).toList());
  },
);

/// Outlet manager's people: training progress, mentors, sign-off spot checks
/// (M1, M5, M6, T9).
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final outlet = session.managedOutlet;
    if (outlet == null) return Center(child: Text(l10n.noOutletAssigned));
    final staff = ref.watch(outletStaffProvider(outlet.id));
    final summaries = ref.watch(teamSummariesProvider(outlet.id)).value ?? {};
    final mentorships = ref.watch(outletMentorshipsProvider(outlet.id)).value ?? [];
    final signoffs = ref.watch(signoffsProvider(outlet.id)).value ?? [];
    final unchecked = signoffs.where((s) => !s.checked && s.submission.scoredBy != session.profile.id).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(outletStaffProvider(outlet.id));
          ref.invalidate(outletMentorshipsProvider(outlet.id));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            TabHeader(title: l10n.team, overline: outlet.name, padding: const EdgeInsets.fromLTRB(0, 24, 0, 16)),
            if (unchecked.isNotEmpty && session.can('practical.spot_check', outletId: outlet.id)) ...[
              AppCard(
                onTap: () => context.push('/team/signoffs'),
                color: AppColors.infoSoft,
                borderColor: AppColors.infoSoft,
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.signoffsToSpotCheck(unchecked.length),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.info)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.info),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AsyncBody(
              value: staff,
              onRetry: () => ref.invalidate(outletStaffProvider(outlet.id)),
              builder: (people) => Column(
                children: [
                  for (final p in people.where((p) => p.id != session.profile.id))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PersonTile(
                        person: p,
                        summary: summaries[p.id],
                        mentor: mentorships.where((m) => m.traineeId == p.id).firstOrNull?.mentorName,
                        trainees: mentorships.where((m) => m.mentorId == p.id).length,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, this.summary, this.mentor, this.trainees = 0});
  final Profile person;
  final TrainingSummary? summary;
  final String? mentor;
  final int trainees;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final behind = summary?.behind ?? false;
    return AppCard(
      onTap: () => context.push('/team/${person.id}'),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Avatar(person.fullName, tone: behind ? Tone.danger : Tone.primary, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  [
                    person.positionName,
                    if (mentor != null) l10n.mentorName(mentor!),
                    if (trainees > 0) l10n.mentorsN(trainees),
                  ].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (summary != null && summary!.assigned > 0) ...[
                  const SizedBox(height: 8),
                  ProgressBar(value: summary!.progress, color: behind ? AppColors.danger : AppColors.primary),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (summary != null && summary!.assigned > 0)
            Text(Fmt.pct(summary!.progress * 100),
                style: TextStyle(fontWeight: FontWeight.w700, color: behind ? AppColors.danger : AppColors.text)),
        ],
      ),
    );
  }
}
