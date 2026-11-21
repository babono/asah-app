import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';

class Person {
  const Person(this.id, this.name, this.position);
  final String id;
  final String name;
  final String? position;

  String get label => position == null ? name : '$name · $position';
}

/// Names for a set of user ids, limited by people_names() to colleagues the
/// caller works with. Key: ids joined with ',' (use [peopleKey]).
final peopleProvider = FutureProvider.family<Map<String, Person>, String>((ref, key) async {
  final ids = key.split(',').where((s) => s.isNotEmpty).toList();
  if (ids.isEmpty) return {};
  final rows = await ref.watch(supabaseProvider).rpc('people_names', params: {'p_ids': ids});
  return {
    for (final r in rows as List)
      r['id'] as String: Person(r['id'] as String, r['full_name'] as String, r['position_name'] as String?),
  };
});

String peopleKey(Iterable<String?> ids) {
  final list = ids.whereType<String>().toSet().toList()..sort();
  return list.join(',');
}
