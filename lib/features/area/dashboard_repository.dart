import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/format.dart';
import '../issues/issue_repository.dart';

/// Per-outlet numbers for the area and group dashboards (S4, S5).
class OutletKpis {
  OutletKpis(this.outletId);
  final String outletId;
  int runs = 0;
  int onTime = 0;
  int missed = 0;
  int openIssues = 0;
  int lateIssues = 0;
  int escalated = 0;
  int traineesBehind = 0;
  int modulesOverdue = 0;
  int assigned = 0;
  int completed = 0;
  DateTime? lastAudit;

  double? get onTimePct => runs == 0 ? null : onTime * 100 / runs;
  double? get trainingPct => assigned == 0 ? null : (assigned - modulesOverdue) * 100 / assigned;
}

class DashboardData {
  DashboardData(this.outlets, this.escalatedIssues, this.weekly, this.medianFixHours);
  final Map<String, OutletKpis> outlets;
  final List<Issue> escalatedIssues;

  /// Week start -> (runs, onTime) for the trend (S5).
  final Map<DateTime, ({int runs, int onTime})> weekly;
  final double? medianFixHours;

  int get runs => outlets.values.fold(0, (s, o) => s + o.runs);
  int get onTime => outlets.values.fold(0, (s, o) => s + o.onTime);
  double? get onTimePct => runs == 0 ? null : onTime * 100 / runs;
  int get openIssues => outlets.values.fold(0, (s, o) => s + o.openIssues);
  int get escalated => escalatedIssues.length;
  int get modulesOverdue => outlets.values.fold(0, (s, o) => s + o.modulesOverdue);
  int get assigned => outlets.values.fold(0, (s, o) => s + o.assigned);
  double? get trainingPct => assigned == 0 ? null : (assigned - modulesOverdue) * 100 / assigned;
}

class DashboardRepository {
  DashboardRepository(this._db);
  final SupabaseClient _db;

  /// [days] back from today. RLS on the views limits rows to the caller's scope.
  Future<DashboardData> load(List<String> outletIds, {int days = 7}) async {
    final out = {for (final id in outletIds) id: OutletKpis(id)};
    if (outletIds.isEmpty) return DashboardData(out, [], {}, null);
    final since = Fmt.isoDate(DateTime.now().subtract(Duration(days: days - 1)));
    final trendSince = Fmt.isoDate(DateTime.now().subtract(const Duration(days: 7 * 8)));

    final results = await Future.wait([
      _db
          .from('v_outlet_daily_compliance')
          .select('outlet_id, shift_date, runs, on_time, missed')
          .inFilter('outlet_id', outletIds)
          .gte('shift_date', trendSince),
      _db.from('issues').select(Issue.select).inFilter('outlet_id', outletIds).neq('status', 'closed'),
      _db.from('v_training_progress').select('outlet_id, assigned, completed, overdue').inFilter('outlet_id', outletIds),
      _db
          .from('checklist_runs')
          .select('outlet_id, submitted_at')
          .inFilter('outlet_id', outletIds)
          .not('conducted_by', 'is', null)
          .eq('status', 'submitted')
          .order('submitted_at', ascending: false)
          .limit(200),
      _db
          .from('v_issue_resolution')
          .select('hours_open')
          .inFilter('outlet_id', outletIds)
          .eq('status', 'closed')
          .gte('created_at', DateTime.now().subtract(Duration(days: days.clamp(7, 90))).toUtc().toIso8601String())
          .limit(1000),
    ]);

    final weekly = <DateTime, ({int runs, int onTime})>{};
    for (final r in results[0] as List) {
      final day = DateTime.parse(r['shift_date'] as String);
      final runs = (r['runs'] as num).toInt();
      final onTime = (r['on_time'] as num).toInt();
      final week = Fmt.weekStart(day);
      final w = weekly[week] ?? (runs: 0, onTime: 0);
      weekly[week] = (runs: w.runs + runs, onTime: w.onTime + onTime);
      if (r['shift_date'].compareTo(since) < 0) continue;
      final k = out[r['outlet_id']];
      if (k == null) continue;
      k.runs += runs;
      k.onTime += onTime;
      k.missed += (r['missed'] as num).toInt();
    }

    final issues = (results[1] as List).map((r) => Issue.fromJson(r as Map<String, dynamic>)).toList();
    for (final i in issues) {
      final k = out[i.outletId]!;
      k.openIssues++;
      if (i.isLate) k.lateIssues++;
      if (i.escalatedAt != null && i.isOpen) k.escalated++;
    }

    for (final t in results[2] as List) {
      final k = out[t['outlet_id']];
      if (k == null) continue;
      final overdue = (t['overdue'] as num).toInt();
      k.assigned += (t['assigned'] as num).toInt();
      k.completed += (t['completed'] as num).toInt();
      k.modulesOverdue += overdue;
      if (overdue > 0) k.traineesBehind++;
    }

    for (final a in results[3] as List) {
      final k = out[a['outlet_id']];
      if (k != null && k.lastAudit == null) k.lastAudit = DateTime.parse(a['submitted_at'] as String);
    }

    final hours = (results[4] as List).map((r) => (r['hours_open'] as num).toDouble()).toList()..sort();
    final median = hours.isEmpty ? null : hours[hours.length ~/ 2];

    final escalated = issues.where((i) => i.isOpen && i.escalatedAt != null).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return DashboardData(out, escalated, weekly, median);
  }
}

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(ref.watch(supabaseProvider)));

final dashboardProvider = FutureProvider.family<DashboardData, ({String key, int days})>((ref, args) {
  final ids = args.key.split(',').where((s) => s.isNotEmpty).toList();
  return ref.watch(dashboardRepositoryProvider).load(ids, days: args.days);
});
