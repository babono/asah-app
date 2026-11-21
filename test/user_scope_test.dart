import 'package:asah/core/offline/local_store.dart';
import 'package:asah/core/supabase/supabase_providers.dart';
import 'package:asah/features/issues/issue_repository.dart';
import 'package:asah/features/learning/learning_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _User extends Notifier<String?> {
  @override
  String? build() => 'putu';
  void set(String? id) => state = id;
}

final _user = NotifierProvider<_User, String?>(_User.new);

/// On a shared outlet phone, nothing loaded for one person may be shown to the
/// next: every repository (and the queries built on it) is rebuilt when the
/// signed-in user changes.
void main() {
  test('repositories are rebuilt when someone else signs in', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      supabaseProvider.overrideWithValue(SupabaseClient('http://localhost', 'test-key')),
      currentUserIdProvider.overrideWith((ref) => ref.watch(_user)),
    ]);
    addTearDown(container.dispose);
    final issues = <IssueRepository>[];
    container.listen(issueRepositoryProvider, (_, next) => issues.add(next), fireImmediately: true);
    final learning = <LearningRepository>[];
    container.listen(learningRepositoryProvider, (_, next) => learning.add(next), fireImmediately: true);

    container.read(_user.notifier).set(null); // Putu signs out
    container.read(_user.notifier).set('komang'); // Komang signs in
    container.read(issueRepositoryProvider);
    container.read(learningRepositoryProvider);

    expect(issues.length, greaterThan(1));
    expect(identical(issues.first, issues.last), isFalse);
    expect(identical(learning.first, learning.last), isFalse);
  });
}
