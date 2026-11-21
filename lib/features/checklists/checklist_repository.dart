import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../core/offline/local_store.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/format.dart';
import '../session/models.dart';
import '../session/session_provider.dart';
import 'models.dart';

class ChecklistRepository {
  ChecklistRepository(this._db, this._store);
  final SupabaseClient _db;
  final LocalStore _store;

  /// Runs this person fills today: their position's routine checklists at
  /// their outlet, plus audits they are conducting. Cached for offline use.
  Future<List<ChecklistRun>> myRunsToday(Session session) async {
    final key = 'cache:myRuns:${session.profile.id}';
    try {
      final today = Fmt.isoDate(DateTime.now());
      final rows = await _db
          .from('checklist_runs')
          .select(ChecklistRun.select)
          .or('shift_date.eq.$today,and(status.in.(pending,in_progress),conducted_by.eq.${session.profile.id})')
          .order('due_at');
      var runs = (rows as List).map((r) => ChecklistRun.fromJson(r as Map<String, dynamic>)).toList();

      // Managers also see every outlet run (checklist.view); keep only the
      // ones this person's position fills, or audits they run.
      final templateIds = runs.map((r) => r.templateId).toSet().toList();
      final positions = templateIds.isEmpty
          ? <dynamic>[]
          : await _db
              .from('checklist_template_positions')
              .select('template_id, position_id')
              .inFilter('template_id', templateIds);
      final mine = positions
          .where((p) => p['position_id'] == session.profile.positionId)
          .map((p) => p['template_id'] as String)
          .toSet();
      runs = runs
          .where((r) => r.isAudit
              ? r.conductedBy == session.profile.id
              : mine.contains(r.templateId) &&
                  r.outletId == session.profile.outletId &&
                  (r.isOpen || r.submittedBy == session.profile.id))
          .toList();
      await _store.setJson(key, runs.map((r) => r.toJson()).toList());
      return runs;
    } catch (e) {
      final cached = _store.getList(key);
      if (isNetworkError(e) && cached != null) {
        return cached.map((r) => ChecklistRun.fromJson(r as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  /// Every run at an outlet on a day (outlet manager view, A7).
  Future<List<ChecklistRun>> outletRuns(String outletId, DateTime day) async {
    final rows = await _db
        .from('checklist_runs')
        .select(ChecklistRun.select)
        .eq('outlet_id', outletId)
        .eq('shift_date', Fmt.isoDate(day))
        .order('due_at');
    return (rows as List).map((r) => ChecklistRun.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<ChecklistRun>> myAudits(String userId) async {
    final rows = await _db
        .from('checklist_runs')
        .select(ChecklistRun.select)
        .eq('conducted_by', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((r) => ChecklistRun.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<ChecklistRun> run(String runId) async {
    final key = 'cache:run:$runId';
    try {
      final row = await _db.from('checklist_runs').select(ChecklistRun.select).eq('id', runId).single();
      await _store.setJson(key, row);
      return ChecklistRun.fromJson(row);
    } catch (e) {
      final cached = _store.getMap(key);
      if (isNetworkError(e) && cached != null) return ChecklistRun.fromJson(cached);
      rethrow;
    }
  }

  Future<List<ChecklistItem>> items(String templateVersionId) async {
    final key = 'cache:items:$templateVersionId';
    try {
      final rows = await _db
          .from('checklist_items')
          .select(ChecklistItem.select)
          .eq('template_version_id', templateVersionId)
          .order('sort');
      await _store.setJson(key, rows);
      return (rows as List).map((r) => ChecklistItem.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      final cached = _store.getList(key);
      if (isNetworkError(e) && cached != null) {
        return cached.map((r) => ChecklistItem.fromJson(r as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  /// Pre-fetches items for every run so they can be filled offline.
  Future<Map<String, TemplateStats>> statsFor(List<ChecklistRun> runs) async {
    final out = <String, TemplateStats>{};
    for (final v in runs.map((r) => r.templateVersionId).toSet()) {
      try {
        final items = await this.items(v);
        out[v] = TemplateStats(items.length, items.where((i) => i.needsPhoto).length);
      } catch (_) {}
    }
    return out;
  }

  Future<List<ChecklistResponse>> responses(String runId) async {
    final rows = await _db
        .from('checklist_responses')
        .select('id, item_id, value_bool, value_number, value_text, passed, answered_by, answered_at, '
            'checklist_response_photos(media_file_id)')
        .eq('run_id', runId);
    return (rows as List).map((r) => ChecklistResponse.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Audit forms an area manager can start (S4).
  Future<List<({String id, String name})>> auditTemplates() async {
    final rows = await _db
        .from('checklist_templates')
        .select('id, name')
        .eq('kind', 'audit')
        .isFilter('archived_at', null)
        .order('name');
    return (rows as List).map((r) => (id: r['id'] as String, name: r['name'] as String)).toList();
  }

  Future<String> startAudit(String templateId, String outletId) async {
    final id = await _db.rpc('start_audit', params: {'p_template': templateId, 'p_outlet': outletId});
    return id as String;
  }

  // ---- Upload steps, used by the sync outbox ----

  /// Writes every answer (insert or update) and returns item id -> response id.
  Future<Map<String, String>> saveResponses(String runId, Map<String, Answer> answers, DateTime answeredAt) async {
    final uid = _db.auth.currentUser!.id;
    final rows = answers.entries
        .map((e) => {
              'run_id': runId,
              'item_id': e.key,
              'value_bool': e.value.yes,
              'value_number': e.value.number,
              'value_text': (e.value.text ?? '').trim().isEmpty ? null : e.value.text!.trim(),
              'answered_by': uid,
              'answered_at': answeredAt.toUtc().toIso8601String(),
            })
        .toList();
    if (rows.isEmpty) return {};
    final saved = await _db.from('checklist_responses').upsert(rows, onConflict: 'run_id,item_id').select('id, item_id');
    return {for (final r in saved as List) r['item_id'] as String: r['id'] as String};
  }

  Future<void> attachPhoto(String responseId, String mediaId) async {
    await _db
        .from('checklist_response_photos')
        .upsert({'response_id': responseId, 'media_file_id': mediaId}, ignoreDuplicates: true);
  }

  /// Server stamps time and checks the location (A3) and raises issues (A4).
  Future<({int failed, int total})> submit(String runId, double? lat, double? lng) async {
    final res = await _db.rpc('submit_checklist_run', params: {
      'p_run': runId,
      'p_latitude': lat,
      'p_longitude': lng,
    }) as Map<String, dynamic>;
    return (failed: res['failed'] as int, total: res['total'] as int);
  }
}

final checklistRepositoryProvider = Provider<ChecklistRepository>(
  (ref) => ChecklistRepository(ref.watch(supabaseProvider), ref.watch(localStoreProvider)),
);

final myRunsTodayProvider = FutureProvider<List<ChecklistRun>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null || !(session.canFill || session.isAreaManager)) return [];
  return ref.watch(checklistRepositoryProvider).myRunsToday(session);
});

final templateStatsProvider = FutureProvider<Map<String, TemplateStats>>((ref) async {
  final runs = await ref.watch(myRunsTodayProvider.future);
  return ref.watch(checklistRepositoryProvider).statsFor(runs.where((r) => r.isOpen).toList());
});

final runProvider = FutureProvider.family<ChecklistRun, String>((ref, id) {
  return ref.watch(checklistRepositoryProvider).run(id);
});

final runItemsProvider = FutureProvider.family<List<ChecklistItem>, String>((ref, versionId) {
  return ref.watch(checklistRepositoryProvider).items(versionId);
});

final runResponsesProvider = FutureProvider.family<List<ChecklistResponse>, String>((ref, runId) {
  return ref.watch(checklistRepositoryProvider).responses(runId);
});

final outletRunsTodayProvider = FutureProvider.family<List<ChecklistRun>, String>((ref, outletId) {
  return ref.watch(checklistRepositoryProvider).outletRuns(outletId, DateTime.now());
});
