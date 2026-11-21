import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../features/area/dashboard_repository.dart';
import '../../features/session/models.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/download.dart';

const _target = 90.0;

/// Outlet, area and group dashboards (S4) with weekly trend and CSV export (S5).
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _days = 7;
  String? _areaId; // null = everything in scope

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final inScope = session.outletsWith('dashboard.view');
    final areas = {for (final o in inScope) o.areaId: o.areaName ?? 'Area'};
    final outlets = _areaId == null ? inScope : inScope.where((o) => o.areaId == _areaId).toList();
    final key = (key: outlets.map((o) => o.id).join(','), days: _days);
    final data = ref.watch(dashboardProvider(key));
    final canExport = session.hasAny('data.export');

    return AdminPage(
      breadcrumb: '${_areaId == null ? (areas.length > 1 ? 'Group' : areas.values.firstOrNull ?? '') : areas[_areaId]} · '
          '${outlets.length} outlets · ${_days == 7 ? 'Last 7 days' : 'Last 4 weeks'}',
      title: _areaId == null && areas.length > 1 ? 'Group overview' : 'Area overview',
      actions: [
        if (areas.length > 1)
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              initialValue: _areaId,
              decoration: const InputDecoration(labelText: 'Area'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All areas')),
                for (final a in areas.entries) DropdownMenuItem(value: a.key, child: Text(a.value)),
              ],
              onChanged: (v) => setState(() => _areaId = v),
            ),
          ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<int>(
            initialValue: _days,
            decoration: const InputDecoration(labelText: 'Period'),
            items: const [
              DropdownMenuItem(value: 7, child: Text('Last 7 days')),
              DropdownMenuItem(value: 28, child: Text('Last 4 weeks')),
            ],
            onChanged: (v) => setState(() => _days = v ?? 7),
          ),
        ),
        if (canExport)
          AdminButton('Export CSV',
              icon: Icons.download_rounded, onPressed: data.value == null ? null : () => _export(outlets, data.value!)),
      ],
      children: [
        AdminAsync(
          value: data,
          onRetry: () => ref.invalidate(dashboardProvider(key)),
          builder: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : 2;
                  final tiles = [
                    _Kpi('Checklists on time', Fmt.pct(d.onTimePct), 'Target ${_target.round()}%',
                        warn: d.onTimePct != null && d.onTimePct! < _target),
                    _Kpi('Open issues', '${d.openIssues}',
                        d.medianFixHours == null ? 'No fixes closed yet' : 'Median fix ${_hours(d.medianFixHours!)}'),
                    _Kpi('Late issues, escalated', '${d.escalated}', 'Past their deadline', alert: d.escalated > 0),
                    _Kpi('Training on schedule', Fmt.pct(d.trainingPct), '${d.modulesOverdue} modules overdue'),
                  ];
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: cols == 4 ? 2.1 : 2.4,
                    children: tiles,
                  );
                },
              ),
              const SizedBox(height: 20),
              AdminSection(
                title: 'By outlet',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminTable(
                      columns: const ['Outlet', 'Checklists on time', 'Open issues', 'Late', 'Training', 'Last audit'],
                      rows: [
                        for (final o in outlets)
                          if (d.outlets[o.id] case final k?)
                            DataRow(cells: [
                              DataCell(Text(o.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(SizedBox(width: 220, child: _Bar(k.onTimePct))),
                              DataCell(Text('${k.openIssues}')),
                              DataCell(Text('${k.lateIssues}',
                                  style: TextStyle(
                                      fontWeight: k.lateIssues > 0 ? FontWeight.w700 : FontWeight.w400,
                                      color: k.lateIssues > 0 ? AppColors.danger : null))),
                              DataCell(Text(k.traineesBehind == 0
                                  ? 'On schedule'
                                  : '${k.traineesBehind} behind · ${k.modulesOverdue} overdue')),
                              DataCell(Text(k.lastAudit == null ? 'Never' : _ago(k.lastAudit!),
                                  style: const TextStyle(color: AppColors.textSecondary))),
                            ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Wrap(spacing: 16, children: [
                      _Legend(AppColors.primary, 'At or above 90% target'),
                      _Legend(AppColors.belowTarget, 'Below target'),
                    ]),
                  ],
                ),
              ),
              AdminSection(title: 'Checklists on time, by week', child: _Trend(weekly: d.weekly)),
              AdminSection(
                title: 'Escalated',
                trailing: TextButton(onPressed: () => context.go('/issues'), child: const Text('All issues')),
                child: d.escalatedIssues.isEmpty
                    ? const Text('Nothing escalated.', style: TextStyle(color: AppColors.textSecondary))
                    : Column(
                        children: [
                          for (final i in d.escalatedIssues)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                              child: Row(
                                children: [
                                  Pill('${_late(i.dueAt)} late', tone: Tone.danger, small: true),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text('${i.title} · ${session.outlets[i.outletId]?.name ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Text(i.assignedTo == null ? 'Not assigned' : 'Assigned',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _export(List<Outlet> outlets, DashboardData d) {
    final rows = <List<Object?>>[
      ['Outlet', 'Area', 'Checklist runs', 'On time', 'On time %', 'Missed', 'Open issues', 'Late issues',
        'Escalated', 'Modules assigned', 'Modules overdue', 'Trainees behind', 'Last audit'],
      for (final o in outlets)
        if (d.outlets[o.id] case final k?)
          [o.name, o.areaName, k.runs, k.onTime, k.onTimePct?.toStringAsFixed(1), k.missed, k.openIssues,
            k.lateIssues, k.escalated, k.assigned, k.modulesOverdue, k.traineesBehind,
            k.lastAudit == null ? '' : Fmt.isoDate(k.lastAudit!)],
    ];
    downloadTextFile('asah-dashboard-${Fmt.isoDate(DateTime.now())}.csv', Csv().encode(rows));
  }

  static String _hours(double h) => h < 1 ? '${(h * 60).round()} m' : '${h.floor()} h ${((h % 1) * 60).round()} m';
  static String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    return days == 0 ? 'Today' : '$days days ago';
  }

  static String _late(DateTime due) {
    final h = DateTime.now().difference(due).inHours;
    return h >= 24 ? '${h ~/ 24} d' : '$h h';
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.note, {this.alert = false, this.warn = false});
  final String label;
  final String value;
  final String note;
  final bool alert;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: alert ? AppColors.dangerSoft : AppColors.surface,
        border: Border.all(color: alert ? AppColors.dangerBorder : AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: alert ? AppColors.dangerDark : AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: alert ? AppColors.danger : AppColors.text)),
          const SizedBox(height: 6),
          Text(note,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: warn || alert ? FontWeight.w600 : FontWeight.w400,
                  color: alert ? AppColors.dangerDark : (warn ? AppColors.warning : AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.pct);
  final double? pct;

  @override
  Widget build(BuildContext context) {
    final below = pct != null && pct! < _target;
    return Row(
      children: [
        Expanded(
          child: ProgressBar(value: (pct ?? 0) / 100, height: 8, color: below ? AppColors.belowTarget : AppColors.primary),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 44, child: Text(Fmt.pct(pct), style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);
}

/// Simple weekly bar chart: share of checklist runs done on time.
class _Trend extends StatelessWidget {
  const _Trend({required this.weekly});
  final Map<DateTime, ({int runs, int onTime})> weekly;

  @override
  Widget build(BuildContext context) {
    final weeks = weekly.keys.toList()..sort();
    if (weeks.isEmpty) return const Text('No checklist runs yet.', style: TextStyle(color: AppColors.textSecondary));
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final w in weeks)
            Expanded(
              child: Builder(builder: (context) {
                final v = weekly[w]!;
                final pct = v.runs == 0 ? 0.0 : v.onTime * 100 / v.runs;
                return Tooltip(
                  message: '${v.onTime} of ${v.runs} on time',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${pct.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          height: 120 * pct / 100,
                          decoration: BoxDecoration(
                            color: pct < _target ? AppColors.belowTarget : AppColors.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(Fmt.day(w), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
