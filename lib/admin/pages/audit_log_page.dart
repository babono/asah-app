import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../features/session/people.dart';
import '../widgets/admin_widgets.dart';

final _logProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String? table, int page})>((ref, a) async {
  var q = ref.watch(supabaseProvider).from('admin_audit_log').select();
  if (a.table != null) q = q.eq('table_name', a.table!);
  final rows = await q.order('created_at', ascending: false).range(a.page * 50, a.page * 50 + 49);
  return (rows as List).cast<Map<String, dynamic>>();
});

final _ratingViewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('mentor_rating_access_log').select().order('viewed_at', ascending: false).limit(100);
  return (rows as List).cast<Map<String, dynamic>>();
});

const _tables = [
  'profiles', 'user_roles', 'roles', 'role_permissions', 'positions', 'departments', 'outlets', 'brands', 'areas',
  'app_settings', 'learning_paths', 'learning_path_items', 'checklist_templates', 'checklist_schedules',
];

/// Every admin and permission change: who, what, when, before and after (F9).
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _table;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(_logProvider((table: _table, page: _page)));
    final views = ref.watch(_ratingViewsProvider);
    return AdminPage(
      breadcrumb: 'System',
      title: 'Audit log',
      actions: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: _table,
            decoration: const InputDecoration(labelText: 'Record type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Everything')),
              for (final t in _tables) DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() {
              _table = v;
              _page = 0;
            }),
          ),
        ),
      ],
      children: [
        AdminSection(
          child: AdminAsync(
            value: log,
            builder: (rows) {
              final people = ref.watch(peopleProvider(peopleKey(rows.map((r) => r['actor_id'] as String?)))).value ?? {};
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminTable(
                    minWidth: 760,
                    columns: const ['When', 'Who', 'Action', 'Record', 'Change'],
                    rows: [
                      for (final r in rows)
                        DataRow(
                          onSelectChanged: (_) => _show(r),
                          cells: [
                            DataCell(Text(Fmt.dayTime(DateTime.parse(r['created_at'] as String)))),
                            DataCell(Text(people[r['actor_id']]?.name ?? (r['actor_id'] == null ? 'System' : '…'))),
                            DataCell(Text(r['action'] as String)),
                            DataCell(Text('${r['table_name']}')),
                            DataCell(Text(_summary(r), overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary))),
                          ],
                        ),
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: _page == 0 ? null : () => setState(() => _page--), child: const Text('Newer')),
                    TextButton(onPressed: rows.length < 50 ? null : () => setState(() => _page++), child: const Text('Older')),
                  ]),
                ],
              );
            },
          ),
        ),
        AdminSection(
          title: 'Who viewed mentor raters',
          child: AdminAsync(
            value: views,
            builder: (rows) {
              final people = ref.watch(peopleProvider(peopleKey(rows.expand((r) => [r['viewer_id'] as String?, r['mentor_id'] as String?])))).value ?? {};
              return rows.isEmpty
                  ? const Text('No views yet.', style: TextStyle(color: AppColors.textSecondary))
                  : AdminTable(
                      columns: const ['When', 'Viewer', 'Mentor'],
                      rows: [
                        for (final r in rows)
                          DataRow(cells: [
                            DataCell(Text(Fmt.dayTime(DateTime.parse(r['viewed_at'] as String)))),
                            DataCell(Text(people[r['viewer_id']]?.name ?? '…')),
                            DataCell(Text(people[r['mentor_id']]?.name ?? '…')),
                          ]),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  /// Fields that changed between before and after.
  static String _summary(Map<String, dynamic> r) {
    final before = (r['before'] as Map?) ?? {};
    final after = (r['after'] as Map?) ?? {};
    final keys = {...before.keys, ...after.keys}.where((k) => k != 'updated_at' && before[k]?.toString() != after[k]?.toString());
    return keys.map((k) => '$k: ${before[k] ?? '∅'} → ${after[k] ?? '∅'}').join('; ');
  }

  void _show(Map<String, dynamic> r) {
    const enc = JsonEncoder.withIndent('  ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r['action']} · ${r['table_name']}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SelectableText('Before\n${enc.convert(r['before'])}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
              const SizedBox(width: 16),
              Expanded(child: SelectableText('After\n${enc.convert(r['after'])}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
