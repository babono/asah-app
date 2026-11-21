import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../issues/issue_repository.dart';
import '../learning/learning_repository.dart';
import '../learning/widgets.dart';
import '../mentorship/mentorship_repository.dart';
import '../session/models.dart';
import '../session/session_provider.dart';
import '../today/manager_today_screen.dart';
import 'team_screen.dart';

final _profileProvider = FutureProvider.family<Profile, String>((ref, id) async {
  final row = await ref.watch(supabaseProvider).from('profiles').select(Profile.select).eq('id', id).single();
  return Profile.fromJson(row);
});

/// One staff member, for their outlet manager: path progress, mentor, actions.
class StaffDetailScreen extends ConsumerWidget {
  const StaffDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final profile = ref.watch(_profileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: profile.maybeWhen(
          data: (p) => TwoLineTitle(p.fullName, [p.positionName, if (p.dayNumber != null) l10n.dayN(p.dayNumber!)].whereType<String>().join(' · ')),
          orElse: () => const SizedBox(),
        ),
      ),
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(_profileProvider(userId)),
        builder: (p) {
          final outletId = p.outletId;
          final assignments = ref.watch(userAssignmentsProvider((userId: p.id, positionId: p.positionId)));
          final mentorships = outletId == null ? <Mentorship>[] : (ref.watch(outletMentorshipsProvider(outletId)).value ?? []);
          final mentorship = mentorships.where((m) => m.traineeId == p.id).firstOrNull;
          final canManage = outletId != null && session.can('mentorship.manage', outletId: outletId);
          final canAssignTraining = outletId != null && session.can('training.assign', outletId: outletId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(l10n.mentor),
              AppCard(
                radius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Avatar(mentorship?.mentorName ?? '–', tone: Tone.accent, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mentorship == null
                                ? l10n.noMentorYet
                                : '${mentorship.mentorName} · ${l10n.sinceDate(Fmt.day(mentorship.startedAt))}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickMentor(context, ref, p),
                              child: Text(mentorship == null ? l10n.assignMentor : l10n.changeMentor),
                            ),
                          ),
                          if (mentorship != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _end(context, ref, mentorship),
                                child: Text(l10n.endMentorship),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                l10n.learningPath,
                trailing: canAssignTraining
                    ? TextButton(onPressed: () => _assignModule(context, ref, p), child: Text(l10n.assignModule))
                    : null,
              ),
              AsyncBody(
                value: assignments,
                builder: (list) => list.isEmpty
                    ? EmptyState(icon: Icons.menu_book_outlined, message: l10n.noModulesYet)
                    : Column(children: [
                        for (final a in list)
                          Padding(padding: const EdgeInsets.only(bottom: 10), child: AssignmentTile(assignment: a)),
                      ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickMentor(BuildContext context, WidgetRef ref, Profile trainee) async {
    final l10n = context.l10n;
    final staff = await ref.read(outletStaffProvider(trainee.outletId!).future);
    if (!context.mounted) return;
    final candidates = staff.where((s) => s.id != trainee.id).toList()
      ..sort((a, b) => (b.positionLevel ?? 0).compareTo(a.positionLevel ?? 0));
    final picked = await showModalBottomSheet<Profile>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(l10n.pickMentor, style: Theme.of(context).textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(l10n.mentorRulesNote, style: Theme.of(context).textTheme.bodySmall),
              ),
              for (final s in candidates)
                ListTile(
                  leading: Avatar(s.fullName, size: 36),
                  title: Text(s.fullName),
                  subtitle: Text([s.positionName, if (s.positionLevel != null) l10n.levelN(s.positionLevel!)].whereType<String>().join(' · ')),
                  onTap: () => Navigator.pop(ctx, s),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final ok = await runAction(context, () => ref.read(mentorshipRepositoryProvider).assignMentor(trainee.id, picked.id),
        success: l10n.mentorAssigned(picked.firstName));
    if (ok) ref.invalidate(outletMentorshipsProvider(trainee.outletId!));
  }

  Future<void> _end(BuildContext context, WidgetRef ref, Mentorship m) async {
    final l10n = context.l10n;
    final go = await confirmDialog(context, title: l10n.endMentorshipQ, message: l10n.endMentorshipBody, confirm: l10n.endMentorship);
    if (!go || !context.mounted) return;
    final ok = await runAction(context, () => ref.read(mentorshipRepositoryProvider).endMentorship(m.id),
        success: l10n.mentorshipEnded);
    if (ok) ref.invalidate(outletMentorshipsProvider(m.outletId));
  }

  Future<void> _assignModule(BuildContext context, WidgetRef ref, Profile p) async {
    final l10n = context.l10n;
    final modules = await ref.read(learningRepositoryProvider).publishedModules();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<({String moduleId, String versionId, String title, String category})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in modules)
                ListTile(title: Text(m.title), subtitle: Text(m.category), onTap: () => Navigator.pop(ctx, m)),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => ref.read(learningRepositoryProvider).assignModule(
          userId: p.id, moduleId: picked.moduleId, versionId: picked.versionId, source: 'manual'),
      success: l10n.moduleAssigned,
    );
    if (ok) {
      ref.invalidate(userAssignmentsProvider((userId: p.id, positionId: p.positionId)));
      if (p.outletId != null) ref.invalidate(teamSummariesProvider(p.outletId!));
    }
  }
}

/// Outlet manager spot-checks a sample of mentor sign-offs (M6).
class SignoffsScreen extends ConsumerWidget {
  const SignoffsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final outlet = session.managedOutlet!;
    final list = ref.watch(signoffsProvider(outlet.id));
    final staff = {for (final p in ref.watch(outletStaffProvider(outlet.id)).value ?? <Profile>[]) p.id: p};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mentorSignoffs)),
      body: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(signoffsProvider(outlet.id)),
        builder: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.spotCheckExplainer, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${staff[s.submission.userId]?.fullName ?? ''} · ${s.submission.moduleTitle ?? ''}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Pill(s.submission.status == 'passed' ? l10n.passed : l10n.redo,
                              tone: s.submission.status == 'passed' ? Tone.primary : Tone.danger, small: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scoredByOn(staff[s.submission.scoredBy]?.fullName ?? '', Fmt.dayTime(s.submission.scoredAt ?? s.submission.submittedAt)),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      if (s.checked)
                        Text(l10n.spotChecked, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))
                      else if (s.submission.scoredBy != session.profile.id)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push('/mentor/score/${s.submission.id}'),
                                child: Text(l10n.watch),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _check(context, ref, s.submission.id, false),
                                child: Text(l10n.disagree),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _check(context, ref, s.submission.id, true),
                                child: Text(l10n.agree),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _check(BuildContext context, WidgetRef ref, String submissionId, bool agrees) async {
    final l10n = context.l10n;
    String? note;
    if (!agrees) {
      note = await promptText(context, title: l10n.whatIsWrongWithSignoff);
      if (note == null) return;
    }
    if (!context.mounted) return;
    final outletId = ref.read(requireSessionProvider).managedOutlet!.id;
    final ok = await runAction(context,
        () => ref.read(mentorshipRepositoryProvider).spotCheck(submissionId, agrees: agrees, note: note),
        success: l10n.spotCheckSaved);
    if (ok) ref.invalidate(signoffsProvider(outletId));
  }
}
