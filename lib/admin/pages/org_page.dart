import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/admin_widgets.dart';

final _orgProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('departments')
      .select('id, name, sort_order, archived_at, positions(id, name, level, archived_at)')
      .order('sort_order')
      .order('name');
  return (rows as List).cast<Map<String, dynamic>>();
});

/// Departments, positions and levels (F2). Changes apply without an app
/// release; archiving is blocked by the server while staff or content use it.
class OrgPage extends ConsumerStatefulWidget {
  const OrgPage({super.key});

  @override
  ConsumerState<OrgPage> createState() => _OrgPageState();
}

class _OrgPageState extends ConsumerState<OrgPage> {
  bool _showArchived = false;

  Future<void> _run(Future<void> Function() action, String ok) async {
    if (await runAction(context, action, success: ok)) ref.invalidate(_orgProvider);
  }

  Future<void> _editDepartment([Map<String, dynamic>? d]) async {
    final name = TextEditingController(text: d?['name'] as String?);
    final db = ref.read(supabaseProvider);
    final saved = await showFormDialog(context,
        title: d == null ? 'New department' : 'Rename department',
        fields: [FormText('Name', name, hint: 'e.g. Kitchen, Service, Bar')],
        onSave: () async {
          if (d == null) {
            final count = (ref.read(_orgProvider).value ?? []).length;
            await db.from('departments').insert({'name': name.text.trim(), 'sort_order': count});
          } else {
            await db.from('departments').update({'name': name.text.trim()}).eq('id', d['id']);
          }
        });
    if (saved) ref.invalidate(_orgProvider);
  }

  Future<void> _editPosition(Map<String, dynamic> dept, [Map<String, dynamic>? p]) async {
    final name = TextEditingController(text: p?['name'] as String?);
    final positions = (dept['positions'] as List).where((x) => x['archived_at'] == null).toList();
    final nextLevel = positions.fold<int>(0, (m, x) => (x['level'] as int) > m ? x['level'] as int : m) + 1;
    final level = TextEditingController(text: '${p?['level'] ?? nextLevel}');
    final db = ref.read(supabaseProvider);
    final saved = await showFormDialog(context,
        title: p == null ? 'New position in ${dept['name']}' : 'Edit position',
        fields: [
          FormText('Position', name, hint: 'e.g. Server, Captain'),
          FormText('Level (1 = entry)', level, number: true),
          const Text('One active position per level in a department. Level decides mentor eligibility, not access.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        onSave: () async {
          final row = {'name': name.text.trim(), 'level': int.parse(level.text.trim())};
          if (p == null) {
            await db.from('positions').insert({...row, 'department_id': dept['id']});
          } else {
            await db.from('positions').update(row).eq('id', p['id']);
          }
        });
    if (saved) ref.invalidate(_orgProvider);
  }

  Future<void> _move(List<Map<String, dynamic>> depts, int index, int delta) async {
    final j = index + delta;
    if (j < 0 || j >= depts.length) return;
    final db = ref.read(supabaseProvider);
    await _run(() async {
      final reordered = List.of(depts);
      final d = reordered.removeAt(index);
      reordered.insert(j, d);
      for (var k = 0; k < reordered.length; k++) {
        await db.from('departments').update({'sort_order': k}).eq('id', reordered[k]['id']);
      }
    }, 'Order saved');
  }

  Future<void> _archive(String table, Map<String, dynamic> row) async {
    final archived = row['archived_at'] != null;
    await _run(
      () => ref.read(supabaseProvider).from(table).update({
        'archived_at': archived ? null : DateTime.now().toUtc().toIso8601String(),
      }).eq('id', row['id']),
      archived ? 'Restored' : 'Archived',
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(_orgProvider);
    return AdminPage(
      breadcrumb: 'Setup',
      title: 'Positions and levels',
      subtitle: 'Department = career track. Position = job title. Level = its step on the ladder.',
      actions: [
        FilterChip(label: const Text('Show archived'), selected: _showArchived, onSelected: (v) => setState(() => _showArchived = v)),
        AdminButton('New department', icon: Icons.add, primary: true, onPressed: () => _editDepartment()),
      ],
      children: [
        AdminAsync(
          value: org,
          onRetry: () => ref.invalidate(_orgProvider),
          builder: (all) {
            final depts = all.where((d) => _showArchived || d['archived_at'] == null).toList();
            return Column(
              children: [
                for (var i = 0; i < depts.length; i++)
                  AdminSection(
                    title: depts[i]['name'] as String,
                    trailing: Wrap(spacing: 4, children: [
                      if (depts[i]['archived_at'] != null) const StatusChip('archived'),
                      IconButton(tooltip: 'Move up', onPressed: () => _move(depts, i, -1), icon: const Icon(Icons.arrow_upward, size: 18)),
                      IconButton(tooltip: 'Move down', onPressed: () => _move(depts, i, 1), icon: const Icon(Icons.arrow_downward, size: 18)),
                      IconButton(tooltip: 'Rename', onPressed: () => _editDepartment(depts[i]), icon: const Icon(Icons.edit_outlined, size: 18)),
                      IconButton(
                        tooltip: depts[i]['archived_at'] == null ? 'Archive' : 'Restore',
                        onPressed: () => _archive('departments', depts[i]),
                        icon: Icon(depts[i]['archived_at'] == null ? Icons.archive_outlined : Icons.unarchive_outlined, size: 18),
                      ),
                    ]),
                    child: _Positions(
                      dept: depts[i],
                      showArchived: _showArchived,
                      onAdd: () => _editPosition(depts[i]),
                      onEdit: (p) => _editPosition(depts[i], p),
                      onArchive: (p) => _archive('positions', p),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Positions extends StatelessWidget {
  const _Positions({required this.dept, required this.showArchived, required this.onAdd, required this.onEdit, required this.onArchive});
  final Map<String, dynamic> dept;
  final bool showArchived;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onArchive;

  @override
  Widget build(BuildContext context) {
    final positions = (dept['positions'] as List)
        .cast<Map<String, dynamic>>()
        .where((p) => showArchived || p['archived_at'] == null)
        .toList()
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in positions)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                SizedBox(width: 72, child: Pill('Level ${p['level']}', tone: Tone.neutral, small: true)),
                const SizedBox(width: 8),
                Expanded(child: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (p['archived_at'] != null) const StatusChip('archived'),
                IconButton(tooltip: 'Edit', onPressed: () => onEdit(p), icon: const Icon(Icons.edit_outlined, size: 18)),
                IconButton(
                  tooltip: p['archived_at'] == null ? 'Archive' : 'Restore',
                  onPressed: () => onArchive(p),
                  icon: Icon(p['archived_at'] == null ? Icons.archive_outlined : Icons.unarchive_outlined, size: 18),
                ),
              ],
            ),
          ),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add position'))),
      ],
    );
  }
}
