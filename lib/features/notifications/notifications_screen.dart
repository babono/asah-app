import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import 'notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: AsyncBody(
          value: list,
          onRetry: () => ref.invalidate(notificationsProvider),
          builder: (items) => items.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: [
                  EmptyState(icon: Icons.notifications_none_rounded, message: l10n.noNotifications),
                ])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      tileColor: n.unread ? AppColors.primarySoft.withValues(alpha: 0.4) : null,
                      leading: Icon(_icon(n.type), color: n.unread ? AppColors.primary : AppColors.textSecondary),
                      title: Text(n.title, style: TextStyle(fontWeight: n.unread ? FontWeight.w700 : FontWeight.w500)),
                      subtitle: Text([if (n.body != null) n.body!, Fmt.dayTime(n.createdAt)].join('\n')),
                      isThreeLine: n.body != null,
                      onTap: () async {
                        if (n.unread) {
                          await ref.read(notificationsRepositoryProvider).markRead(n.id);
                          ref.invalidate(notificationsProvider);
                        }
                        final route = routeForNotification(n.type, n.data);
                        if (route != null && context.mounted) context.push(route);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  static IconData _icon(String type) {
    if (type.startsWith('issue')) return Icons.report_problem_outlined;
    if (type.startsWith('checklist')) return Icons.fact_check_outlined;
    if (type.startsWith('practical') || type.startsWith('trainee') || type.startsWith('mentor')) return Icons.people_outline;
    if (type.startsWith('certificate')) return Icons.verified_outlined;
    if (type.startsWith('checkin')) return Icons.event_note_outlined;
    return Icons.menu_book_outlined;
  }
}

/// Bell button with an unread dot (Today header).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Semantics(
      label: unread > 0 ? l10n.notificationsUnread(unread) : l10n.notifications,
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/notifications'),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 22),
                if (unread > 0)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.belowTarget,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
