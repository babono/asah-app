import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/checklists/checklist_fill_screen.dart';
import '../features/checklists/run_detail_screen.dart';
import '../features/issues/issue_detail_screen.dart';
import '../features/issues/raise_issue_screen.dart';
import '../features/learning/learn_screen.dart';
import '../features/learning/module_screen.dart';
import '../features/learning/practical_record_screen.dart';
import '../features/learning/quiz_screen.dart';
import '../features/mentorship/checkin_screen.dart';
import '../features/mentorship/formal_training_screens.dart';
import '../features/mentorship/my_mentor_screen.dart';
import '../features/mentorship/practical_score_screen.dart';
import '../features/mentorship/rate_mentor_screen.dart';
import '../features/mentorship/trainee_detail_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/certificates_screen.dart';
import '../features/team/staff_detail_screen.dart';
import '../features/today/manager_today_screen.dart';
import 'home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen(currentUserIdProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  String p(GoRouterState s, String name) => s.pathParameters[name]!;

  // Screens opened from a push tap can build before the session loads.
  GoRoute route(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, builder: (_, s) => SessionGate(child: build(s)));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final signedIn = ref.read(currentUserIdProvider) != null;
      final atSignIn = state.matchedLocation == '/sign-in';
      if (!signedIn) return atSignIn ? null : '/sign-in';
      if (atSignIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      route('/learn', (_) => const LearnScreen(standalone: true)),
      route('/checklist/:runId', (s) => ChecklistFillScreen(runId: p(s, 'runId'))),
      route('/run/:runId', (s) => RunDetailScreen(runId: p(s, 'runId'))),
      route('/module/:id', (s) => ModuleScreen(assignmentId: p(s, 'id'))),
      route('/module/:id/quiz', (s) => QuizScreen(assignmentId: p(s, 'id'))),
      route('/module/:id/practical', (s) => PracticalRecordScreen(assignmentId: p(s, 'id'))),
      route('/issues/new', (_) => const RaiseIssueScreen()),
      route('/issues/:id', (s) => IssueDetailScreen(issueId: p(s, 'id'))),
      route('/mentor/trainee/:id', (s) => TraineeDetailScreen(mentorshipId: p(s, 'id'))),
      route('/mentor/score/:id', (s) => PracticalScoreScreen(submissionId: p(s, 'id'))),
      route('/mentor/checkin/:id', (s) => CheckinScreen(mentorshipId: p(s, 'id'))),
      route('/formal-training/new/:mentorshipId',
          (s) => RequestFormalTrainingScreen(mentorshipId: p(s, 'mentorshipId'))),
      route('/formal-training/:id', (s) => FormalTrainingDetailScreen(trainingId: p(s, 'id'))),
      route('/my-mentor/:id', (s) => MyMentorScreen(mentorshipId: p(s, 'id'))),
      route('/rate-mentor/:id', (s) => RateMentorScreen(mentorshipId: p(s, 'id'))),
      route('/team/signoffs', (_) => const SignoffsScreen()),
      route('/team/:userId', (s) => StaffDetailScreen(userId: p(s, 'userId'))),
      route('/outlet/:id', (s) => ManagerTodayScreen(outletId: p(s, 'id'))),
      route('/notifications', (_) => const NotificationsScreen()),
      route('/certificates', (_) => const CertificatesScreen()),
    ],
  );
});
