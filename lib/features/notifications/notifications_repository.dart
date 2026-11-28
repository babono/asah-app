import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get unread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        data: Map<String, dynamic>.from((j['data'] as Map?) ?? {}),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// Where a notification leads in the app, from its data payload.
String? routeForNotification(String type, Map<String, dynamic> data) {
  if (data['run_id'] != null) return '/checklist/${data['run_id']}';
  if (data['issue_id'] != null) return '/issues/${data['issue_id']}';
  if (data['submission_id'] != null) return '/mentor/score/${data['submission_id']}';
  if (data['formal_training_id'] != null) return '/formal-training/${data['formal_training_id']}';
  if (data['mentorship_id'] != null) return '/mentor/checkin/${data['mentorship_id']}';
  if (data['certificate_id'] != null) return '/certificates';
  if (type == 'trainee_behind' && data['user_id'] != null) return '/team/${data['user_id']}';
  if (data['assignment_id'] != null && type != 'trainee_failed_quiz') return '/module/${data['assignment_id']}';
  if (type.startsWith('module_') || type.startsWith('practical_')) return '/learn';
  if (type == 'mentor_assigned' || type == 'trainee_failed_quiz') return '/';
  return null;
}

class NotificationsRepository {
  NotificationsRepository(this._db);
  final SupabaseClient _db;

  Future<List<AppNotification>> list() async {
    final rows = await _db
        .from('notifications')
        .select('id, type, title, body, data, read_at, created_at')
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).map((r) => AppNotification.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) =>
      _db.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  Future<void> markAllRead() => _db
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()}).isFilter('read_at', null);
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(userDb(ref)));

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(notificationsRepositoryProvider).list();
});

/// Unread count for the bell, kept live with Realtime.
final unreadCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  final db = userDb(ref);
  return db
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.where((r) => r['read_at'] == null).length);
});
