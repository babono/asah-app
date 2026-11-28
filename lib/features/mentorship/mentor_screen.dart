import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../learning/learning_repository.dart';
import '../learning/models.dart';
import '../session/session_provider.dart';
import 'formal_training_repository.dart';
import 'mentorship_repository.dart';

class MentorDashboard {
  const MentorDashboard(this.trainees, this.summaries, this.pending, this.lastCheckins);
  final List<Mentorship> trainees;
  final Map<String, TrainingSummary> summaries;
  final List<PracticalSubmission> pending;
  final Map<String, DateTime> lastCheckins;
}

final mentorDashboardProvider = FutureProvider<MentorDashboard>((ref) async {
  final trainees = await ref.watch(myTraineesProvider.future);
  final ids = trainees.map((t) => t.traineeId).toList();
  final repo = ref.watch(mentorshipRepositoryProvider);
  final results = await Future.wait([
    ref.watch(learningRepositoryProvider).summaries(ids),
    repo.pendingPracticals(ids),
    repo.lastCheckins(trainees.map((t) => t.id).toList()),
  ]);
  return MentorDashboard(
    trainees,
    results[0] as Map<String, TrainingSummary>,
    results[1] as List<PracticalSubmission>,
    results[2] as Map<String, DateTime>,
  );
});

/// Mentor tab: trainees, practical tests to score, check-ins due (M2, M3;
/// design screen 4).
class MentorScreen extends ConsumerWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final dash = ref.watch(mentorDashboardProvider);
    final awaiting = ref.watch(formalTrainingsAwaitingMeProvider).value ?? [];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myTraineesProvider);
          ref.invalidate(myMentorRatingProvider);
          ref.invalidate(formalTrainingsAwaitingMeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            TabHeader(
              overline: [session.profile.firstName, l10n.mentor, session.outlet?.name].whereType<String>().join(' · '),
              title: l10n.myTrainees,
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
            ),
            AsyncBody(
              value: dash,
              onRetry: () => ref.invalidate(myTraineesProvider),
              builder: (d) {
                final weekStart = Fmt.weekStart(DateTime.now());
                final checkinsDue =
                    d.trainees.where((t) => (d.lastCheckins[t.id]?.isBefore(weekStart) ?? true)).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (d.trainees.isEmpty) EmptyState(icon: Icons.people_outline, message: l10n.noTraineesYet),
                    for (final t in d.trainees)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TraineeCard(mentorship: t, summary: d.summaries[t.traineeId]),
                      ),
                    if (d.pending.isNotEmpty || checkinsDue.isNotEmpty || awaiting.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SectionTitle(l10n.toDo),
                      for (final t in awaiting)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TodoTile(
                            icon: Icons.event_available_outlined,
                            tone: Tone.warning,
                            title: l10n.formalTrainingRequestTitle(t.traineeName ?? ''),
                            subtitle: '${t.topic} · ${Fmt.dayTime(t.scheduledAt)}',
                            onTap: () => context.push('/formal-training/${t.id}'),
                          ),
                        ),
                      for (final p in d.pending)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TodoTile(
                            icon: Icons.videocam_outlined,
                            tone: Tone.warning,
                            title: l10n.scorePracticalTest,
                            subtitle: [
                              d.trainees.where((t) => t.traineeId == p.userId).firstOrNull?.traineeName,
                              p.moduleTitle,
                            ].whereType<String>().join(' · '),
                            onTap: () => context.push('/mentor/score/${p.id}'),
                          ),
                        ),
                      for (final t in checkinsDue)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TodoTile(
                            icon: Icons.event_note_outlined,
                            tone: Tone.info,
                            title: l10n.weeklyCheckinDue,
                            subtitle: '${t.traineeName ?? ''} · ${l10n.thisWeek}',
                            onTap: () => context.push('/mentor/checkin/${t.id}'),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _MyRatingNote(),
          ],
        ),
      ),
    );
  }
}

class _TraineeCard extends StatelessWidget {
  const _TraineeCard({required this.mentorship, required this.summary});
  final Mentorship mentorship;
  final TrainingSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = summary;
    final behind = s?.behind ?? false;
    return AppCard(
      onTap: () => context.push('/mentor/trainee/${mentorship.id}'),
      borderColor: behind ? AppColors.dangerBorder : AppColors.border,
      borderWidth: behind ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(mentorship.traineeName ?? '?', tone: behind ? Tone.danger : Tone.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentorship.traineeName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      [mentorship.traineePosition, l10n.dayN(mentorship.traineeDay)].whereType<String>().join(' · '),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Pill(behind ? l10n.behind : l10n.onTrack, tone: behind ? Tone.danger : Tone.primary),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: s?.progress ?? 0, color: behind ? AppColors.danger : AppColors.primary),
          const SizedBox(height: 8),
          if (s?.failedQuizTwice ?? false)
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Text(l10n.failedQuizTwice,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.pathPct(((s?.progress ?? 0) * 100).round()),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  s?.overdue != null && s!.overdue > 0
                      ? l10n.modulesOverdue(s.overdue)
                      : l10n.lastQuiz(Fmt.pct(s?.lastQuizPct)),
                  style: TextStyle(
                      fontSize: 13, color: (s?.overdue ?? 0) > 0 ? AppColors.danger : AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.icon, required this.tone, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Tone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconTile(icon, tone: tone, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.icon),
        ],
      ),
    );
  }
}

class _MyRatingNote extends ConsumerWidget {
  const _MyRatingNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rating = ref.watch(myMentorRatingProvider).value;
    final text = rating?.average != null
        ? l10n.myRatingAverage(rating!.average!.toStringAsFixed(1), rating.ratings)
        : l10n.myRatingHidden(rating?.shownAfter ?? 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.star_outline_rounded, color: AppColors.textStrong),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textStrong))),
        ],
      ),
    );
  }
}
