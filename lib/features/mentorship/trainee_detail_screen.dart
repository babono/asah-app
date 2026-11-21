import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../learning/learning_repository.dart';
import '../learning/widgets.dart';
import 'mentorship_repository.dart';

/// A trainee's path, quiz results and check-ins, for their mentor (M2, M3).
class TraineeDetailScreen extends ConsumerWidget {
  const TraineeDetailScreen({super.key, required this.mentorshipId});
  final String mentorshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ms = ref.watch(mentorshipProvider(mentorshipId));
    return Scaffold(
      appBar: AppBar(
        title: ms.maybeWhen(
          data: (m) => TwoLineTitle(m.traineeName ?? '', [m.traineePosition, l10n.dayN(m.traineeDay)].whereType<String>().join(' · ')),
          orElse: () => const SizedBox(),
        ),
      ),
      body: AsyncBody(
        value: ms,
        onRetry: () => ref.invalidate(mentorshipProvider(mentorshipId)),
        builder: (m) {
          final assignments =
              ref.watch(userAssignmentsProvider((userId: m.traineeId, positionId: m.traineePositionId)));
          final checkins = ref.watch(checkinsProvider(m.id));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userAssignmentsProvider((userId: m.traineeId, positionId: m.traineePositionId)));
              ref.invalidate(checkinsProvider(m.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionTitle(
                  l10n.weeklyCheckins,
                  trailing: m.active
                      ? TextButton(
                          onPressed: () => context.push('/mentor/checkin/${m.id}'),
                          child: Text(l10n.logCheckin),
                        )
                      : null,
                ),
                AsyncBody(
                  value: checkins,
                  builder: (list) => list.isEmpty
                      ? EmptyState(icon: Icons.event_note_outlined, message: l10n.noCheckinsYet)
                      : Column(children: [for (final c in list.take(4)) CheckinCard(checkin: c)]),
                ),
                const SizedBox(height: 24),
                SectionTitle(l10n.learningPath),
                AsyncBody(
                  value: assignments,
                  builder: (list) => Column(
                    children: [
                      for (final a in list)
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: AssignmentTile(assignment: a)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CheckinCard extends StatelessWidget {
  const CheckinCard({super.key, required this.checkin});
  final Checkin checkin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.weekOf(Fmt.day(checkin.weekOf)),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(checkin.feedback, style: const TextStyle(fontSize: 14, height: 1.45)),
            if (checkin.goals != null && checkin.goals!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.goals, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(checkin.goals!, style: const TextStyle(fontSize: 14, height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}
