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
      GoRoute(path: '/learn', builder: (_, _) => const LearnScreen(standalone: true)),
      GoRoute(path: '/checklist/:runId', builder: (_, s) => ChecklistFillScreen(runId: p(s, 'runId'))),
      GoRoute(path: '/run/:runId', builder: (_, s) => RunDetailScreen(runId: p(s, 'runId'))),
      GoRoute(path: '/module/:id', builder: (_, s) => ModuleScreen(assignmentId: p(s, 'id'))),
      GoRoute(path: '/module/:id/quiz', builder: (_, s) => QuizScreen(assignmentId: p(s, 'id'))),
      GoRoute(path: '/module/:id/practical', builder: (_, s) => PracticalRecordScreen(assignmentId: p(s, 'id'))),
      GoRoute(path: '/issues/new', builder: (_, _) => const RaiseIssueScreen()),
      GoRoute(path: '/issues/:id', builder: (_, s) => IssueDetailScreen(issueId: p(s, 'id'))),
      GoRoute(path: '/mentor/trainee/:id', builder: (_, s) => TraineeDetailScreen(mentorshipId: p(s, 'id'))),
      GoRoute(path: '/mentor/score/:id', builder: (_, s) => PracticalScoreScreen(submissionId: p(s, 'id'))),
      GoRoute(path: '/mentor/checkin/:id', builder: (_, s) => CheckinScreen(mentorshipId: p(s, 'id'))),
      GoRoute(path: '/my-mentor/:id', builder: (_, s) => MyMentorScreen(mentorshipId: p(s, 'id'))),
      GoRoute(path: '/rate-mentor/:id', builder: (_, s) => RateMentorScreen(mentorshipId: p(s, 'id'))),
      GoRoute(path: '/team/signoffs', builder: (_, _) => const SignoffsScreen()),
      GoRoute(path: '/team/:userId', builder: (_, s) => StaffDetailScreen(userId: p(s, 'userId'))),
      GoRoute(path: '/outlet/:id', builder: (_, s) => ManagerTodayScreen(outletId: p(s, 'id'))),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/certificates', builder: (_, _) => const CertificatesScreen()),
    ],
  );
});
