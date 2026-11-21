import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Emits on every sign-in, sign-out and token refresh.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

/// The signed-in user's id, or null. Rebuilds dependents only when it changes.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});

/// The client for data providers. Also makes the calling provider depend on the
/// signed-in user, so it (and everything built on it) reloads when someone else
/// signs in on the same phone (shared outlet phones): nothing from the previous
/// person is shown. A provider returning the client itself would not do this:
/// the client object never changes, so dependents would not be told.
SupabaseClient userDb(Ref ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(supabaseProvider);
}
