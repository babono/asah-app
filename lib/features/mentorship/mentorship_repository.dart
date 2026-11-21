import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/format.dart';
import '../learning/models.dart';
import '../session/session_provider.dart';

class Mentorship {
  const Mentorship({
    required this.id,
    required this.mentorId,
    required this.traineeId,
    required this.outletId,
    required this.startedAt,
    this.endedAt,
    this.endReason,
    this.mentorName,
    this.traineeName,
    this.traineePosition,
    this.traineePositionId,
    this.traineeHireDate,
  });

  final String id;
  final String mentorId;
  final String traineeId;
  final String outletId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? endReason;
  final String? mentorName;
  final String? traineeName;
  final String? traineePosition;
  final String? traineePositionId;
  final DateTime? traineeHireDate;

  static const select = 'id, mentor_id, trainee_id, outlet_id, started_at, ended_at, end_reason, '
      'mentor:profiles!mentorships_mentor_id_fkey(full_name), '
      'trainee:profiles!mentorships_trainee_id_fkey(full_name, hire_date, position_id, positions(name))';

  factory Mentorship.fromJson(Map<String, dynamic> j) {
    final t = j['trainee'] as Map<String, dynamic>?;
    return Mentorship(
      id: j['id'] as String,
      mentorId: j['mentor_id'] as String,
      traineeId: j['trainee_id'] as String,
      outletId: j['outlet_id'] as String,
      startedAt: DateTime.parse(j['started_at'] as String),
      endedAt: parseTs(j['ended_at']),
      endReason: j['end_reason'] as String?,
      mentorName: (j['mentor'] as Map?)?['full_name'] as String?,
      traineeName: t?['full_name'] as String?,
      traineePositionId: t?['position_id'] as String?,
      traineePosition: (t?['positions'] as Map?)?['name'] as String?,
      traineeHireDate: t?['hire_date'] == null ? null : DateTime.parse(t!['hire_date'] as String),
    );
  }

  bool get active => endedAt == null;

  /// "Day 12" since the trainee started work (or the mentorship).
  int get traineeDay => DateTime.now().difference(traineeHireDate ?? startedAt).inDays + 1;
}

class Checkin {
  const Checkin({required this.id, required this.weekOf, required this.feedback, this.goals, required this.createdAt});
  final String id;
  final DateTime weekOf;
  final String feedback;
  final String? goals;
  final DateTime createdAt;

  factory Checkin.fromJson(Map<String, dynamic> j) => Checkin(
        id: j['id'] as String,
        weekOf: DateTime.parse(j['week_of'] as String),
        feedback: j['feedback'] as String,
        goals: j['goals'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class MentorRating {
  const MentorRating({required this.ratings, this.average, this.shownAfter});
  final int ratings;
  final num? average;
  final int? shownAfter;
}

class MentorshipRepository {
  MentorshipRepository(this._db);
  final SupabaseClient _db;

  Future<List<Mentorship>> asMentor(String mentorId) async {
    final rows = await _db
        .from('mentorships')
        .select(Mentorship.select)
        .eq('mentor_id', mentorId)
        .isFilter('ended_at', null)
        .order('started_at', ascending: true);
    return (rows as List).map((r) => Mentorship.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// The trainee's mentorships, newest first (current one, then ended ones to rate).
  Future<List<Mentorship>> asTrainee(String traineeId) async {
    final rows = await _db
        .from('mentorships')
        .select(Mentorship.select)
        .eq('trainee_id', traineeId)
        .order('started_at', ascending: false);
    return (rows as List).map((r) => Mentorship.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Mentorship>> atOutlet(String outletId) async {
    final rows = await _db
        .from('mentorships')
        .select(Mentorship.select)
        .eq('outlet_id', outletId)
        .isFilter('ended_at', null);
    return (rows as List).map((r) => Mentorship.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Mentorship> byId(String id) async =>
      Mentorship.fromJson(await _db.from('mentorships').select(Mentorship.select).eq('id', id).single());

  Future<List<PracticalSubmission>> pendingPracticals(List<String> traineeIds) async {
    if (traineeIds.isEmpty) return [];
    final rows = await _db
        .from('practical_submissions')
        .select(PracticalSubmission.select)
        .inFilter('user_id', traineeIds)
        .eq('status', 'pending')
        .order('submitted_at', ascending: true);
    return (rows as List).map((r) => PracticalSubmission.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<PracticalSubmission> submission(String id) async => PracticalSubmission.fromJson(
      await _db.from('practical_submissions').select(PracticalSubmission.select).eq('id', id).single());

  Future<List<RubricCriterion>> rubric(String moduleVersionId) async {
    final rows = await _db
        .from('rubric_criteria')
        .select('id, title, description, sort')
        .eq('module_version_id', moduleVersionId)
        .order('sort', ascending: true);
    return (rows as List).map((r) => RubricCriterion.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Mentor scores each rubric line pass/redo (T3). Server checks it is their trainee.
  Future<String> scorePractical(String submissionId, Map<String, String> results, {Map<String, String>? notes, String? feedback}) async {
    final scores = results.entries
        .map((e) => {'criterion_id': e.key, 'result': e.value, 'note': notes?[e.key]})
        .toList();
    final res = await _db.rpc('score_practical', params: {
      'p_submission': submissionId,
      'p_scores': scores,
      'p_feedback': feedback,
    });
    return res as String;
  }

  Future<List<Checkin>> checkins(String mentorshipId) async {
    final rows = await _db
        .from('mentor_checkins')
        .select('id, week_of, feedback, goals, created_at')
        .eq('mentorship_id', mentorshipId)
        .order('week_of', ascending: false);
    return (rows as List).map((r) => Checkin.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Latest check-in week per mentorship (to show "check-in due").
  Future<Map<String, DateTime>> lastCheckins(List<String> mentorshipIds) async {
    if (mentorshipIds.isEmpty) return {};
    final rows = await _db
        .from('mentor_checkins')
        .select('mentorship_id, week_of')
        .inFilter('mentorship_id', mentorshipIds)
        .order('week_of', ascending: false);
    final out = <String, DateTime>{};
    for (final r in rows as List) {
      out.putIfAbsent(r['mentorship_id'] as String, () => DateTime.parse(r['week_of'] as String));
    }
    return out;
  }

  /// One check-in per week (M3). Saving again in the same week updates it.
  Future<void> saveCheckin(String mentorshipId, {required String feedback, String? goals}) async {
    final week = Fmt.isoDate(Fmt.weekStart(DateTime.now()));
    final uid = _db.auth.currentUser!.id;
    final existing = await _db
        .from('mentor_checkins')
        .select('id')
        .eq('mentorship_id', mentorshipId)
        .eq('week_of', week)
        .maybeSingle();
    if (existing == null) {
      await _db.from('mentor_checkins').insert({
        'mentorship_id': mentorshipId,
        'week_of': week,
        'feedback': feedback,
        'goals': goals,
        'created_by': uid,
      });
    } else {
      await _db.from('mentor_checkins').update({'feedback': feedback, 'goals': goals}).eq('id', existing['id']);
    }
  }

  /// Average only, and only after enough ratings (M7).
  Future<MentorRating> myRating() async {
    final r = await _db.rpc('my_mentor_rating') as Map<String, dynamic>;
    return MentorRating(ratings: r['ratings'] as int, average: r['average'] as num?, shownAfter: r['shown_after'] as int?);
  }

  Future<void> rateMentor(String mentorshipId, int score, String? comment) async {
    await _db.rpc('submit_mentor_rating', params: {
      'p_mentorship': mentorshipId,
      'p_score': score,
      'p_comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    });
  }

  /// Outlet manager pairs a mentor; the server checks eligibility (M1).
  Future<void> assignMentor(String traineeId, String mentorId) async {
    await _db.rpc('assign_mentor', params: {'p_trainee': traineeId, 'p_mentor': mentorId});
  }

  /// M5: end when the trainee finished their path.
  Future<void> endMentorship(String id, {String reason = 'path_completed'}) async {
    await _db
        .from('mentorships')
        .update({'ended_at': DateTime.now().toUtc().toIso8601String(), 'end_reason': reason}).eq('id', id);
  }

  /// Recently scored practical tests at an outlet, for spot checks (M6).
  Future<List<({PracticalSubmission submission, bool checked})>> recentSignoffs(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final rows = await _db
        .from('practical_submissions')
        .select('${PracticalSubmission.select}, practical_spot_checks(id)')
        .inFilter('user_id', userIds)
        .neq('status', 'pending')
        .order('scored_at', ascending: false)
        .limit(30);
    return (rows as List)
        .map((r) => (
              submission: PracticalSubmission.fromJson(r as Map<String, dynamic>),
              checked: ((r['practical_spot_checks'] as List?) ?? []).isNotEmpty,
            ))
        .toList();
  }

  Future<void> spotCheck(String submissionId, {required bool agrees, String? note}) async {
    await _db.from('practical_spot_checks').insert({
      'submission_id': submissionId,
      'checked_by': _db.auth.currentUser!.id,
      'agrees': agrees,
      'note': note,
    });
  }
}

final mentorshipRepositoryProvider = Provider((ref) => MentorshipRepository(userDb(ref)));

final myTraineesProvider = FutureProvider<List<Mentorship>>((ref) async {
  final s = await ref.watch(sessionProvider.future);
  if (s == null || !s.isMentor) return [];
  return ref.watch(mentorshipRepositoryProvider).asMentor(s.profile.id);
});

final myMentorshipsProvider = FutureProvider<List<Mentorship>>((ref) async {
  final s = await ref.watch(sessionProvider.future);
  if (s == null) return [];
  return ref.watch(mentorshipRepositoryProvider).asTrainee(s.profile.id);
});

final mentorshipProvider = FutureProvider.family<Mentorship, String>((ref, id) {
  return ref.watch(mentorshipRepositoryProvider).byId(id);
});

final checkinsProvider = FutureProvider.family<List<Checkin>, String>((ref, mentorshipId) {
  return ref.watch(mentorshipRepositoryProvider).checkins(mentorshipId);
});

final myMentorRatingProvider = FutureProvider<MentorRating>((ref) {
  return ref.watch(mentorshipRepositoryProvider).myRating();
});
