import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/media_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../features/issues/issue_repository.dart';
import '../../features/session/people.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';

/// Issues across the person's scope (S1-S3), read-only in the web; the
/// outlet and area managers act on them from the phone.
class AdminIssuesPage extends ConsumerStatefulWidget {
  const AdminIssuesPage({super.key});

  @override
  ConsumerState<AdminIssuesPage> createState() => _AdminIssuesPageState();
}

class _AdminIssuesPageState extends ConsumerState<AdminIssuesPage> {
  IssueFilter _filter = IssueFilter.open;
  String? _outletId;
  String? _source;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final outlets = session.outletsWith('issue.view');
    final issues = ref.watch(issuesProvider(_filter));

    return AdminPage(
      breadcrumb: 'Standar',
      title: 'Issues and audits',
      actions: [
        SizedBox(
          width: 360,
          child: SegmentedButton<IssueFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: IssueFilter.open, label: Text('Open')),
              ButtonSegment(value: IssueFilter.checkFix, label: Text('Check fix')),
              ButtonSegment(value: IssueFilter.closed, label: Text('Closed')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: _outletId,
            decoration: const InputDecoration(labelText: 'Outlet'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All outlets')),
              for (final o in outlets) DropdownMenuItem(value: o.id, child: Text(o.name)),
            ],
            onChanged: (v) => setState(() => _outletId = v),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String?>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'Source'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any source')),
              DropdownMenuItem(value: 'checklist', child: Text('Checklists')),
              DropdownMenuItem(value: 'audit', child: Text('Audits')),
              DropdownMenuItem(value: 'manual', child: Text('By hand')),
            ],
            onChanged: (v) => setState(() => _source = v),
          ),
        ),
      ],
      children: [
        AdminSection(
          child: AdminAsync(
            value: issues,
            onRetry: () => ref.invalidate(issuesProvider(_filter)),
            builder: (all) {
              final list = all
                  .where((i) => (_outletId == null || i.outletId == _outletId) && (_source == null || i.source == _source))
                  .toList();
              if (list.isEmpty) return const Text('No issues.', style: TextStyle(color: AppColors.textSecondary));
              final people = ref.watch(peopleProvider(peopleKey(list.expand((i) => [i.assignedTo, i.raisedBy])))).value ?? {};
              return AdminTable(
                minWidth: 900,
                columns: const ['Issue', 'Outlet', 'Source', 'Severity', 'Owner', 'Deadline', 'Status'],
                rows: [
                  for (final i in list)
                    DataRow(
                      onSelectChanged: (_) => _openIssue(i),
                      cells: [
                        DataCell(Text(i.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(session.outlets[i.outletId]?.name ?? '')),
                        DataCell(Text(i.source == 'manual' ? 'By hand' : '${i.source} · ${i.runName ?? ''}')),
                        DataCell(Text(i.severity)),
                        DataCell(Text(i.assignedTo == null ? 'Not assigned' : people[i.assignedTo]?.name ?? '–',
                            style: TextStyle(color: i.assignedTo == null ? AppColors.danger : null))),
                        DataCell(Text(Fmt.dayTime(i.dueAt),
                            style: TextStyle(color: i.isLate ? AppColors.danger : null, fontWeight: i.isLate ? FontWeight.w700 : null))),
                        DataCell(i.escalatedAt != null && i.isOpen ? const Pill('Escalated', tone: Tone.danger, small: true) : StatusChip(i.status)),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _openIssue(Issue i) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i.title),
        content: SizedBox(width: 560, child: _IssueTimeline(issue: i)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _IssueTimeline extends ConsumerWidget {
  const _IssueTimeline({required this.issue});
  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(issueEventsProvider(issue.id));
    return AdminAsync(
      value: events,
      builder: (list) {
        final people = ref.watch(peopleProvider(peopleKey(list.map((e) => e.actorId)))).value ?? {};
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (issue.description != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(issue.description!)),
              for (final e in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.type[0].toUpperCase()}${e.type.substring(1)} · ${Fmt.dayTime(e.createdAt)}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text([people[e.actorId]?.name ?? (e.actorId == null ? 'System' : ''), if (e.note != null && e.type != 'assigned') e.note!]
                          .where((s) => s.isNotEmpty)
                          .join(' · ')),
                      if (e.mediaFileId != null) ...[const SizedBox(height: 6), MediaImage(e.mediaFileId!, height: 160)],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
