import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../features/auth/sign_in_screen.dart';
import 'admin_shell.dart';
import 'pages/audit_log_page.dart';
import 'pages/checklist_builder_page.dart';
import 'pages/checklist_templates_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/issues_page.dart';
import 'pages/mentor_ratings_page.dart';
import 'pages/module_builder_page.dart';
import 'pages/modules_page.dart';
import 'pages/org_page.dart';
import 'pages/outlets_page.dart';
import 'pages/paths_page.dart';
import 'pages/roles_page.dart';
import 'pages/settings_page.dart';
import 'pages/users_page.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref.listen(currentUserIdProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, pageBuilder: (_, s) => NoTransitionPage(child: build(s)));

  return GoRouter(
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
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const Center(
          child: ClipRect(
            child: SizedBox(width: 440, height: 760, child: SignInScreen()),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          page('/', (_) => const DashboardPage()),
          page('/issues', (_) => const AdminIssuesPage()),
          page('/org', (_) => const OrgPage()),
          page('/users', (_) => const UsersPage()),
          page('/roles', (_) => const RolesPage()),
          page('/outlets', (_) => const OutletsPage()),
          page('/modules', (_) => const ModulesPage()),
          page('/modules/:id', (s) => ModuleBuilderPage(moduleId: s.pathParameters['id']!)),
          page('/paths', (_) => const PathsPage()),
          page('/ratings', (_) => const MentorRatingsPage()),
          page('/checklists', (_) => const ChecklistTemplatesPage()),
          page('/checklists/:id', (s) => ChecklistBuilderPage(templateId: s.pathParameters['id']!)),
          page('/audit-log', (_) => const AuditLogPage()),
          page('/settings', (_) => const SettingsPage()),
        ],
      ),
    ],
  );
});
