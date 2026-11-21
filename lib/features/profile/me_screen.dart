import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/offline/local_store.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../mentorship/mentorship_repository.dart';
import '../mentorship/rate_mentor_screen.dart';
import '../session/session_provider.dart';
import '../sync/sync_service.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final p = session.profile;
    final locale = ref.watch(localeProvider)?.languageCode ?? p.locale;
    final sync = ref.watch(syncProvider);
    final store = ref.watch(localStoreProvider);
    final toRate = (ref.watch(myMentorshipsProvider).value ?? [])
        .where((m) => !m.active && !hasRated(store, m.id))
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          TabHeader(title: l10n.me, padding: const EdgeInsets.fromLTRB(0, 24, 0, 16)),
          AppCard(
            child: Row(
              children: [
                Avatar(p.fullName, tone: Tone.accent, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(
                        [p.positionName, session.outlet?.name].whereType<String>().join(' · '),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (p.phone != null)
                        Text(p.phone!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final m in toRate) ...[
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.push('/rate-mentor/${m.id}'),
              color: AppColors.warningSoft,
              borderColor: AppColors.warningSoft,
              child: Row(
                children: [
                  const Icon(Icons.star_outline_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.rateMentorPrompt(m.mentorName ?? ''),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          GroupedCard(children: [
            if (session.isManager && session.canLearn)
              _Link(icon: Icons.menu_book_outlined, label: l10n.myLearning, onTap: () => context.push('/learn')),
            _Link(icon: Icons.verified_outlined, label: l10n.certificates, onTap: () => context.push('/certificates')),
            _Link(icon: Icons.notifications_none_rounded, label: l10n.notifications, onTap: () => context.push('/notifications')),
            if (sync.jobs.isNotEmpty)
              _Link(
                icon: Icons.cloud_upload_outlined,
                label: l10n.itemsWaitingToSync(sync.jobs.length),
                trailing: sync.running
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.syncNow, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                onTap: () => ref.read(syncProvider.notifier).processAll(),
              ),
          ]),
          const SizedBox(height: 20),
          Text(l10n.language, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'id', label: Text('Bahasa Indonesia')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {locale},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              if (sync.pending > 0) {
                final go = await confirmDialog(context,
                    title: l10n.signOutQ, message: l10n.signOutUnsynced(sync.pending), confirm: l10n.signOut);
                if (!go) return;
              }
              await ref.read(localStoreProvider).clearUserData();
              await ref.read(supabaseProvider).auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap, this.trailing});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textStrong),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.icon),
      onTap: onTap,
    );
  }
}
