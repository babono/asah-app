import 'package:asah/features/mentorship/formal_training_repository.dart';
import 'package:asah/features/notifications/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const mentor = 'mentor-1';
const trainee = 'trainee-1';
const manager = 'manager-1';

FormalTraining training({
  String status = 'requested',
  String requestedBy = trainee,
  Duration startsIn = const Duration(days: 1),
}) =>
    FormalTraining.fromJson({
      'id': 'ft-1',
      'mentorship_id': 'ms-1',
      'mentor_id': mentor,
      'trainee_id': trainee,
      'outlet_id': 'outlet-1',
      'scheduled_at': DateTime.now().add(startsIn).toUtc().toIso8601String(),
      'duration_minutes': 30,
      'topic': 'Grill station',
      'status': status,
      'requested_by': requestedBy,
      'mentor': {'full_name': 'Komang'},
      'trainee': {'full_name': 'Putu'},
    });

void main() {
  test('only the other side answers a request', () {
    final t = training();
    expect(t.canRespond(mentor), isTrue);
    expect(t.canRespond(trainee), isFalse);
    expect(t.canRespond(manager), isFalse);
    expect(training(requestedBy: mentor).canRespond(trainee), isTrue);
  });

  test('a request past its start time has expired and cannot be answered', () {
    final t = training(startsIn: const Duration(minutes: -5));
    expect(t.expired, isTrue);
    expect(t.canRespond(mentor), isFalse);
  });

  test('either side cancels an open session, managers cannot', () {
    final t = training(status: 'approved');
    expect(t.canCancel(mentor), isTrue);
    expect(t.canCancel(trainee), isTrue);
    expect(t.canCancel(manager), isFalse);
    expect(training(status: 'declined').canCancel(mentor), isFalse);
    expect(training(status: 'approved', startsIn: const Duration(hours: -1)).canCancel(mentor), isFalse);
  });

  test('defaults to 30 minutes and names the other person', () {
    final t = training();
    expect(t.endsAt.difference(t.scheduledAt), const Duration(minutes: 30));
    expect(t.otherName(mentor), 'Putu');
    expect(t.otherName(trainee), 'Komang');
  });

  test('formal training notifications open the session, not the check-in', () {
    expect(
      routeForNotification('formal_training_requested', {'formal_training_id': 'ft-1', 'mentorship_id': 'ms-1'}),
      '/formal-training/ft-1',
    );
  });
}
