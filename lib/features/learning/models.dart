import '../../core/utils/format.dart';

class Assignment {
  Assignment({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.moduleVersionId,
    required this.source,
    this.pathId,
    required this.assignedAt,
    this.dueAt,
    required this.status,
    this.completedAt,
    required this.title,
    this.summary,
    required this.category,
    this.estimatedMinutes,
    this.prerequisiteModuleId,
    this.blocksTotal = 0,
    this.blocksDone = 0,
    this.pathSort,
    this.mandatory = true,
    this.dueDays,
  });

  final String id;
  final String userId;
  final String moduleId;
  final String moduleVersionId;
  final String source; // path | manual | refresher | retraining
  final String? pathId;
  final DateTime assignedAt;
  final DateTime? dueAt;
  final String status; // not_started | in_progress | completed
  final DateTime? completedAt;
  final String title;
  final String? summary;
  final String category;
  final int? estimatedMinutes;
  final String? prerequisiteModuleId;
  int blocksTotal;
  int blocksDone;
  int? pathSort;
  bool mandatory;
  int? dueDays;

  static const select = 'id, user_id, module_id, module_version_id, source, path_id, assigned_at, due_at, status, '
      'completed_at, module_versions(title, summary, estimated_minutes, prerequisite_module_id), modules(category)';

  factory Assignment.fromJson(Map<String, dynamic> j) {
    final v = j['module_versions'] as Map<String, dynamic>? ?? {};
    return Assignment(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      moduleId: j['module_id'] as String,
      moduleVersionId: j['module_version_id'] as String,
      source: j['source'] as String,
      pathId: j['path_id'] as String?,
      assignedAt: DateTime.parse(j['assigned_at'] as String),
      dueAt: parseTs(j['due_at']),
      status: j['status'] as String,
      completedAt: parseTs(j['completed_at']),
      title: (v['title'] as String?) ?? '',
      summary: v['summary'] as String?,
      category: ((j['modules'] as Map?)?['category'] as String?) ?? '',
      estimatedMinutes: v['estimated_minutes'] as int?,
      prerequisiteModuleId: v['prerequisite_module_id'] as String?,
      blocksTotal: (j['_blocks_total'] as int?) ?? 0,
      blocksDone: (j['_blocks_done'] as int?) ?? 0,
      pathSort: j['_path_sort'] as int?,
      mandatory: (j['_mandatory'] as bool?) ?? true,
      dueDays: j['_due_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'module_id': moduleId,
        'module_version_id': moduleVersionId,
        'source': source,
        'path_id': pathId,
        'assigned_at': assignedAt.toUtc().toIso8601String(),
        'due_at': dueAt?.toUtc().toIso8601String(),
        'status': status,
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'module_versions': {
          'title': title,
          'summary': summary,
          'estimated_minutes': estimatedMinutes,
          'prerequisite_module_id': prerequisiteModuleId,
        },
        'modules': {'category': category},
        '_blocks_total': blocksTotal,
        '_blocks_done': blocksDone,
        '_path_sort': pathSort,
        '_mandatory': mandatory,
        '_due_days': dueDays,
      };

  bool get isCompleted => status == 'completed';
  bool get isOverdue => !isCompleted && dueAt != null && dueAt!.isBefore(DateTime.now());
  bool get isPathModule => source == 'path';
  double get contentProgress => blocksTotal == 0 ? (isCompleted ? 1 : 0) : blocksDone / blocksTotal;
}

class ContentBlock {
  const ContentBlock({
    required this.id,
    required this.sort,
    required this.type,
    this.title,
    this.body,
    this.mediaFileId,
    this.durationSeconds,
  });

  final String id;
  final int sort;
  final String type; // video | sop_card | document
  final String? title;
  final String? body;
  final String? mediaFileId;
  final int? durationSeconds;

  factory ContentBlock.fromJson(Map<String, dynamic> j) => ContentBlock(
        id: j['id'] as String,
        sort: j['sort'] as int,
        type: j['type'] as String,
        title: j['title'] as String?,
        body: j['body'] as String?,
        mediaFileId: j['media_file_id'] as String?,
        durationSeconds: (j['media_files'] as Map?)?['duration_seconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sort': sort,
        'type': type,
        'title': title,
        'body': body,
        'media_file_id': mediaFileId,
        'media_files': {'duration_seconds': durationSeconds},
      };
}

class Quiz {
  const Quiz({required this.id, required this.passMarkPct, this.maxAttempts, this.timeLimitSeconds});
  final String id;
  final int passMarkPct;
  final int? maxAttempts;
  final int? timeLimitSeconds;

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        id: j['id'] as String,
        passMarkPct: j['pass_mark_pct'] as int,
        maxAttempts: j['max_attempts'] as int?,
        timeLimitSeconds: j['time_limit_seconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pass_mark_pct': passMarkPct,
        'max_attempts': maxAttempts,
        'time_limit_seconds': timeLimitSeconds,
      };
}

class QuizAttempt {
  const QuizAttempt({required this.id, this.scorePct, this.passed, this.submittedAt, required this.startedAt});
  final String id;
  final num? scorePct;
  final bool? passed;
  final DateTime? submittedAt;
  final DateTime startedAt;

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        id: j['id'] as String,
        scorePct: asNum(j['score_pct']),
        passed: j['passed'] as bool?,
        submittedAt: parseTs(j['submitted_at']),
        startedAt: DateTime.parse(j['started_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'score_pct': scorePct,
        'passed': passed,
        'submitted_at': submittedAt?.toUtc().toIso8601String(),
        'started_at': startedAt.toUtc().toIso8601String(),
      };
}

class RubricCriterion {
  const RubricCriterion({required this.id, required this.title, this.description, required this.sort});
  final String id;
  final String title;
  final String? description;
  final int sort;

  factory RubricCriterion.fromJson(Map<String, dynamic> j) => RubricCriterion(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        sort: (j['sort'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'sort': sort};
}

class PracticalScore {
  const PracticalScore(this.criterionId, this.result, this.note);
  final String criterionId;
  final String result; // pass | redo
  final String? note;
}

class PracticalSubmission {
  const PracticalSubmission({
    required this.id,
    required this.assignmentId,
    required this.userId,
    required this.mediaFileId,
    required this.submittedAt,
    required this.status,
    this.scoredBy,
    this.scoredAt,
    this.feedback,
    this.scores = const [],
    this.moduleTitle,
    this.moduleVersionId,
  });

  final String id;
  final String assignmentId;
  final String userId;
  final String mediaFileId;
  final DateTime submittedAt;
  final String status; // pending | passed | redo
  final String? scoredBy;
  final DateTime? scoredAt;
  final String? feedback;
  final List<PracticalScore> scores;
  final String? moduleTitle;
  final String? moduleVersionId;

  static const select = 'id, assignment_id, user_id, media_file_id, submitted_at, status, scored_by, scored_at, '
      'feedback, practical_scores(criterion_id, result, note), '
      'module_assignments(module_version_id, module_versions(title))';

  factory PracticalSubmission.fromJson(Map<String, dynamic> j) {
    final a = j['module_assignments'] as Map<String, dynamic>?;
    return PracticalSubmission(
      id: j['id'] as String,
      assignmentId: j['assignment_id'] as String,
      userId: j['user_id'] as String,
      mediaFileId: j['media_file_id'] as String,
      submittedAt: DateTime.parse(j['submitted_at'] as String),
      status: j['status'] as String,
      scoredBy: j['scored_by'] as String?,
      scoredAt: parseTs(j['scored_at']),
      feedback: j['feedback'] as String?,
      scores: ((j['practical_scores'] as List?) ?? [])
          .map((s) => PracticalScore(s['criterion_id'] as String, s['result'] as String, s['note'] as String?))
          .toList(),
      moduleVersionId: a?['module_version_id'] as String?,
      moduleTitle: (a?['module_versions'] as Map?)?['title'] as String?,
    );
  }
}

class ModuleDetail {
  ModuleDetail({
    required this.assignment,
    required this.blocks,
    required this.completedBlockIds,
    this.quiz,
    this.questionCount = 0,
    required this.attempts,
    required this.rubric,
    required this.submissions,
    this.positionInPath,
    this.pathLength,
    this.pathName,
    this.certificateValidDays,
  });

  final Assignment assignment;
  final List<ContentBlock> blocks;
  final Set<String> completedBlockIds;
  final Quiz? quiz;
  final int questionCount;
  final List<QuizAttempt> attempts;
  final List<RubricCriterion> rubric;
  final List<PracticalSubmission> submissions;
  final int? positionInPath;
  final int? pathLength;
  final String? pathName;
  final int? certificateValidDays;

  bool get contentDone => blocks.every((b) => completedBlockIds.contains(b.id));
  bool get quizPassed => attempts.any((a) => a.passed == true);
  int get attemptsUsed => attempts.length;
  int? get attemptsLeft => quiz?.maxAttempts == null ? null : (quiz!.maxAttempts! - attemptsUsed).clamp(0, 999);
  QuizAttempt? get lastAttempt => attempts.where((a) => a.submittedAt != null).firstOrNull;
  PracticalSubmission? get lastSubmission => submissions.firstOrNull;
  bool get practicalPassed => submissions.any((s) => s.status == 'passed');
  bool get practicalPending => submissions.any((s) => s.status == 'pending');
}

/// Question served by start_quiz_attempt(), without the correct answer.
class QuizQuestion {
  const QuizQuestion(this.id, this.prompt, this.options);
  final String id;
  final String prompt;
  final List<({String id, String label})> options;
}

class QuizSession {
  const QuizSession(this.attemptId, this.questions, this.timeLimitSeconds);
  final String attemptId;
  final List<QuizQuestion> questions;
  final int? timeLimitSeconds;
}

class Certificate {
  const Certificate({required this.id, required this.title, required this.issuedAt, this.expiresAt});
  final String id;
  final String title;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  bool get expired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get expiringSoon =>
      !expired && expiresAt != null && expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)));
}

/// Progress summary for a person (mentor and manager views).
class TrainingSummary {
  const TrainingSummary({
    required this.assigned,
    required this.completed,
    required this.overdue,
    this.lastQuizPct,
    this.failedQuizTwice = false,
  });
  final int assigned;
  final int completed;
  final int overdue;
  final num? lastQuizPct;
  final bool failedQuizTwice;

  double get progress => assigned == 0 ? 0 : completed / assigned;
  bool get behind => overdue > 0 || failedQuizTwice;
}
