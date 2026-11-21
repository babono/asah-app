import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import 'mentor_screen.dart';
import 'mentorship_repository.dart';

/// Weekly check-in: feedback and goals the trainee can read (M3).
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, required this.mentorshipId});
  final String mentorshipId;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _feedback = TextEditingController();
  final _goals = TextEditingController();
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _feedback.dispose();
    _goals.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_feedback.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final ok = await runAction(context, () async {
      await ref.read(mentorshipRepositoryProvider).saveCheckin(
            widget.mentorshipId,
            feedback: _feedback.text.trim(),
            goals: _goals.text.trim().isEmpty ? null : _goals.text.trim(),
          );
      ref.invalidate(checkinsProvider(widget.mentorshipId));
      ref.invalidate(mentorDashboardProvider);
    }, success: context.l10n.checkinSaved);
    if (mounted) setState(() => _saving = false);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ms = ref.watch(mentorshipProvider(widget.mentorshipId)).value;
    final thisWeek = Fmt.weekStart(DateTime.now());
    final existing = ref.watch(checkinsProvider(widget.mentorshipId)).value?.where((c) => !c.weekOf.isBefore(thisWeek)).firstOrNull;
    if (existing != null && !_prefilled) {
      _prefilled = true;
      _feedback.text = existing.feedback;
      _goals.text = existing.goals ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: TwoLineTitle(l10n.weeklyCheckin, ms?.traineeName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.weekOf(Fmt.day(thisWeek)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _feedback,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(labelText: l10n.feedback, hintText: l10n.feedbackHint, alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goals,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.goalsNextWeek, alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Text(l10n.traineeSeesCheckin, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.saveCheckin)),
      ),
    );
  }
}
