import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../issues/issue_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../session/session_provider.dart';
import '../today/today_widgets.dart';
import 'dashboard_repository.dart';

const complianceTarget = 90.0;

/// Area manager's outlets: compliance, issues, training, last audit (S4).
class AreaScreen extends ConsumerWidget {
  const AreaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final outlets = session.isAreaManager ? session.outletsWith('audit.conduct') : session.outletsWith('dashboard.view');
    final key = (key: outlets.map((o) => o.id).join(','), days: 7);
    final data = ref.watch(dashboardProvider(key));
    final areaNames = outlets.map((o) => o.areaName).whereType<String>().toSet();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider(key)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            TabHeader(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              overline: '${areaNames.join(', ')} · ${l10n.outletsN(outlets.length)} · ${l10n.last7Days}',
              title: l10n.areaOverview,
              trailing: const NotificationBell(),
            ),
            const SyncBanner(),
            AsyncBody(
              value: data,
              onRetry: () => ref.invalidate(dashboardProvider(key)),
              builder: (d) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      StatTile(value: Fmt.pct(d.onTimePct), label: l10n.checklistsOnTime),
                      StatTile(value: '${d.openIssues}', label: l10n.openIssues),
                      StatTile(value: '${d.escalated}', label: l10n.lateEscalated, alert: d.escalated > 0),
                      StatTile(value: Fmt.pct(d.trainingPct), label: l10n.trainingOnSchedule),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(l10n.byOutlet),
                  for (final o in outlets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OutletCard(name: o.name, k: d.outlets[o.id]!, onTap: () => context.push('/outlet/${o.id}')),
                    ),
                  if (d.escalatedIssues.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionTitle(l10n.escalatedToYou),
                    for (final i in d.escalatedIssues)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: IssueCard(issue: i, outletName: session.outlets[i.outletId]?.name),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutletCard extends StatelessWidget {
  const _OutletCard({required this.name, required this.k, required this.onTap});
  final String name;
  final OutletKpis k;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = k.onTimePct;
    final below = pct != null && pct < complianceTarget;
    return AppCard(
      onTap: onTap,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              Text(Fmt.pct(pct), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: (pct ?? 0) / 100, color: below ? AppColors.belowTarget : AppColors.primary, height: 8),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Fact(l10n.openIssuesN(k.openIssues)),
              _Fact(l10n.lateN(k.lateIssues), danger: k.lateIssues > 0),
              _Fact(k.traineesBehind == 0 ? l10n.trainingOnScheduleShort : l10n.traineesBehindN(k.traineesBehind),
                  danger: k.traineesBehind > 0),
              _Fact(k.lastAudit == null
                  ? l10n.noAuditYet
                  : l10n.lastAuditDaysAgo(DateTime.now().difference(k.lastAudit!).inDays)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.text, {this.danger = false});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: danger ? FontWeight.w700 : FontWeight.w400,
          color: danger ? AppColors.danger : AppColors.textSecondary));
}
