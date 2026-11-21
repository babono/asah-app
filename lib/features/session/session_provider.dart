import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/local_store.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/errors.dart';
import 'models.dart';

class NoProfileException implements Exception {
  const NoProfileException();
}

/// The signed-in person's profile, permissions and the outlet list.
/// Cached on the device so the app opens offline (PRD F7).
final sessionProvider = FutureProvider<Session?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final db = userDb(ref);
  final store = ref.watch(localStoreProvider);
  final cacheKey = 'cache:session:$userId';

  try {
    final results = await Future.wait<dynamic>([
      db.from('profiles').select(Profile.select).eq('id', userId).maybeSingle(),
      db.rpc('my_permissions'),
      db.from('outlets').select(Outlet.select).isFilter('archived_at', null).order('name', ascending: true),
    ]);
    final profileRow = results[0] as Map<String, dynamic>?;
    if (profileRow == null) throw const NoProfileException();
    final session = Session(
      profile: Profile.fromJson(profileRow),
      grants: (results[1] as List).map((g) => Grant.fromJson(g as Map<String, dynamic>)).toList(),
      outlets: {
        for (final o in (results[2] as List).map((o) => Outlet.fromJson(o as Map<String, dynamic>))) o.id: o,
      },
    );
    await store.setJson(cacheKey, session.toJson());
    return session;
  } catch (e) {
    if (isNetworkError(e)) {
      final cached = store.getMap(cacheKey);
      if (cached != null) return Session.fromJson(cached);
    }
    rethrow;
  }
});

/// Convenience for screens that only render once the session exists.
final requireSessionProvider = Provider<Session>((ref) {
  final s = ref.watch(sessionProvider).value;
  if (s != null) return _lastSession = s;
  // Just signed out: screens still on their way out get the last session for
  // their final frame instead of an error. A new sign-in loads a fresh one.
  final last = _lastSession;
  if (last != null && ref.watch(currentUserIdProvider) == null) return last;
  throw StateError('No session');
});

Session? _lastSession;
