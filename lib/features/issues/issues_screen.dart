import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../session/people.dart';
import '../session/session_provider.dart';
import 'issue_repository.dart';
import 'issue_widgets.dart';

/// Issues the person can see: their own for staff, the outlet or area for
/// managers (S1).
class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  IssueFilter _filter = IssueFilter.open;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final issues = ref.watch(issuesProvider(_filter));
    final canRaise = session.hasAny('issue.create');

    return Scaffold(
      floatingActionButton: canRaise
          ? FloatingActionButton.extended(
              heroTag: 'raise-issue', // tabs share one screen: tags must differ
              onPressed: () => context.push('/issues/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.raiseIssue),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(issuesProvider(_filter)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            children: [
              TabHeader(
                title: l10n.issues,
                overline: session.isAreaManager
                    ? l10n.yourArea
                    : session.isOutletManager
                        ? session.managedOutlet?.name
                        : l10n.raisedByOrAssignedToYou,
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              ),
              SegmentedButton<IssueFilter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: IssueFilter.open, label: Text(l10n.open)),
                  ButtonSegment(value: IssueFilter.checkFix, label: Text(l10n.checkFix)),
                  ButtonSegment(value: IssueFilter.closed, label: Text(l10n.closed)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: 16),
              AsyncBody(
                value: issues,
                onRetry: () => ref.invalidate(issuesProvider(_filter)),
                builder: (list) {
                  if (list.isEmpty) {
                    return EmptyState(icon: Icons.check_circle_outline, message: l10n.noIssuesHere);
                  }
                  final names = ref.watch(peopleProvider(peopleKey(list.map((i) => i.assignedTo)))).value ?? {};
                  final multiOutlet = list.map((i) => i.outletId).toSet().length > 1;
                  return Column(
                    children: [
                      for (final i in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IssueCard(
                            issue: i,
                            outletName: multiOutlet ? session.outlets[i.outletId]?.name : null,
                            ownerName: names[i.assignedTo]?.name,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
