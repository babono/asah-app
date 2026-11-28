import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../session/session_provider.dart';
import 'formal_training_repository.dart';
import 'mentorship_repository.dart';

/// Status label and tone, from the viewer's side ("Waiting for you").
({String label, Tone tone}) formalTrainingStatus(BuildContext context, FormalTraining t, String uid) {
  final l10n = context.l10n;
  if (t.expired) return (label: l10n.ftExpired, tone: Tone.neutral);
  return switch (t.status) {
    FormalTrainingStatus.requested =>
      t.requestedBy == uid || !t.isParty(uid)
          ? (
              label: l10n.ftWaitingFor(t.requestedBy == t.mentorId ? t.traineeName ?? '' : t.mentorName ?? ''),
              tone: Tone.info,
            )
          : (label: l10n.ftWaitingForYou, tone: Tone.warning),
    FormalTrainingStatus.approved =>
      t.isPast ? (label: l10n.ftHeld, tone: Tone.neutral) : (label: l10n.ftScheduled, tone: Tone.primary),
    FormalTrainingStatus.declined => (label: l10n.ftDeclined, tone: Tone.danger),
    FormalTrainingStatus.cancelled => (label: l10n.ftCancelled, tone: Tone.neutral),
  };
}

String _when(FormalTraining t) => '${Fmt.weekday(t.scheduledAt)}, ${Fmt.dayTime(t.scheduledAt)}';

/// One session: when, topic, who, status. Opens the detail screen.
class FormalTrainingTile extends ConsumerWidget {
  const FormalTrainingTile({super.key, required this.training, this.showPeople = false});
  final FormalTraining training;

  /// Show "Mentor with Trainee" (managers' lists) instead of the topic line only.
  final bool showPeople;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uid = ref.watch(requireSessionProvider).profile.id;
    final t = training;
    final status = formalTrainingStatus(context, t, uid);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => context.push('/formal-training/${t.id}'),
        child: Row(
          children: [
            IconTile(Icons.event_available_outlined, tone: status.tone, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.topic, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _when(t),
                      l10n.minutesShort(t.durationMinutes),
                      if (showPeople) l10n.mentorWithTrainee(t.mentorName ?? '', t.traineeName ?? ''),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(status.label, tone: status.tone, small: true),
          ],
        ),
      ),
    );
  }
}

/// "Formal trainings" section on the mentor's trainee page and the trainee's
/// mentor page, with a Request button while the mentorship is active.
class FormalTrainingSection extends ConsumerWidget {
  const FormalTrainingSection({super.key, required this.mentorship, this.limit = 5});
  final Mentorship mentorship;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(formalTrainingsProvider(mentorship.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l10n.formalTrainings,
          trailing: mentorship.active
              ? TextButton(
                  onPressed: () => context.push('/formal-training/new/${mentorship.id}'),
                  child: Text(l10n.requestShort),
                )
              : null,
        ),
        AsyncBody(
          value: list,
          onRetry: () => ref.invalidate(formalTrainingsProvider(mentorship.id)),
          builder: (items) => items.isEmpty
              ? EmptyState(icon: Icons.event_available_outlined, message: l10n.noFormalTrainings)
              : Column(children: [for (final t in items.take(limit)) FormalTrainingTile(training: t)]),
        ),
      ],
    );
  }
}

/// Mentor or trainee proposes a date and time for a 30-minute session.
class RequestFormalTrainingScreen extends ConsumerStatefulWidget {
  const RequestFormalTrainingScreen({super.key, required this.mentorshipId});
  final String mentorshipId;

  @override
  ConsumerState<RequestFormalTrainingScreen> createState() => _RequestFormalTrainingScreenState();
}

class _RequestFormalTrainingScreenState extends ConsumerState<RequestFormalTrainingScreen> {
  static const _duration = 30;
  final _topic = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default: tomorrow at 10:00, a quiet time before lunch service.
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _time = const TimeOfDay(hour: 10, minute: 0);
    _topic.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _topic.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _send(String otherName) async {
    final l10n = context.l10n;
    if (_topic.text.trim().isEmpty) return;
    if (!_start.isAfter(DateTime.now())) {
      showSnack(context, l10n.pickFutureTime, error: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await runAction(context, () async {
      await ref
          .read(formalTrainingRepositoryProvider)
          .request(
            widget.mentorshipId,
            scheduledAt: _start,
            topic: _topic.text,
            note: _note.text,
            durationMinutes: _duration,
          );
      invalidateFormalTrainings(ref);
    }, success: l10n.formalTrainingRequestSent(otherName));
    if (mounted) setState(() => _saving = false);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = ref.watch(requireSessionProvider).profile.id;
    final ms = ref.watch(mentorshipProvider(widget.mentorshipId)).value;
    final otherName = (ms == null ? null : (uid == ms.mentorId ? ms.traineeName : ms.mentorName)) ?? '';
    final inPast = !_start.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: TwoLineTitle(l10n.requestFormalTraining, otherName.isEmpty ? null : otherName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoBanner(icon: Icons.groups_outlined, text: l10n.formalTrainingIntro(otherName)),
          const SizedBox(height: 16),
          TextField(
            controller: _topic,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.formalTrainingTopic, hintText: l10n.formalTrainingTopicHint),
          ),
          const SizedBox(height: 16),
          GroupedCard(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.pickDate),
                trailing: Text(
                  '${Fmt.weekday(_date)}, ${Fmt.day(_date)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: _pickDate,
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l10n.pickTime),
                trailing: Text(
                  '${Fmt.time(_start)} · ${l10n.minutesShort(_duration)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: inPast ? AppColors.danger : null),
                ),
                onTap: _pickTime,
              ),
            ],
          ),
          if (inPast) ...[
            const SizedBox(height: 8),
            Text(l10n.pickFutureTime, style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.formalTrainingNote, alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Text(l10n.managersCanJoin, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton(
          onPressed: _saving || _topic.text.trim().isEmpty || inPast ? null : () => _send(otherName),
          child: Text(l10n.sendRequest),
        ),
      ),
    );
  }
}

/// One session. The other side approves or declines a request; either side
/// can cancel an open one. Managers see it read-only.
class FormalTrainingDetailScreen extends ConsumerStatefulWidget {
  const FormalTrainingDetailScreen({super.key, required this.trainingId});
  final String trainingId;

  @override
  ConsumerState<FormalTrainingDetailScreen> createState() => _FormalTrainingDetailScreenState();
}

class _FormalTrainingDetailScreenState extends ConsumerState<FormalTrainingDetailScreen> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runAction(context, () async {
      await action();
      invalidateFormalTrainings(ref);
    }, success: success);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _approve(FormalTraining t) => _act(
    () => ref.read(formalTrainingRepositoryProvider).respond(t.id, approve: true),
    context.l10n.formalTrainingApproved,
  );

  Future<void> _decline(FormalTraining t) async {
    final l10n = context.l10n;
    final reason = await promptText(
      context,
      title: l10n.declineFormalTraining,
      hint: l10n.reasonOptional,
      required: false,
    );
    if (reason == null || !mounted) return;
    await _act(
      () => ref.read(formalTrainingRepositoryProvider).respond(t.id, approve: false, note: reason),
      l10n.formalTrainingDeclined,
    );
  }

  Future<void> _cancel(FormalTraining t, String uid) async {
    final l10n = context.l10n;
    final reason = await promptText(
      context,
      title: l10n.cancelFormalTrainingConfirm(t.otherName(uid) ?? ''),
      hint: l10n.reasonOptional,
      required: false,
    );
    if (reason == null || !mounted) return;
    await _act(
      () => ref.read(formalTrainingRepositoryProvider).cancel(t.id, reason: reason),
      l10n.formalTrainingCancelled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = ref.watch(requireSessionProvider).profile.id;
    final value = ref.watch(formalTrainingProvider(widget.trainingId));
    final t = value.value;

    Widget? bottom;
    if (t != null && t.canRespond(uid)) {
      bottom = BottomBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: _busy ? null : () => _decline(t), child: Text(l10n.decline)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: _busy ? null : () => _approve(t), child: Text(l10n.approve)),
            ),
          ],
        ),
      );
    } else if (t != null && t.canCancel(uid)) {
      bottom = BottomBar(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: _busy ? null : () => _cancel(t, uid),
          child: Text(l10n.cancelFormalTraining),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.formalTraining)),
      bottomNavigationBar: bottom,
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(formalTrainingProvider(widget.trainingId)),
        builder: (t) {
          final status = formalTrainingStatus(context, t, uid);
          String nameOf(String id) =>
              id == uid ? l10n.youLabel : (id == t.mentorId ? t.mentorName : t.traineeName) ?? '';
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(formalTrainingProvider(widget.trainingId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (t.canRespond(uid)) ...[
                  Text(
                    l10n.formalTrainingRequestTitle(nameOf(t.requestedBy)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                ],
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Pill(status.label, tone: status.tone),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Fact(icon: Icons.calendar_today_outlined, text: _when(t)),
                      _Fact(
                        icon: Icons.schedule_outlined,
                        text:
                            '${Fmt.time(t.scheduledAt)}–${Fmt.time(t.endsAt)} · ${l10n.minutesShort(t.durationMinutes)}',
                      ),
                      _Fact(icon: Icons.school_outlined, text: '${l10n.mentor}: ${nameOf(t.mentorId)}'),
                      _Fact(icon: Icons.person_outline, text: t.traineeName ?? ''),
                      _Fact(icon: Icons.send_outlined, text: l10n.requestedByName(nameOf(t.requestedBy))),
                    ],
                  ),
                ),
                if ((t.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionTitle(l10n.formalTrainingNote),
                  Text(t.note!, style: const TextStyle(fontSize: 14, height: 1.45)),
                ],
                if ((t.responseNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionTitle(l10n.reply),
                  Text(t.responseNote!, style: const TextStyle(fontSize: 14, height: 1.45)),
                ],
                const SizedBox(height: 16),
                if (t.isOpen && !t.isPast)
                  InfoBanner(
                    icon: Icons.groups_outlined,
                    text: t.status == FormalTrainingStatus.approved
                        ? l10n.managersCanJoinScheduled
                        : l10n.managersCanJoin,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textStrong)),
          ),
        ],
      ),
    );
  }
}
