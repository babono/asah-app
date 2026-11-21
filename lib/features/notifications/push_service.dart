import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'notifications_repository.dart';

/// Push notifications through OneSignal (PRD F6). The server writes
/// public.notifications rows; a trigger forwards each to the "push" Edge
/// Function, which targets the OneSignal External ID = Supabase user id.
class PushService {
  static bool _started = false;

  static Future<void> start({required SupabaseClient db, required void Function(String route) open}) async {
    if (_started || kIsWeb || !AppConfig.isPushConfigured) return;
    _started = true;

    OneSignal.initialize(AppConfig.onesignalAppId);

    void link(String? userId) {
      if (userId != null) {
        OneSignal.login(userId);
        OneSignal.Notifications.requestPermission(true);
      }
    }

    link(db.auth.currentUser?.id);
    // Re-link on every auth event: a session restored after start-up would
    // otherwise leave the device without an External ID and pushes go nowhere.
    db.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          link(data.session?.user.id);
        case AuthChangeEvent.signedOut:
          OneSignal.logout();
        default:
          break;
      }
    });

    OneSignal.Notifications.addClickListener((event) {
      final data = Map<String, dynamic>.from(event.notification.additionalData ?? {});
      final route = routeForNotification((data['type'] as String?) ?? '', data);
      if (route != null) open(route);
    });
  }
}
