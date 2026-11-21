import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/camera.dart';
import '../../core/media/media_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../learning/learning_repository.dart';
import '../session/models.dart';
import '../session/people.dart';
import '../session/session_provider.dart';
import 'issue_repository.dart';
import 'issue_widgets.dart';

final _responsePhotosProvider = FutureProvider.family<List<String>, String>(
  (ref, responseId) => ref.watch(issueRepositoryProvider).responsePhotos(responseId),
);

/// Issue detail with owner, deadline, timeline and the next action
/// (S1, S2, S3, R7; design screen 7).
class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});
  final String issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final issue = ref.watch(issueProvider(issueId));

    return Scaffold(
      appBar: AppBar(
        title: issue.maybeWhen(
          data: (i) => TwoLineTitle(i.title, [l10n.issue, session.outlets[i.outletId]?.name].whereType<String>().join(' · ')),
          orElse: () => const SizedBox(),
        ),
        actions: [
          issue.maybeWhen(
            data: (i) => Padding(padding: const EdgeInsets.only(right: 12), child: severityPill(context, i.severity)),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: AsyncBody(
        value: issue,
        onRetry: () => ref.invalidate(issueProvider(issueId)),
        builder: (i) => RefreshIndicator(
          onRefresh: () async => invalidateIssues(ref, issueId: issueId),
          child: _IssueBody(issue: i, session: session),
        ),
      ),
      bottomNavigationBar: issue.maybeWhen(
        data: (i) => _IssueActions(issue: i, session: session),
        orElse: () => null,
      ),
    );
  }
}

class _IssueBody extends ConsumerWidget {
  const _IssueBody({required this.issue, required this.session});
  final Issue issue;
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final i = issue;
    final events = ref.watch(issueEventsProvider(i.id));
    final ids = [i.raisedBy, i.assignedTo, i.fixedBy, i.closedBy, ...?events.value?.map((e) => e.actorId)];
    final people = ref.watch(peopleProvider(peopleKey(ids))).value ?? {};
    String name(String? id) => id == null ? l10n.system : (people[id]?.name ?? l10n.someone);

    final checklistPhotos = i.responseId == null ? null : ref.watch(_responsePhotosProvider(i.responseId!)).value;
    final createdPhoto = events.value?.where((e) => e.type == 'created' && e.mediaFileId != null).firstOrNull?.mediaFileId;
    final photo = checklistPhotos?.firstOrNull ?? createdPhoto;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (photo != null) ...[
          MediaImage(photo, caption: '${Fmt.time(i.createdAt)} · ${session.outlets[i.outletId]?.name ?? ''} · ${l10n.inAppCamera}'),
          const SizedBox(height: 16),
        ],
        if (i.description != null && i.description!.isNotEmpty) ...[
          Text(i.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
        ],
        GroupedCard(children: [
          KeyValueRow(
            label: l10n.source,
            value: [issueSourceLabel(context, i), if (i.raisedBy != null) name(i.raisedBy)].join(' · '),
          ),
          KeyValueRow(
            label: l10n.deadline,
            value: Fmt.dayTime(i.dueAt),
            valueColor: i.isLate ? AppColors.danger : null,
            bold: i.isLate,
          ),
          KeyValueRow(
            label: l10n.owner,
            value: i.assignedTo == null ? l10n.notAssigned : (people[i.assignedTo]?.label ?? l10n.someone),
            valueColor: i.assignedTo == null ? AppColors.danger : null,
            bold: i.assignedTo == null,
          ),
          KeyValueRow(
            label: l10n.ifLate,
            value: i.escalatedAt != null ? l10n.escalatedAt(Fmt.dayTime(i.escalatedAt!)) : l10n.escalatesToArea,
            valueColor: i.escalatedAt != null ? AppColors.danger : null,
          ),
        ]),
        const SizedBox(height: 24),
        SectionTitle(l10n.progress),
        AsyncBody(
          value: events,
          builder: (list) => _Timeline(issue: i, events: list, name: name),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.issue, required this.events, required this.name});
  final Issue issue;
  final List<IssueEvent> events;
  final String Function(String?) name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <_Step>[
      for (final e in events)
        _Step(
          done: true,
          danger: e.type == 'escalated' || e.type == 'reopened',
          title: switch (e.type) {
            'created' => l10n.eventRaised,
            'assigned' => l10n.eventAssigned,
            'fixed' => l10n.eventFixed,
            'accepted' => l10n.eventAccepted,
            'reopened' => l10n.eventReopened,
            'escalated' => l10n.eventEscalated,
            _ => l10n.eventComment,
          },
          subtitle: [
            Fmt.dayTime(e.createdAt),
            if (e.type == 'assigned' && e.note != null) name(e.note) else if (e.type != 'escalated') name(e.actorId),
            if (e.type != 'assigned' && e.note != null && e.note!.isNotEmpty) '"${e.note}"',
          ].join(' · '),
          mediaId: e.type == 'created' ? null : e.mediaFileId,
        ),
    ];
    // What happens next, in grey.
    if (issue.isOpen && issue.assignedTo == null) {
      rows.add(_Step(done: false, danger: true, title: l10n.eventAssigned, subtitle: l10n.waitingForManager));
    }
    if (issue.isOpen) rows.add(_Step(done: false, title: l10n.fixedWithProof, subtitle: l10n.byTheOwner));
    if (!issue.isClosed) rows.add(_Step(done: false, title: l10n.acceptedOrReopened, subtitle: l10n.notTheFixer));

    return Column(
      children: [
        for (var k = 0; k < rows.length; k++) _StepRow(step: rows[k], last: k == rows.length - 1),
      ],
    );
  }
}

class _Step {
  const _Step({required this.done, required this.title, required this.subtitle, this.danger = false, this.mediaId});
  final bool done;
  final bool danger;
  final String title;
  final String subtitle;
  final String? mediaId;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last});
  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final dotColor = step.danger ? AppColors.danger : AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? dotColor : (step.danger ? AppColors.dangerSoft : null),
                  border: step.done ? null : Border.all(color: step.danger ? AppColors.danger : AppColors.dashed, width: 2),
                ),
              ),
              if (!last) Expanded(child: Container(width: 2, color: AppColors.inputBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: step.done ? AppColors.text : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(step.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  if (step.mediaId != null) ...[
                    const SizedBox(height: 8),
                    MediaImage(step.mediaId!, height: 140),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one or two actions this person can take now. The RPCs enforce the
/// same rules on the server (R6, R7).
class _IssueActions extends ConsumerStatefulWidget {
  const _IssueActions({required this.issue, required this.session});
  final Issue issue;
  final Session session;

  @override
  ConsumerState<_IssueActions> createState() => _IssueActionsState();
}

class _IssueActionsState extends ConsumerState<_IssueActions> {
  bool _busy = false;

  Issue get i => widget.issue;
  Session get s => widget.session;
  String get me => s.profile.id;

  Future<void> _do(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    final ok = await runAction(context, action, success: success);
    if (ok) invalidateIssues(ref, issueId: i.id, outletId: i.outletId);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _assign() async {
    final l10n = context.l10n;
    final staff = await ref.read(outletStaffProvider(i.outletId).future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Profile>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.assignTo, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final p in staff)
              ListTile(
                leading: Avatar(p.fullName, size: 36),
                title: Text(p.fullName),
                subtitle: p.positionName == null ? null : Text(p.positionName!),
                selected: p.id == i.assignedTo,
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _do(() => ref.read(issueRepositoryProvider).assign(i.id, picked.id), l10n.assignedNotified(picked.firstName));
  }

  Future<void> _fix() async {
    final l10n = context.l10n;
    final proof = await capturePhoto();
    if (proof == null || !mounted) return;
    final note = await promptText(context, title: l10n.whatDidYouFix, hint: l10n.optionalNote, required: false);
    if (!mounted) return;
    await _do(() => ref.read(issueRepositoryProvider).fix(i, note: note, proof: proof), l10n.markedFixed);
  }

  Future<void> _accept() =>
      _do(() => ref.read(issueRepositoryProvider).verify(i.id, accept: true), context.l10n.issueClosedMsg);

  Future<void> _reopen() async {
    final l10n = context.l10n;
    final reason = await promptText(context, title: l10n.whyReopen, hint: l10n.reopenHint);
    if (reason == null) return;
    await _do(() => ref.read(issueRepositoryProvider).verify(i.id, accept: false, note: reason), l10n.issueReopenedMsg);
  }

  Future<void> _comment() async {
    final l10n = context.l10n;
    final note = await promptText(context, title: l10n.addComment);
    if (note == null) return;
    await _do(() => ref.read(issueRepositoryProvider).comment(i.id, note), l10n.commentAdded);
  }

  Future<void> _refresher() async {
    final l10n = context.l10n;
    final person = i.raisedBy;
    if (person == null) return;
    final modules = await ref.read(learningRepositoryProvider).publishedModules();
    if (!mounted) return;
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(l10n.assignRefresher, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final m in modules)
                ListTile(title: Text(m.title), subtitle: Text(m.category), onTap: () => Navigator.pop(ctx, m)),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await _do(
      () => ref.read(learningRepositoryProvider).assignModule(userId: person, moduleId: picked.moduleId, versionId: picked.versionId),
      l10n.refresherAssigned,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canAssign = s.can('issue.assign', outletId: i.outletId);
    final canFix = i.isOpen && ((i.assignedTo == me && s.can('issue.fix', outletId: i.outletId)) || canAssign);
    final canVerify = i.isFixed && s.can('issue.verify', outletId: i.outletId) && i.fixedBy != me;
    final canRefresher = i.source != 'manual' && i.raisedBy != null && s.can('training.assign', outletId: i.outletId);

    final buttons = <Widget>[];
    if (canVerify) {
      buttons.addAll([
        Expanded(child: OutlinedButton(onPressed: _busy ? null : _reopen, child: Text(l10n.reopen))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: _busy ? null : _accept, child: Text(l10n.acceptFix))),
      ]);
    } else if (i.isOpen && canAssign && i.assignedTo == null) {
      buttons.add(Expanded(child: FilledButton(onPressed: _busy ? null : _assign, child: Text(l10n.assignOwner))));
    } else if (canFix) {
      if (canAssign) {
        buttons.addAll([
          Expanded(child: OutlinedButton(onPressed: _busy ? null : _assign, child: Text(l10n.changeOwner))),
          const SizedBox(width: 10),
        ]);
      }
      buttons.add(Expanded(
        child: FilledButton.icon(
          onPressed: _busy ? null : _fix,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.markFixed),
        ),
      ));
    } else if (i.isFixed && i.fixedBy == me) {
      return BottomBar(child: Text(l10n.waitingForSomeoneToCheck, textAlign: TextAlign.center));
    }

    final secondary = <Widget>[
      if (!i.isClosed) TextButton.icon(onPressed: _busy ? null : _comment, icon: const Icon(Icons.chat_bubble_outline, size: 18), label: Text(l10n.comment)),
      if (canRefresher) TextButton.icon(onPressed: _busy ? null : _refresher, icon: const Icon(Icons.school_outlined, size: 18), label: Text(l10n.refresher)),
    ];
    if (buttons.isEmpty && secondary.isEmpty) return const SizedBox.shrink();

    return BottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondary.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: secondary),
          if (buttons.isNotEmpty) Row(children: buttons),
        ],
      ),
    );
  }
}
