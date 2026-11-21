import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/local_store.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/errors.dart';
import '../session/session_provider.dart';
import 'models.dart';

class LearningRepository {
  LearningRepository(this._db, this._store);
  final SupabaseClient _db;
  final LocalStore _store;

  /// Assignments of a person, ordered by their learning path, with content
  /// progress (T10). Readable by the person, their mentor and managers in scope.
  Future<List<Assignment>> assignments(String userId, {String? positionId, bool cache = false}) async {
    final key = 'cache:assignments:$userId';
    try {
      final rows = await _db
          .from('module_assignments')
          .select(Assignment.select)
          .eq('user_id', userId)
          .order('assigned_at');
      final list = (rows as List).map((r) => Assignment.fromJson(r as Map<String, dynamic>)).toList();
      // Keep the latest assignment per module (a retraining reopens one).
      final byModule = <String, Assignment>{};
      for (final a in list) {
        final prev = byModule[a.moduleId];
        if (prev == null || (prev.isCompleted && !a.isCompleted) || a.assignedAt.isAfter(prev.assignedAt)) {
          byModule[a.moduleId] = a;
        }
      }
      final result = byModule.values.toList();
      await _attachProgress(result);
      if (positionId != null) await _attachPathOrder(result, positionId);
      result.sort(_order);
      if (cache) await _store.setJson(key, result.map((a) => a.toJson()).toList());
      return result;
    } catch (e) {
      final cached = _store.getList(key);
      if (cache && isNetworkError(e) && cached != null) {
        return cached.map((r) => Assignment.fromJson(r as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  static int _order(Assignment a, Assignment b) {
    // Refreshers and retraining first, then the path in its order.
    int rank(Assignment x) => x.isPathModule ? 1 : 0;
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final s = (a.pathSort ?? 9999).compareTo(b.pathSort ?? 9999);
    if (s != 0) return s;
    return a.assignedAt.compareTo(b.assignedAt);
  }

  Future<void> _attachProgress(List<Assignment> list) async {
    if (list.isEmpty) return;
    final versionIds = list.map((a) => a.moduleVersionId).toSet().toList();
    final results = await Future.wait([
      _db.from('content_blocks').select('id, module_version_id').inFilter('module_version_id', versionIds),
      _db.from('block_progress').select('assignment_id, block_id').inFilter('assignment_id', list.map((a) => a.id).toList()),
    ]);
    final blocksByVersion = <String, Set<String>>{};
    for (final b in results[0] as List) {
      blocksByVersion.putIfAbsent(b['module_version_id'] as String, () => {}).add(b['id'] as String);
    }
    final doneByAssignment = <String, Set<String>>{};
    for (final p in results[1] as List) {
      doneByAssignment.putIfAbsent(p['assignment_id'] as String, () => {}).add(p['block_id'] as String);
    }
    for (final a in list) {
      final blocks = blocksByVersion[a.moduleVersionId] ?? {};
      a.blocksTotal = blocks.length;
      a.blocksDone = (doneByAssignment[a.id] ?? {}).intersection(blocks).length;
    }
  }

  Future<void> _attachPathOrder(List<Assignment> list, String positionId) async {
    final path = await _db
        .from('learning_paths')
        .select('id, name, learning_path_items(module_id, sort, is_mandatory, due_days)')
        .eq('position_id', positionId)
        .isFilter('archived_at', null)
        .maybeSingle();
    if (path == null) return;
    final items = {
      for (final i in path['learning_path_items'] as List) i['module_id'] as String: i as Map<String, dynamic>,
    };
    for (final a in list) {
      final i = items[a.moduleId];
      if (i == null) continue;
      a.pathSort = i['sort'] as int;
      a.mandatory = i['is_mandatory'] as bool;
      a.dueDays = i['due_days'] as int;
    }
  }

  Future<String?> pathName(String positionId) async {
    final row = await _db
        .from('learning_paths')
        .select('name')
        .eq('position_id', positionId)
        .isFilter('archived_at', null)
        .maybeSingle();
    return row?['name'] as String?;
  }

  /// Everything the module screen needs, cached for offline lessons (F7).
  Future<ModuleDetail> moduleDetail(String assignmentId, {String? positionId}) async {
    final key = 'cache:module:$assignmentId';
    try {
      final a = Assignment.fromJson(
          await _db.from('module_assignments').select(Assignment.select).eq('id', assignmentId).single());
      final v = a.moduleVersionId;
      final results = await Future.wait([
        _db
            .from('content_blocks')
            .select('id, sort, type, title, body, media_file_id, media_files(duration_seconds)')
            .eq('module_version_id', v)
            .order('sort'),
        _db.from('block_progress').select('block_id').eq('assignment_id', assignmentId),
        _db.from('quizzes').select('id, pass_mark_pct, max_attempts, time_limit_seconds, question_count').eq('module_version_id', v).maybeSingle(),
        _db
            .from('quiz_attempts')
            .select('id, score_pct, passed, submitted_at, started_at')
            .eq('assignment_id', assignmentId)
            .order('started_at', ascending: false),
        _db.from('rubric_criteria').select('id, title, description, sort').eq('module_version_id', v).order('sort'),
        _db
            .from('practical_submissions')
            .select(PracticalSubmission.select)
            .eq('assignment_id', assignmentId)
            .order('submitted_at', ascending: false),
        _db.from('module_versions').select('certificate_valid_days').eq('id', v).maybeSingle(),
      ]);
      final quizRow = results[2] as Map<String, dynamic>?;
      int? pos, len;
      String? pathName;
      if (a.pathId != null) {
        final path = await _db
            .from('learning_paths')
            .select('name, learning_path_items(module_id, sort)')
            .eq('id', a.pathId!)
            .maybeSingle();
        if (path != null) {
          final items = (path['learning_path_items'] as List).toList()
            ..sort((x, y) => (x['sort'] as int).compareTo(y['sort'] as int));
          len = items.length;
          final idx = items.indexWhere((i) => i['module_id'] == a.moduleId);
          pos = idx < 0 ? null : idx + 1;
          pathName = path['name'] as String?;
        }
      }
      final json = {
        'assignment': a.toJson(),
        'blocks': results[0],
        'done': (results[1] as List).map((p) => p['block_id']).toList(),
        'quiz': quizRow,
        'attempts': results[3],
        'rubric': results[4],
        'submissions': results[5],
        'cert_days': (results[6] as Map?)?['certificate_valid_days'],
        'pos': pos,
        'len': len,
        'path_name': pathName,
      };
      await _store.setJson(key, json);
      return _detailFromJson(json);
    } catch (e) {
      final cached = _store.getMap(key);
      if (isNetworkError(e) && cached != null) return _detailFromJson(cached);
      rethrow;
    }
  }

  ModuleDetail _detailFromJson(Map<String, dynamic> j) {
    final quiz = j['quiz'] as Map<String, dynamic>?;
    return ModuleDetail(
      assignment: Assignment.fromJson(j['assignment'] as Map<String, dynamic>),
      blocks: (j['blocks'] as List).map((b) => ContentBlock.fromJson(b as Map<String, dynamic>)).toList(),
      completedBlockIds: (j['done'] as List).cast<String>().toSet(),
      quiz: quiz == null ? null : Quiz.fromJson(quiz),
      questionCount: (quiz?['question_count'] as int?) ?? 0,
      attempts: (j['attempts'] as List).map((a) => QuizAttempt.fromJson(a as Map<String, dynamic>)).toList(),
      rubric: (j['rubric'] as List).map((r) => RubricCriterion.fromJson(r as Map<String, dynamic>)).toList(),
      submissions:
          (j['submissions'] as List).map((s) => PracticalSubmission.fromJson(s as Map<String, dynamic>)).toList(),
      certificateValidDays: j['cert_days'] as int?,
      positionInPath: j['pos'] as int?,
      pathLength: j['len'] as int?,
      pathName: j['path_name'] as String?,
    );
  }

  /// Marks a lesson block done; completes the module when everything is done.
  Future<void> completeBlock(String assignmentId, String blockId) async {
    await _db.rpc('complete_block', params: {'p_assignment': assignmentId, 'p_block': blockId});
  }

  /// Records a block as done in the offline cache (when the RPC is queued).
  Future<void> markBlockDoneLocally(String assignmentId, String blockId) async {
    final key = 'cache:module:$assignmentId';
    final cached = _store.getMap(key);
    if (cached == null) return;
    final done = (cached['done'] as List).cast<String>().toSet()..add(blockId);
    cached['done'] = done.toList();
    await _store.setJson(key, cached);
  }

  Future<QuizSession> startQuiz(String assignmentId) async {
    final res = await _db.rpc('start_quiz_attempt', params: {'p_assignment': assignmentId}) as Map<String, dynamic>;
    final questions = ((res['questions'] as List?) ?? []).map((q) {
      final opts = ((q['options'] as List?) ?? [])
          .map((o) => (id: o['id'] as String, label: o['label'] as String))
          .toList();
      return QuizQuestion(q['id'] as String, q['prompt'] as String, opts);
    }).toList();
    return QuizSession(res['attempt_id'] as String, questions, res['time_limit_seconds'] as int?);
  }

  Future<({num score, bool passed})> submitQuiz(String attemptId, Map<String, String> answers) async {
    final res = await _db.rpc('submit_quiz_attempt', params: {'p_attempt': attemptId, 'p_answers': answers})
        as Map<String, dynamic>;
    return (score: res['score_pct'] as num, passed: res['passed'] as bool);
  }

  Future<void> submitPractical(String assignmentId, String mediaId) async {
    await _db.rpc('submit_practical', params: {'p_assignment': assignmentId, 'p_media': mediaId});
  }

  Future<List<Certificate>> certificates(String userId) async {
    final rows = await _db
        .from('certificates')
        .select('id, issued_at, expires_at, module_versions(title)')
        .eq('user_id', userId)
        .order('issued_at', ascending: false);
    return (rows as List)
        .map((r) => Certificate(
              id: r['id'] as String,
              title: ((r['module_versions'] as Map?)?['title'] as String?) ?? '',
              issuedAt: DateTime.parse(r['issued_at'] as String),
              expiresAt: r['expires_at'] == null ? null : DateTime.parse(r['expires_at'] as String),
            ))
        .toList();
  }

  /// Published modules (for assigning a refresher, T9).
  Future<List<({String moduleId, String versionId, String title, String category})>> publishedModules() async {
    final rows = await _db
        .from('module_versions')
        .select('id, module_id, title, modules(category)')
        .eq('status', 'published')
        .order('title');
    return (rows as List)
        .map((r) => (
              moduleId: r['module_id'] as String,
              versionId: r['id'] as String,
              title: r['title'] as String,
              category: ((r['modules'] as Map?)?['category'] as String?) ?? '',
            ))
        .toList();
  }

  /// Outlet manager assigns a refresher or one-off module (T9).
  Future<void> assignModule({
    required String userId,
    required String moduleId,
    required String versionId,
    String source = 'refresher',
    int dueInDays = 7,
  }) async {
    await _db.from('module_assignments').insert({
      'user_id': userId,
      'module_id': moduleId,
      'module_version_id': versionId,
      'source': source,
      'assigned_by': _db.auth.currentUser!.id,
      'due_at': DateTime.now().add(Duration(days: dueInDays)).toUtc().toIso8601String(),
    });
  }

  /// Progress summaries for several people (mentor dashboard, team view).
  Future<Map<String, TrainingSummary>> summaries(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final results = await Future.wait([
      _db.from('module_assignments').select('id, user_id, status, due_at, completed_at').inFilter('user_id', userIds),
      _db
          .from('quiz_attempts')
          .select('assignment_id, user_id, score_pct, passed, submitted_at')
          .inFilter('user_id', userIds)
          .not('submitted_at', 'is', null)
          .order('submitted_at', ascending: false),
    ]);
    final out = <String, TrainingSummary>{};
    final now = DateTime.now();
    for (final id in userIds) {
      final mine = (results[0] as List).where((a) => a['user_id'] == id).toList();
      final attempts = (results[1] as List).where((a) => a['user_id'] == id).toList();
      final completedAssignments = mine.where((a) => a['status'] == 'completed').map((a) => a['id']).toSet();
      final failsByAssignment = <String, int>{};
      for (final at in attempts) {
        if (at['passed'] == false && !completedAssignments.contains(at['assignment_id'])) {
          failsByAssignment.update(at['assignment_id'] as String, (v) => v + 1, ifAbsent: () => 1);
        }
      }
      out[id] = TrainingSummary(
        assigned: mine.length,
        completed: completedAssignments.length,
        overdue: mine
            .where((a) =>
                a['completed_at'] == null && a['due_at'] != null && DateTime.parse(a['due_at'] as String).isBefore(now))
            .length,
        lastQuizPct: attempts.isEmpty ? null : attempts.first['score_pct'] as num?,
        failedQuizTwice: failsByAssignment.values.any((n) => n >= 2),
      );
    }
    return out;
  }
}

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => LearningRepository(ref.watch(supabaseProvider), ref.watch(localStoreProvider)),
);

final myAssignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null || !session.canLearn) return [];
  return ref
      .watch(learningRepositoryProvider)
      .assignments(session.profile.id, positionId: session.profile.positionId, cache: true);
});

final myPathNameProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  final pos = session?.profile.positionId;
  if (pos == null) return null;
  try {
    return await ref.watch(learningRepositoryProvider).pathName(pos);
  } catch (_) {
    return null;
  }
});

final moduleDetailProvider = FutureProvider.family<ModuleDetail, String>((ref, assignmentId) {
  return ref.watch(learningRepositoryProvider).moduleDetail(assignmentId);
});

final userAssignmentsProvider = FutureProvider.family<List<Assignment>, ({String userId, String? positionId})>(
  (ref, args) => ref.watch(learningRepositoryProvider).assignments(args.userId, positionId: args.positionId),
);

final certificatesProvider = FutureProvider.family<List<Certificate>, String>((ref, userId) {
  return ref.watch(learningRepositoryProvider).certificates(userId);
});
