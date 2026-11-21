import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/local_store.dart';
import 'models.dart';

/// Unfinished checklists survive the app closing (PRD A6).
class ChecklistDraftStore {
  ChecklistDraftStore(this._store);
  final LocalStore _store;

  String _key(String runId) => 'draft:run:$runId';

  Map<String, Answer> load(String runId) {
    final m = _store.getMap(_key(runId));
    if (m == null) return {};
    return m.map((k, v) => MapEntry(k, Answer.fromJson(v as Map<String, dynamic>)));
  }

  bool has(String runId) => _store.getMap(_key(runId)) != null;

  Future<void> save(String runId, Map<String, Answer> answers) =>
      _store.setJson(_key(runId), answers.map((k, v) => MapEntry(k, v.toJson())));

  Future<void> clear(String runId) => _store.remove(_key(runId));
}

final checklistDraftStoreProvider = Provider((ref) => ChecklistDraftStore(ref.watch(localStoreProvider)));
