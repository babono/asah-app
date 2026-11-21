import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/offline/local_store.dart';
import '../core/supabase/supabase_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/widgets.dart';
import '../features/auth/logo.dart';
import '../features/session/models.dart';
import '../features/session/session_provider.dart';

class AdminNavItem {
  const AdminNavItem(this.section, this.label, this.path, this.icon, this.visible);
  final String section;
  final String label;
  final String path;
  final IconData icon;
  final bool Function(Session s) visible;
}

/// Sidebar entries; each shows only to people with the permission behind it.
final adminNav = <AdminNavItem>[
  AdminNavItem('Monitoring', 'Dashboards', '/', Icons.space_dashboard_outlined, (s) => s.hasAny('dashboard.view')),
  AdminNavItem('Monitoring', 'Issues and audits', '/issues', Icons.report_problem_outlined, (s) => s.hasAny('issue.view')),
  AdminNavItem('Setup', 'Positions and levels', '/org', Icons.account_tree_outlined, (s) => s.hasGroup('org.manage')),
  AdminNavItem('Setup', 'Users and roles', '/users', Icons.badge_outlined, (s) => s.hasAny('user.view') || s.hasGroup('user.manage')),
  AdminNavItem('Setup', 'Roles and permissions', '/roles', Icons.admin_panel_settings_outlined, (s) => s.hasGroup('role.manage')),
  AdminNavItem('Setup', 'Outlets', '/outlets', Icons.storefront_outlined, (s) => s.hasGroup('outlet.manage')),
  AdminNavItem('Asuh', 'Learning modules', '/modules', Icons.menu_book_outlined,
      (s) => s.hasGroup('module.author') || s.hasGroup('module.review')),
  AdminNavItem('Asuh', 'Learning paths', '/paths', Icons.route_outlined, (s) => s.hasGroup('path.manage')),
  AdminNavItem('Asuh', 'Mentor ratings', '/ratings', Icons.star_outline_rounded, (s) => s.hasGroup('mentor_rating.view_raters')),
  AdminNavItem('Aksi', 'Checklist templates', '/checklists', Icons.fact_check_outlined, (s) => s.hasGroup('checklist_template.manage')),
  AdminNavItem('System', 'Audit log', '/audit-log', Icons.history_rounded, (s) => s.hasGroup('audit_log.view')),
  AdminNavItem('System', 'Settings', '/settings', Icons.tune_rounded, (s) => s.hasGroup('settings.manage')),
];

String adminRoleLabel(Session s) {
  if (s.hasGroup('user.manage')) return 'HQ admin';
  if (s.hasGroup('module.review')) return 'Training manager';
  if (s.hasGroup('module.author')) return 'HQ trainer';
  if (s.hasGroup('mentor_rating.view_raters')) return 'HR and senior management';
  if (s.isAreaManager) return 'Area manager';
  if (s.isOutletManager) return 'Outlet manager';
  return 'Viewer';
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(sessionProvider))),
      data: (s) {
        if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final items = adminNav.where((i) => i.visible(s)).toList();
        if (items.isEmpty) return _NoAdminAccess(name: s.profile.fullName);
        final wide = MediaQuery.of(context).size.width >= 900;
        final nav = _Sidebar(items: items, location: location);
        return Scaffold(
          appBar: _Header(session: s, showMenu: !wide),
          drawer: wide ? null : Drawer(child: nav),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) SizedBox(width: 240, child: nav),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget implements PreferredSizeWidget {
  const _Header({required this.session, required this.showMenu});
  final Session session;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      toolbarHeight: 60,
      automaticallyImplyLeading: showMenu,
      titleSpacing: showMenu ? 0 : 24,
      title: Row(
        children: [
          const AsahMark(size: 32, background: AppColors.primary, foreground: AppColors.accent),
          const SizedBox(width: 12),
          const Text('ASAH Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(width: 12),
          Pill(adminRoleLabel(session), small: true),
        ],
      ),
      actions: [
        if (MediaQuery.of(context).size.width > 700)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(AppConfig.clientName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: session.profile.fullName,
          onSelected: (v) async {
            if (v == 'out') {
              await ref.read(localStoreProvider).clearUserData();
              await ref.read(supabaseProvider).auth.signOut();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text(session.profile.fullName)),
            const PopupMenuItem(value: 'out', child: Text('Sign out')),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Avatar(session.profile.fullName, tone: Tone.accent, size: 36),
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.location});
  final List<AdminNavItem> items;
  final String location;

  bool _active(AdminNavItem i) => i.path == '/' ? location == '/' : location.startsWith(i.path);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? section;
    for (final i in items) {
      if (i.section != section) {
        section = i.section;
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(12, children.isEmpty ? 0 : 16, 12, 6),
          child: Text(section.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: AppColors.textMuted)),
        ));
      }
      final on = _active(i);
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: on ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Scaffold.maybeOf(context)?.closeDrawer();
              context.go(i.path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(i.icon, size: 18, color: on ? AppColors.primary : AppColors.textStrong),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                            color: on ? AppColors.primary : AppColors.textStrong)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: ListView(padding: const EdgeInsets.fromLTRB(12, 20, 12, 20), children: children),
    );
  }
}

class _NoAdminAccess extends ConsumerWidget {
  const _NoAdminAccess({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Hi $name, the admin web is for HQ and managers.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Use the ASAH app on your phone for your tasks and learning.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(supabaseProvider).auth.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
