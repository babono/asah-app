import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../learning/learning_repository.dart';
import '../session/session_provider.dart';

/// Certificates with expiry (T8).
class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userId = ref.watch(requireSessionProvider).profile.id;
    final certs = ref.watch(certificatesProvider(userId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificates)),
      body: AsyncBody(
        value: certs,
        onRetry: () => ref.invalidate(certificatesProvider(userId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (list.isEmpty) EmptyState(icon: Icons.verified_outlined, message: l10n.noCertificatesYet),
            for (final c in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  radius: 16,
                  borderColor: c.expired ? AppColors.dangerBorder : AppColors.border,
                  child: Row(
                    children: [
                      IconTile(Icons.verified_outlined, tone: c.expired ? Tone.danger : Tone.primary, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text(
                              c.expiresAt == null
                                  ? l10n.issuedOn(Fmt.fullDate(c.issuedAt))
                                  : l10n.validUntil(Fmt.fullDate(c.expiresAt!)),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (c.expired)
                        Pill(l10n.expired, tone: Tone.danger, small: true)
                      else if (c.expiringSoon)
                        Pill(l10n.expiresSoon, tone: Tone.warning, small: true),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
