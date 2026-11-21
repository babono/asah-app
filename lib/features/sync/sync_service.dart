import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/media/media_repository.dart';
import '../../core/offline/connectivity.dart';
import '../../core/offline/local_store.dart';
import '../../core/utils/errors.dart';
import '../checklists/checklist_repository.dart';
import '../checklists/draft_store.dart';
import '../checklists/models.dart';
import '../issues/issue_repository.dart';
import '../learning/learning_repository.dart';

/// Work saved on the phone and sent when there is a connection (PRD F7).
class OutboxJob {
  OutboxJob({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.failed = false,
    this.error,
  });

  final String id;
  final String type; // checklist_submit | complete_block
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  bool failed;
  String? error;

  String get label => (payload['label'] as String?) ?? type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'failed': failed,
        'error': error,
      };

  factory OutboxJob.fromJson(Map<String, dynamic> j) => OutboxJob(
        id: j['id'] as String,
        type: j['type'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['created_at'] as String),
        failed: (j['failed'] as bool?) ?? false,
        error: j['error'] as String?,
      );
}

enum JobOutcome { done, retryLater, failed }

class JobResult {
  const JobResult(this.outcome, [this.message, this.data]);
  final JobOutcome outcome;
  final String? message;
  final Map<String, dynamic>? data;
}

class SyncState {
  const SyncState({this.jobs = const [], this.running = false});
  final List<OutboxJob> jobs;
  final bool running;

  int get pending => jobs.where((j) => !j.failed).length;
  List<OutboxJob> get failed => jobs.where((j) => j.failed).toList();

  bool hasPendingSubmit(String runId) =>
      jobs.any((j) => j.type == 'checklist_submit' && j.payload['run_id'] == runId && !j.failed);
}

class SyncController extends Notifier<SyncState> {
  static const _key = 'outbox:jobs';
  static const _uuid = Uuid();

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  SyncState build() {
    final jobs = (_store.getList(_key) ?? [])
        .map((j) => OutboxJob.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    ref.listen(isOnlineProvider, (prev, next) {
      if (next.value == true && prev?.value != true) processAll();
    });
    return SyncState(jobs: jobs);
  }

  Future<void> _persist(List<OutboxJob> jobs) async {
    await _store.setJson(_key, jobs.map((j) => j.toJson()).toList());
    state = SyncState(jobs: List.of(jobs), running: state.running);
  }

  Future<OutboxJob> enqueue(String type, Map<String, dynamic> payload) async {
    final job = OutboxJob(id: _uuid.v4(), type: type, payload: payload, createdAt: DateTime.now());
    await _persist([...state.jobs, job]);
    return job;
  }

  Future<void> discard(String jobId) async {
    await _persist(state.jobs.where((j) => j.id != jobId).toList());
  }

  /// Runs one job now and reports how it went. Network failures keep the job
  /// queued; rule failures (outside the outlet, run already missed) mark it
  /// failed so the person can see why.
  Future<JobResult> run(String jobId) async {
    final job = state.jobs.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return const JobResult(JobOutcome.done);
    JobResult result;
    try {
      final data = await _execute(job);
      result = JobResult(JobOutcome.done, null, data);
    } catch (e) {
      result = isNetworkError(e)
          ? JobResult(JobOutcome.retryLater, friendlyError(e))
          : JobResult(JobOutcome.failed, friendlyError(e));
    }
    final jobs = List.of(state.jobs);
    switch (result.outcome) {
      case JobOutcome.done:
        jobs.removeWhere((j) => j.id == jobId);
      case JobOutcome.retryLater:
        job.error = result.message;
      case JobOutcome.failed:
        job
          ..failed = true
          ..error = result.message;
    }
    await _persist(jobs);
    return result;
  }

  Future<void> processAll() async {
    if (state.running) return;
    state = SyncState(jobs: state.jobs, running: true);
    try {
      for (final job in state.jobs.where((j) => !j.failed).toList()) {
        final r = await run(job.id);
        if (r.outcome == JobOutcome.retryLater) break; // still offline
      }
    } finally {
      state = SyncState(jobs: state.jobs, running: false);
      ref.invalidate(myRunsTodayProvider);
    }
  }

  Future<Map<String, dynamic>?> _execute(OutboxJob job) async {
    switch (job.type) {
      case 'checklist_submit':
        return _submitChecklist(job);
      case 'complete_block':
        await ref.read(learningRepositoryProvider).completeBlock(
              job.payload['assignment_id'] as String,
              job.payload['block_id'] as String,
            );
        return null;
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>> _submitChecklist(OutboxJob job) async {
    final p = job.payload;
    final runId = p['run_id'] as String;
    final outletId = p['outlet_id'] as String;
    final answers = (p['answers'] as Map).map(
      (k, v) => MapEntry(k as String, Answer.fromJson(Map<String, dynamic>.from(v as Map))),
    );
    final uploaded = Map<String, String>.from((p['uploaded'] as Map?) ?? {});
    final repo = ref.read(checklistRepositoryProvider);
    final media = ref.read(mediaRepositoryProvider);

    final responseIds = await repo.saveResponses(runId, answers, DateTime.parse(p['captured_at'] as String));

    // Photos: upload each once, remembering the media id in the job so a
    // retry after a dropped connection does not upload it again.
    for (final entry in answers.entries) {
      final responseId = responseIds[entry.key];
      if (responseId == null) continue;
      for (final path in entry.value.photoPaths) {
        var mediaId = uploaded[path];
        if (mediaId == null) {
          mediaId = await media.uploadPhoto(XFile(path), kind: 'checklist_photo', outletId: outletId);
          uploaded[path] = mediaId;
          p['uploaded'] = uploaded;
          await _persist(state.jobs);
        }
        await repo.attachPhoto(responseId, mediaId);
      }
    }

    final result = await repo.submit(runId, (p['lat'] as num?)?.toDouble(), (p['lng'] as num?)?.toDouble());

    await ref.read(checklistDraftStoreProvider).clear(runId);
    for (final path in uploaded.keys) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    // Everything that shows this run, or the issues it raised.
    ref.invalidate(runProvider(runId));
    ref.invalidate(myRunsTodayProvider);
    ref.invalidate(myAuditsProvider);
    ref.invalidate(outletRunsTodayProvider);
    if (result.failed > 0) ref.invalidate(issuesProvider);
    return {'failed': result.failed, 'total': result.total};
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
