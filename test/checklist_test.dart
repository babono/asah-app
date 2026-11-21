import 'package:asah/features/checklists/models.dart';
import 'package:asah/features/notifications/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answer.fails mirrors app.compute_response_passed() so the warning shown
/// before submit matches the issue the server raises (PRD A4).
void main() {
  const yesNo = ChecklistItem(id: 'i1', sort: 1, label: 'Floor mopped', answerType: AnswerType.yesNo);
  const chiller = ChecklistItem(
      id: 'i2', sort: 2, label: 'Chiller', answerType: AnswerType.number, minValue: 1, maxValue: 5, unit: '°C');
  const toilet = ChecklistItem(
      id: 'i3', sort: 3, label: 'Toilet clean', answerType: AnswerType.yesNo, photoRule: PhotoRule.required);
  const infoOnly = ChecklistItem(id: 'i4', sort: 4, label: 'Music on', answerType: AnswerType.yesNo, failOnNo: false);

  test('"no" fails a yes/no item unless the template says otherwise', () {
    expect(Answer(yes: false).fails(yesNo), isTrue);
    expect(Answer(yes: true).fails(yesNo), isFalse);
    expect(Answer(yes: false).fails(infoOnly), isFalse);
  });

  test('numbers outside the allowed range fail', () {
    expect(Answer(number: 4).fails(chiller), isFalse);
    expect(Answer(number: 1).fails(chiller), isFalse);
    expect(Answer(number: 7).fails(chiller), isTrue);
    expect(Answer(number: 0.5).fails(chiller), isTrue);
  });

  test('a required photo is needed before the item counts as done', () {
    final a = Answer(yes: true);
    expect(a.isComplete(toilet), isFalse);
    a.photoPaths.add('/tmp/p.jpg');
    expect(a.isComplete(toilet), isTrue);
  });

  test('drafts round trip through JSON', () {
    final a = Answer(yes: true, number: 3.5, text: 'ok', photoPaths: ['/a.jpg']);
    final b = Answer.fromJson(a.toJson());
    expect(b.yes, isTrue);
    expect(b.number, 3.5);
    expect(b.photoPaths, ['/a.jpg']);
  });

  test('notifications open the screen they are about', () {
    expect(routeForNotification('issue_created', {'issue_id': 'x'}), '/issues/x');
    expect(routeForNotification('checklist_missed', {'run_id': 'r'}), '/checklist/r');
    expect(routeForNotification('practical_to_score', {'submission_id': 's'}), '/mentor/score/s');
    expect(routeForNotification('checkin_due', {'mentorship_id': 'm'}), '/mentor/checkin/m');
    expect(routeForNotification('module_assigned', {}), '/learn');
  });
}
