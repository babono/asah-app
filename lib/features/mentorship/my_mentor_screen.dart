import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import 'mentorship_repository.dart';
import 'trainee_detail_screen.dart';

/// Trainee's view of their mentor and the weekly check-ins (M3).
class MyMentorScreen extends ConsumerWidget {
  const MyMentorScreen({super.key, required this.mentorshipId});
  final String mentorshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ms = ref.watch(mentorshipProvider(mentorshipId));
    final checkins = ref.watch(checkinsProvider(mentorshipId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourMentor)),
      body: AsyncBody(
        value: ms,
        onRetry: () => ref.invalidate(mentorshipProvider(mentorshipId)),
        builder: (m) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Row(
                children: [
                  Avatar(m.mentorName ?? '?', tone: Tone.accent, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.mentorName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(l10n.mentorSince(Fmt.fullDate(m.startedAt)),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.mentorHelpNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            SectionTitle(l10n.weeklyCheckins),
            AsyncBody(
              value: checkins,
              builder: (list) => list.isEmpty
                  ? EmptyState(icon: Icons.event_note_outlined, message: l10n.noCheckinsYetTrainee)
                  : Column(children: [for (final c in list) CheckinCard(checkin: c)]),
            ),
          ],
        ),
      ),
    );
  }
}
