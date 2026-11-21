import '../../core/utils/format.dart';

enum AnswerType { yesNo, number, text, photo }

enum PhotoRule { none, optional, required }

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.sort,
    required this.label,
    this.helpText,
    required this.answerType,
    this.photoRule = PhotoRule.none,
    this.minValue,
    this.maxValue,
    this.unit,
    this.failOnNo = true,
  });

  final String id;
  final int sort;
  final String label;
  final String? helpText;
  final AnswerType answerType;
  final PhotoRule photoRule;
  final num? minValue;
  final num? maxValue;
  final String? unit;
  final bool failOnNo;

  static const select = 'id, sort, label, help_text, answer_type, photo_rule, min_value, max_value, unit, fail_on_no';

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        sort: j['sort'] as int,
        label: j['label'] as String,
        helpText: j['help_text'] as String?,
        answerType: switch (j['answer_type']) {
          'number' => AnswerType.number,
          'text' => AnswerType.text,
          'photo' => AnswerType.photo,
          _ => AnswerType.yesNo,
        },
        photoRule: switch (j['photo_rule']) {
          'required' => PhotoRule.required,
          'optional' => PhotoRule.optional,
          _ => PhotoRule.none,
        },
        minValue: asNum(j['min_value']),
        maxValue: asNum(j['max_value']),
        unit: j['unit'] as String?,
        failOnNo: (j['fail_on_no'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sort': sort,
        'label': label,
        'help_text': helpText,
        'answer_type': switch (answerType) {
          AnswerType.yesNo => 'yes_no',
          AnswerType.number => 'number',
          AnswerType.text => 'text',
          AnswerType.photo => 'photo',
        },
        'photo_rule': photoRule.name,
        'min_value': minValue,
        'max_value': maxValue,
        'unit': unit,
        'fail_on_no': failOnNo,
      };

  bool get needsPhoto => photoRule == PhotoRule.required || answerType == AnswerType.photo;
  bool get allowsPhoto => photoRule != PhotoRule.none || answerType == AnswerType.photo;
}

class ChecklistRun {
  const ChecklistRun({
    required this.id,
    required this.templateVersionId,
    required this.outletId,
    required this.shiftDate,
    required this.shift,
    required this.dueAt,
    required this.status,
    required this.templateName,
    required this.templateId,
    this.kind = 'routine',
    this.submittedAt,
    this.submittedBy,
    this.conductedBy,
    this.itemCount,
    this.failedCount,
    this.compliancePct,
    this.withinGeofence,
  });

  final String id;
  final String templateVersionId;
  final String templateId;
  final String outletId;
  final DateTime shiftDate;
  final String shift; // opening | mid | closing | other
  final DateTime dueAt;
  final String status; // pending | in_progress | submitted | missed
  final String templateName;
  final String kind; // routine | audit
  final DateTime? submittedAt;
  final String? submittedBy;
  final String? conductedBy;
  final int? itemCount;
  final int? failedCount;
  final num? compliancePct;
  final bool? withinGeofence;

  static const select = 'id, template_version_id, outlet_id, shift_date, shift, due_at, status, submitted_at, '
      'submitted_by, conducted_by, item_count, failed_count, compliance_pct, within_geofence, '
      'checklist_template_versions(template_id, checklist_templates(name, kind))';

  factory ChecklistRun.fromJson(Map<String, dynamic> j) {
    final v = j['checklist_template_versions'] as Map<String, dynamic>?;
    final t = v?['checklist_templates'] as Map<String, dynamic>?;
    return ChecklistRun(
      id: j['id'] as String,
      templateVersionId: j['template_version_id'] as String,
      templateId: (v?['template_id'] as String?) ?? '',
      outletId: j['outlet_id'] as String,
      shiftDate: DateTime.parse(j['shift_date'] as String),
      shift: j['shift'] as String,
      dueAt: DateTime.parse(j['due_at'] as String),
      status: j['status'] as String,
      templateName: (t?['name'] as String?) ?? '',
      kind: (t?['kind'] as String?) ?? 'routine',
      submittedAt: parseTs(j['submitted_at']),
      submittedBy: j['submitted_by'] as String?,
      conductedBy: j['conducted_by'] as String?,
      itemCount: j['item_count'] as int?,
      failedCount: j['failed_count'] as int?,
      compliancePct: asNum(j['compliance_pct']),
      withinGeofence: j['within_geofence'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'template_version_id': templateVersionId,
        'outlet_id': outletId,
        'shift_date': Fmt.isoDate(shiftDate),
        'shift': shift,
        'due_at': dueAt.toUtc().toIso8601String(),
        'status': status,
        'submitted_at': submittedAt?.toUtc().toIso8601String(),
        'submitted_by': submittedBy,
        'conducted_by': conductedBy,
        'item_count': itemCount,
        'failed_count': failedCount,
        'compliance_pct': compliancePct,
        'within_geofence': withinGeofence,
        'checklist_template_versions': {
          'template_id': templateId,
          'checklist_templates': {'name': templateName, 'kind': kind},
        },
      };

  bool get isOpen => status == 'pending' || status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isMissed => status == 'missed';
  bool get isAudit => kind == 'audit';

  /// Done after the due time, or still open past it.
  bool get isLate =>
      isMissed || (isOpen && DateTime.now().isAfter(dueAt)) || (submittedAt != null && submittedAt!.isAfter(dueAt));

  ChecklistRun copyWith({String? status}) => ChecklistRun.fromJson({...toJson(), 'status': status ?? this.status});
}

/// One answer while filling. Photos are local file paths until synced.
class Answer {
  Answer({this.yes, this.number, this.text, List<String>? photoPaths}) : photoPaths = photoPaths ?? [];

  bool? yes;
  num? number;
  String? text;
  List<String> photoPaths;

  bool hasValue(ChecklistItem item) => switch (item.answerType) {
        AnswerType.yesNo => yes != null,
        AnswerType.number => number != null,
        AnswerType.text => (text ?? '').trim().isNotEmpty,
        AnswerType.photo => photoPaths.isNotEmpty,
      };

  bool isComplete(ChecklistItem item) => hasValue(item) && (!item.needsPhoto || photoPaths.isNotEmpty);

  /// Same rule as app.compute_response_passed() on the server.
  bool fails(ChecklistItem item) => switch (item.answerType) {
        AnswerType.yesNo => item.failOnNo && yes == false,
        AnswerType.number => number != null &&
            ((item.minValue != null && number! < item.minValue!) || (item.maxValue != null && number! > item.maxValue!)),
        _ => false,
      };

  Map<String, dynamic> toJson() => {'yes': yes, 'number': number, 'text': text, 'photos': photoPaths};

  factory Answer.fromJson(Map<String, dynamic> j) => Answer(
        yes: j['yes'] as bool?,
        number: j['number'] as num?,
        text: j['text'] as String?,
        photoPaths: (j['photos'] as List?)?.cast<String>() ?? [],
      );
}

/// A submitted answer, read back for managers.
class ChecklistResponse {
  const ChecklistResponse({
    required this.id,
    required this.itemId,
    this.valueBool,
    this.valueNumber,
    this.valueText,
    required this.passed,
    required this.answeredBy,
    required this.answeredAt,
    this.photoMediaIds = const [],
  });

  final String id;
  final String itemId;
  final bool? valueBool;
  final num? valueNumber;
  final String? valueText;
  final bool passed;
  final String answeredBy;
  final DateTime answeredAt;
  final List<String> photoMediaIds;

  factory ChecklistResponse.fromJson(Map<String, dynamic> j) => ChecklistResponse(
        id: j['id'] as String,
        itemId: j['item_id'] as String,
        valueBool: j['value_bool'] as bool?,
        valueNumber: asNum(j['value_number']),
        valueText: j['value_text'] as String?,
        passed: j['passed'] as bool,
        answeredBy: j['answered_by'] as String,
        answeredAt: DateTime.parse(j['answered_at'] as String),
        photoMediaIds: ((j['checklist_response_photos'] as List?) ?? [])
            .map((p) => (p as Map)['media_file_id'] as String)
            .toList(),
      );
}

/// Template summary for the Today card ("12 items · 3 need a photo").
class TemplateStats {
  const TemplateStats(this.items, this.photos);
  final int items;
  final int photos;
}
