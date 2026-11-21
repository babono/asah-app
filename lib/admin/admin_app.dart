import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/l10n/l10n.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'admin_router.dart';

/// HQ admin web (PRD F1-F4, T1-T6, A1-A2, S4-S5, M7, F9).
class AsahAdminApp extends ConsumerWidget {
  const AsahAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = AppTheme.light();
    return MaterialApp.router(
      title: 'ASAH Admin',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        // Buttons size to their content on the web.
        filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style!.copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 48))),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: base.outlinedButtonTheme.style!.copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 48))),
        ),
        dataTableTheme: const DataTableThemeData(headingRowHeight: 40, dataRowMinHeight: 52, dataRowMaxHeight: 64),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      ),
      routerConfig: ref.watch(adminRouterProvider),
      locale: ref.watch(localeProvider) ?? const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
