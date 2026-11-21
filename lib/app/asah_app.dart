import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/l10n/l10n.dart';
import '../core/l10n/locale_controller.dart';
import '../core/supabase/supabase_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/push_service.dart';
import 'router.dart';

/// The phone app for staff, mentors and outlet and area managers.
class AsahApp extends ConsumerStatefulWidget {
  const AsahApp({super.key});

  @override
  ConsumerState<AsahApp> createState() => _AsahAppState();
}

class _AsahAppState extends ConsumerState<AsahApp> {
  @override
  void initState() {
    super.initState();
    PushService.start(
      db: ref.read(supabaseProvider),
      open: (route) => ref.read(routerProvider).push(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      locale: locale ?? const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
