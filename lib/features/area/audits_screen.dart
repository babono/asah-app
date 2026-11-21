import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../checklists/checklist_repository.dart';
import '../checklists/models.dart';
import '../session/session_provider.dart';

final myAuditsProvider = FutureProvider<List<ChecklistRun>>((ref) async {
  final s = await ref.watch(sessionProvider.future);
  if (s == null) return [];
  return ref.watch(checklistRepositoryProvider).myAudits(s.profile.id);
});

/// Area manager visit audits: start one at an outlet, see past ones (S4).
class AuditsScreen extends ConsumerWidget {
  const AuditsScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final session = ref.read(requireSessionProvider);
    final outlets = session.outletsWith('audit.conduct');
    final templates = await ref.read(checklistRepositoryProvider).auditTemplates();
    if (!context.mounted) return;
    if (templates.isEmpty) {
      showSnack(context, l10n.noAuditForms, error: true);
      return;
    }
    String? outletId = outlets.firstOrNull?.id;
    String? templateId = templates.first.id;
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.startAudit, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: outletId,
                  decoration: InputDecoration(labelText: l10n.outlet),
                  items: [for (final o in outlets) DropdownMenuItem(value: o.id, child: Text(o.name))],
                  onChanged: (v) => setState(() => outletId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: templateId,
                  decoration: InputDecoration(labelText: l10n.auditForm),
                  items: [for (final t in templates) DropdownMenuItem(value: t.id, child: Text(t.name))],
                  onChanged: (v) => setState(() => templateId = v),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.startAudit)),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || outletId == null || templateId == null || !context.mounted) return;
    String? runId;
    final ok = await runAction(context, () async {
      runId = await ref.read(checklistRepositoryProvider).startAudit(templateId!, outletId!);
    });
    if (ok && runId != null && context.mounted) {
      ref.invalidate(myAuditsProvider);
      ref.invalidate(myRunsTodayProvider);
      context.push('/checklist/$runId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final audits = ref.watch(myAuditsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _start(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.startAudit),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAuditsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            children: [
              TabHeader(title: l10n.visitAudits, overline: l10n.auditsExplainer, padding: const EdgeInsets.fromLTRB(0, 24, 0, 16)),
              AsyncBody(
                value: audits,
                onRetry: () => ref.invalidate(myAuditsProvider),
                builder: (list) => list.isEmpty
                    ? EmptyState(icon: Icons.assignment_turned_in_outlined, message: l10n.noAuditsYet)
                    : Column(
                        children: [
                          for (final r in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                onTap: () => context.push('/checklist/${r.id}'),
                                radius: 16,
                                child: Row(
                                  children: [
                                    IconTile(Icons.assignment_turned_in_outlined,
                                        tone: r.isSubmitted ? Tone.primary : Tone.warning, size: 40),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${session.outlets[r.outletId]?.name ?? ''} · ${r.templateName}',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                          Text(
                                            r.isSubmitted
                                                ? l10n.auditScore(Fmt.pct(r.compliancePct), Fmt.day(r.submittedAt!))
                                                : l10n.inProgressSince(Fmt.day(r.shiftDate)),
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (r.isSubmitted && (r.failedCount ?? 0) > 0)
                                      Pill(l10n.findingsN(r.failedCount!), tone: Tone.danger, small: true),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
