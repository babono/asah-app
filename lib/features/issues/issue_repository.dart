import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/media/media_repository.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/format.dart';
import '../session/models.dart';

class Issue {
  const Issue({
    required this.id,
    required this.outletId,
    required this.source,
    this.runId,
    this.responseId,
    required this.title,
    this.description,
    required this.severity,
    required this.status,
    this.raisedBy,
    this.assignedTo,
    required this.dueAt,
    this.fixedBy,
    this.fixedAt,
    this.closedBy,
    this.closedAt,
    this.escalatedAt,
    required this.createdAt,
    this.runName,
  });

  final String id;
  final String outletId;
  final String source; // checklist | audit | manual
  final String? runId;
  final String? responseId;
  final String title;
  final String? description;
  final String severity; // low | medium | high
  final String status; // open | fixed | closed
  final String? raisedBy;
  final String? assignedTo;
  final DateTime dueAt;
  final String? fixedBy;
  final DateTime? fixedAt;
  final String? closedBy;
  final DateTime? closedAt;
  final DateTime? escalatedAt;
  final DateTime createdAt;
  final String? runName;

  static const select = 'id, outlet_id, source, run_id, response_id, title, description, severity, status, raised_by, '
      'assigned_to, due_at, fixed_by, fixed_at, closed_by, closed_at, escalated_at, created_at, '
      'checklist_runs(checklist_template_versions(checklist_templates(name)))';

  factory Issue.fromJson(Map<String, dynamic> j) {
    final run = j['checklist_runs'] as Map<String, dynamic>?;
    final runName = ((run?['checklist_template_versions'] as Map?)?['checklist_templates'] as Map?)?['name'] as String?;
    return Issue(
      id: j['id'] as String,
      outletId: j['outlet_id'] as String,
      source: j['source'] as String,
      runId: j['run_id'] as String?,
      responseId: j['response_id'] as String?,
      title: j['title'] as String,
      description: j['description'] as String?,
      severity: j['severity'] as String,
      status: j['status'] as String,
      raisedBy: j['raised_by'] as String?,
      assignedTo: j['assigned_to'] as String?,
      dueAt: DateTime.parse(j['due_at'] as String),
      fixedBy: j['fixed_by'] as String?,
      fixedAt: parseTs(j['fixed_at']),
      closedBy: j['closed_by'] as String?,
      closedAt: parseTs(j['closed_at']),
      escalatedAt: parseTs(j['escalated_at']),
      createdAt: DateTime.parse(j['created_at'] as String),
      runName: runName,
    );
  }

  bool get isOpen => status == 'open';
  bool get isFixed => status == 'fixed';
  bool get isClosed => status == 'closed';
  bool get isLate => isOpen && dueAt.isBefore(DateTime.now());
}

class IssueEvent {
  const IssueEvent({required this.id, this.actorId, required this.type, this.note, this.mediaFileId, required this.createdAt});
  final String id;
  final String? actorId;
  final String type; // created | assigned | fixed | accepted | reopened | escalated | commented
  final String? note;
  final String? mediaFileId;
  final DateTime createdAt;

  factory IssueEvent.fromJson(Map<String, dynamic> j) => IssueEvent(
        id: j['id'] as String,
        actorId: j['actor_id'] as String?,
        type: j['type'] as String,
        note: j['note'] as String?,
        mediaFileId: j['media_file_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

enum IssueFilter { open, checkFix, closed }

/// SLA hours per severity for issues raised by hand.
int slaHoursFor(String severity) => switch (severity) { 'high' => 4, 'low' => 72, _ => 24 };

class IssueRepository {
  IssueRepository(this._db, this._media);
  final SupabaseClient _db;
  final MediaRepository _media;

  Future<List<Issue>> list({IssueFilter filter = IssueFilter.open, String? outletId, int limit = 100}) async {
    var q = _db.from('issues').select(Issue.select);
    q = switch (filter) {
      IssueFilter.open => q.eq('status', 'open'),
      IssueFilter.checkFix => q.eq('status', 'fixed'),
      IssueFilter.closed => q.eq('status', 'closed'),
    };
    if (outletId != null) q = q.eq('outlet_id', outletId);
    final rows = filter == IssueFilter.closed
        ? await q.order('closed_at', ascending: false).limit(limit)
        : await q.order('due_at', ascending: true).limit(limit);
    return (rows as List).map((r) => Issue.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Open and waiting-for-check issues at an outlet (manager Today, S1).
  Future<List<Issue>> active(String outletId) async {
    final rows = await _db
        .from('issues')
        .select(Issue.select)
        .eq('outlet_id', outletId)
        .neq('status', 'closed')
        .order('due_at', ascending: true);
    return (rows as List).map((r) => Issue.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Issue>> activeIn(List<String> outletIds) async {
    if (outletIds.isEmpty) return [];
    final rows = await _db
        .from('issues')
        .select(Issue.select)
        .inFilter('outlet_id', outletIds)
        .neq('status', 'closed')
        .order('due_at', ascending: true);
    return (rows as List).map((r) => Issue.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Issue> byId(String id) async =>
      Issue.fromJson(await _db.from('issues').select(Issue.select).eq('id', id).single());

  Future<List<IssueEvent>> events(String issueId) async {
    final rows = await _db
        .from('issue_events')
        .select('id, actor_id, type, note, media_file_id, created_at')
        .eq('issue_id', issueId)
        .order('created_at', ascending: true);
    return (rows as List).map((r) => IssueEvent.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<String>> responsePhotos(String responseId) async {
    final rows = await _db.from('checklist_response_photos').select('media_file_id').eq('response_id', responseId);
    return (rows as List).map((r) => r['media_file_id'] as String).toList();
  }

  Future<String> raise({
    required String outletId,
    required String title,
    String? description,
    required String severity,
    XFile? photo,
  }) async {
    String? mediaId;
    if (photo != null) mediaId = await _media.uploadPhoto(photo, kind: 'issue_photo', outletId: outletId);
    final id = await _db.rpc('raise_issue', params: {
      'p_outlet': outletId,
      'p_title': title,
      'p_description': description,
      'p_severity': severity,
      'p_sla_hours': slaHoursFor(severity),
      'p_media': mediaId,
    });
    return id as String;
  }

  Future<void> assign(String issueId, String assigneeId) =>
      _db.rpc('assign_issue', params: {'p_issue': issueId, 'p_assignee': assigneeId});

  /// Owner adds a proof photo when fixed (S1).
  Future<void> fix(Issue issue, {String? note, XFile? proof}) async {
    String? mediaId;
    if (proof != null) mediaId = await _media.uploadPhoto(proof, kind: 'issue_photo', outletId: issue.outletId);
    await _db.rpc('fix_issue', params: {'p_issue': issue.id, 'p_note': note, 'p_proof_media': mediaId});
  }

  /// Accept closes it; reopen needs a reason (S2). Never your own fix (R7).
  Future<void> verify(String issueId, {required bool accept, String? note}) =>
      _db.rpc('verify_issue', params: {'p_issue': issueId, 'p_accept': accept, 'p_note': note});

  Future<void> comment(String issueId, String note) async {
    await _db.from('issue_events').insert({
      'issue_id': issueId,
      'actor_id': _db.auth.currentUser!.id,
      'type': 'commented',
      'note': note,
    });
  }

  /// Active staff at an outlet (assign an issue, pick a mentor).
  Future<List<Profile>> outletStaff(String outletId) async {
    final rows = await _db
        .from('profiles')
        .select(Profile.select)
        .eq('outlet_id', outletId)
        .eq('status', 'active')
        .order('full_name', ascending: true);
    return (rows as List).map((r) => Profile.fromJson(r as Map<String, dynamic>)).toList();
  }
}

final issueRepositoryProvider =
    Provider((ref) => IssueRepository(userDb(ref), ref.watch(mediaRepositoryProvider)));

final issuesProvider = FutureProvider.family<List<Issue>, IssueFilter>((ref, filter) {
  return ref.watch(issueRepositoryProvider).list(filter: filter);
});

final issueProvider = FutureProvider.family<Issue, String>((ref, id) => ref.watch(issueRepositoryProvider).byId(id));

final issueEventsProvider =
    FutureProvider.family<List<IssueEvent>, String>((ref, id) => ref.watch(issueRepositoryProvider).events(id));

final outletIssuesProvider =
    FutureProvider.family<List<Issue>, String>((ref, outletId) => ref.watch(issueRepositoryProvider).active(outletId));

final outletStaffProvider =
    FutureProvider.family<List<Profile>, String>((ref, outletId) => ref.watch(issueRepositoryProvider).outletStaff(outletId));

void invalidateIssues(WidgetRef ref, {String? issueId, String? outletId}) {
  for (final f in IssueFilter.values) {
    ref.invalidate(issuesProvider(f));
  }
  if (issueId != null) {
    ref.invalidate(issueProvider(issueId));
    ref.invalidate(issueEventsProvider(issueId));
  }
  if (outletId != null) ref.invalidate(outletIssuesProvider(outletId));
}
