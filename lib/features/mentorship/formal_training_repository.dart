import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/format.dart';
import '../session/session_provider.dart';

enum FormalTrainingStatus { requested, approved, declined, cancelled }

/// A 30-minute formal on-the-spot training between a mentor and their trainee.
/// Either side requests a time, the other approves or declines it. Approved
/// sessions are visible to managers with mentorship.view at the outlet, so
/// they can come and watch.
class FormalTraining {
  const FormalTraining({
    required this.id,
    required this.mentorshipId,
    required this.mentorId,
    required this.traineeId,
    required this.outletId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.topic,
    this.note,
    required this.status,
    required this.requestedBy,
    this.respondedAt,
    this.responseNote,
    this.cancelledBy,
    this.mentorName,
    this.traineeName,
  });

  final String id;
  final String mentorshipId;
  final String mentorId;
  final String traineeId;
  final String outletId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String topic;
  final String? note;
  final FormalTrainingStatus status;
  final String requestedBy;
  final DateTime? respondedAt;
  final String? responseNote;
  final String? cancelledBy;
  final String? mentorName;
  final String? traineeName;

  static const select =
      'id, mentorship_id, mentor_id, trainee_id, outlet_id, scheduled_at, duration_minutes, '
      'topic, note, status, requested_by, responded_at, response_note, cancelled_by, '
      'mentor:profiles!formal_trainings_mentor_id_fkey(full_name), '
      'trainee:profiles!formal_trainings_trainee_id_fkey(full_name)';

  factory FormalTraining.fromJson(Map<String, dynamic> j) => FormalTraining(
    id: j['id'] as String,
    mentorshipId: j['mentorship_id'] as String,
    mentorId: j['mentor_id'] as String,
    traineeId: j['trainee_id'] as String,
    outletId: j['outlet_id'] as String,
    scheduledAt: DateTime.parse(j['scheduled_at'] as String),
    durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 30,
    topic: j['topic'] as String,
    note: j['note'] as String?,
    status: FormalTrainingStatus.values.byName(j['status'] as String),
    requestedBy: j['requested_by'] as String,
    respondedAt: parseTs(j['responded_at']),
    responseNote: j['response_note'] as String?,
    cancelledBy: j['cancelled_by'] as String?,
    mentorName: (j['mentor'] as Map?)?['full_name'] as String?,
    traineeName: (j['trainee'] as Map?)?['full_name'] as String?,
  );

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));
  bool get isPast => endsAt.isBefore(DateTime.now());
  bool get isOpen => status == FormalTrainingStatus.requested || status == FormalTrainingStatus.approved;

  /// A request nobody answered before its start time.
  bool get expired => status == FormalTrainingStatus.requested && !scheduledAt.isAfter(DateTime.now());

  bool isParty(String uid) => uid == mentorId || uid == traineeId;

  /// The other person answers a request, never the one who sent it.
  bool canRespond(String uid) =>
      status == FormalTrainingStatus.requested && isParty(uid) && uid != requestedBy && !expired;

  bool canCancel(String uid) => isOpen && isParty(uid) && !isPast;

  String? otherName(String uid) => uid == mentorId ? traineeName : mentorName;
}

class FormalTrainingRepository {
  FormalTrainingRepository(this._db);
  final SupabaseClient _db;

  List<FormalTraining> _list(Object rows) =>
      (rows as List).map((r) => FormalTraining.fromJson(r as Map<String, dynamic>)).toList();

  /// All sessions of a mentorship: upcoming first (soonest on top), then past.
  Future<List<FormalTraining>> forMentorship(String mentorshipId) async {
    final rows = await _db
        .from('formal_trainings')
        .select(FormalTraining.select)
        .eq('mentorship_id', mentorshipId)
        .order('scheduled_at', ascending: true);
    final all = _list(rows);
    final upcoming = all.where((t) => !t.isPast).toList();
    final past = all.where((t) => t.isPast).toList().reversed;
    return [...upcoming, ...past];
  }

  /// Requests the other side sent to [uid] that still need an answer.
  Future<List<FormalTraining>> awaitingAnswer(String uid) async {
    final rows = await _db
        .from('formal_trainings')
        .select(FormalTraining.select)
        .or('mentor_id.eq.$uid,trainee_id.eq.$uid')
        .neq('requested_by', uid)
        .eq('status', 'requested')
        .gt('scheduled_at', DateTime.now().toUtc().toIso8601String())
        .order('scheduled_at', ascending: true);
    return _list(rows);
  }

  /// Approved sessions at an outlet that have not finished yet (for managers).
  Future<List<FormalTraining>> upcomingAtOutlet(String outletId) async {
    final from = DateTime.now().toUtc().subtract(const Duration(hours: 4));
    final rows = await _db
        .from('formal_trainings')
        .select(FormalTraining.select)
        .eq('outlet_id', outletId)
        .eq('status', 'approved')
        .gt('scheduled_at', from.toIso8601String())
        .order('scheduled_at', ascending: true);
    return _list(rows).where((t) => !t.isPast).toList();
  }

  Future<FormalTraining> byId(String id) async =>
      FormalTraining.fromJson(await _db.from('formal_trainings').select(FormalTraining.select).eq('id', id).single());

  /// The server checks the caller belongs to the mentorship and the time is free.
  Future<String> request(
    String mentorshipId, {
    required DateTime scheduledAt,
    required String topic,
    String? note,
    int durationMinutes = 30,
  }) async {
    final res = await _db.rpc(
      'request_formal_training',
      params: {
        'p_mentorship': mentorshipId,
        'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'p_topic': topic.trim(),
        'p_note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'p_duration_minutes': durationMinutes,
      },
    );
    return res as String;
  }

  Future<void> respond(String id, {required bool approve, String? note}) async {
    await _db.rpc(
      'respond_formal_training',
      params: {'p_training': id, 'p_approve': approve, 'p_note': (note ?? '').trim().isEmpty ? null : note!.trim()},
    );
  }

  Future<void> cancel(String id, {String? reason}) async {
    await _db.rpc(
      'cancel_formal_training',
      params: {'p_training': id, 'p_reason': (reason ?? '').trim().isEmpty ? null : reason!.trim()},
    );
  }
}

final formalTrainingRepositoryProvider = Provider((ref) => FormalTrainingRepository(userDb(ref)));

final formalTrainingsProvider = FutureProvider.family<List<FormalTraining>, String>(
  (ref, mentorshipId) => ref.watch(formalTrainingRepositoryProvider).forMentorship(mentorshipId),
);

final formalTrainingProvider = FutureProvider.family<FormalTraining, String>(
  (ref, id) => ref.watch(formalTrainingRepositoryProvider).byId(id),
);

final formalTrainingsAwaitingMeProvider = FutureProvider<List<FormalTraining>>((ref) async {
  final s = await ref.watch(sessionProvider.future);
  if (s == null) return [];
  return ref.watch(formalTrainingRepositoryProvider).awaitingAnswer(s.profile.id);
});

final outletFormalTrainingsProvider = FutureProvider.family<List<FormalTraining>, String>(
  (ref, outletId) => ref.watch(formalTrainingRepositoryProvider).upcomingAtOutlet(outletId),
);

/// Refresh every list a request, answer or cancellation can change.
void invalidateFormalTrainings(WidgetRef ref) {
  ref.invalidate(formalTrainingsProvider);
  ref.invalidate(formalTrainingProvider);
  ref.invalidate(formalTrainingsAwaitingMeProvider);
  ref.invalidate(outletFormalTrainingsProvider);
}
