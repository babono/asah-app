import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/l10n/locale_controller.dart';
import '../core/offline/local_store.dart';
import '../core/supabase/supabase_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/widgets.dart';
import '../features/area/area_screen.dart';
import '../features/area/audits_screen.dart';
import '../features/issues/issues_screen.dart';
import '../features/learning/learn_screen.dart';
import '../features/mentorship/mentor_screen.dart';
import '../features/profile/me_screen.dart';
import '../features/session/models.dart';
import '../features/session/session_provider.dart';
import '../features/sync/sync_service.dart';
import '../features/team/team_screen.dart';
import '../features/today/manager_today_screen.dart';
import '../features/today/staff_today_screen.dart';

enum HomeTab { today, managerToday, area, learn, mentor, issues, team, audits, me }

/// Tabs follow what the person may do (PRD "each person sees only their own
/// scope"): staff, mentors, outlet managers and area managers each get theirs.
List<HomeTab> tabsFor(Session s) {
  if (s.isAreaManager) return [HomeTab.area, HomeTab.issues, HomeTab.audits, HomeTab.me];
  if (s.isOutletManager) return [HomeTab.managerToday, HomeTab.issues, HomeTab.team, HomeTab.me];
  if (!s.canFill && !s.canLearn && s.canViewDashboards) return [HomeTab.area, HomeTab.issues, HomeTab.me];
  return [
    HomeTab.today,
    if (s.canLearn) HomeTab.learn,
    if (s.isMentor) HomeTab.mentor,
    HomeTab.issues,
    HomeTab.me,
  ];
}

/// Selected tab; other screens can switch it (e.g. "All issues").
class HomeTabController extends Notifier<HomeTab?> {
  @override
  HomeTab? build() => null;
  void select(HomeTab tab) => state = tab;
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab?>(HomeTabController.new);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Send anything saved offline last time.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(syncProvider.notifier).processAll());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(sessionProvider, (_, next) {
      final s = next.value;
      if (s != null) ref.read(localeProvider.notifier).adoptProfileDefault(s.profile.locale);
    });
    final session = ref.watch(sessionProvider);

    return session.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => e is NoProfileException
          ? const _NoAccessScreen()
          : Scaffold(body: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(sessionProvider))),
      data: (s) {
        if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final tabs = tabsFor(s);
        final selected = ref.watch(homeTabProvider);
        final index = selected == null ? 0 : tabs.indexOf(selected).clamp(0, tabs.length - 1);
        return Scaffold(
          body: IndexedStack(index: index, children: [for (final t in tabs) _page(t)]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).select(tabs[i]),
            destinations: [for (final t in tabs) _destination(t, l10n)],
          ),
        );
      },
    );
  }

  Widget _page(HomeTab t) => switch (t) {
        HomeTab.today => const StaffTodayScreen(),
        HomeTab.managerToday => const ManagerTodayScreen(),
        HomeTab.area => const AreaScreen(),
        HomeTab.learn => const LearnScreen(),
        HomeTab.mentor => const MentorScreen(),
        HomeTab.issues => const IssuesScreen(),
        HomeTab.team => const TeamScreen(),
        HomeTab.audits => const AuditsScreen(),
        HomeTab.me => const MeScreen(),
      };

  NavigationDestination _destination(HomeTab t, AppLocalizations l10n) => switch (t) {
        HomeTab.today || HomeTab.managerToday => NavigationDestination(
            icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.today),
        HomeTab.area => NavigationDestination(
            icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: l10n.outlets),
        HomeTab.learn => NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: l10n.learn),
        HomeTab.mentor => NavigationDestination(
            icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people), label: l10n.mentor),
        HomeTab.issues => NavigationDestination(
            icon: const Icon(Icons.report_problem_outlined),
            selectedIcon: const Icon(Icons.report_problem),
            label: l10n.issues),
        HomeTab.team => NavigationDestination(
            icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: l10n.team),
        HomeTab.audits => NavigationDestination(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: const Icon(Icons.assignment_turned_in),
            label: l10n.audits),
        HomeTab.me => NavigationDestination(
            icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.me),
      };
}

/// Shows [child] once the session is loaded.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.value != null) return child;
    if (session.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: session.error.toString(), onRetry: () => ref.invalidate(sessionProvider)),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _NoAccessScreen extends ConsumerWidget {
  const _NoAccessScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(l10n.accountNotReady, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.accountNotReadyBody, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(localStoreProvider).clearUserData();
                  await ref.read(supabaseProvider).auth.signOut();
                },
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
