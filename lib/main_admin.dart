import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin/admin_app.dart';
import 'core/config/app_config.dart';
import 'core/offline/local_store.dart';

/// Admin web entry point.
///   flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=config/development.json
///   flutter build web -t lib/main_admin.dart --dart-define-from-file=config/production.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
  final store = await LocalStore.open();
  runApp(ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: const AsahAdminApp(),
  ));
}
