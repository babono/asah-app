import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/admin_widgets.dart';
import 'modules_page.dart';
import 'users_page.dart';

final _pathProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, positionId) async {
  return await ref
      .watch(supabaseProvider)
      .from('learning_paths')
      .select('id, name, learning_path_items(id, module_id, sort, is_mandatory, due_days)')
      .eq('position_id', positionId)
      .isFilter('archived_at', null)
      .maybeSingle();
});

const _dueOptions = {1: 'Day 1', 7: 'Week 1', 30: 'Month 1', 60: 'Month 2', 90: 'Month 3'};

/// One learning path per position: order, mandatory or optional, due by
/// day 1, week 1 or month 1 (T6). Adding a module assigns it to everyone in
/// the position (T7, done by the database).
class PathsPage extends ConsumerStatefulWidget {
  const PathsPage({super.key});

  @override
  ConsumerState<PathsPage> createState() => _PathsPageState();
}

class _PathsPageState extends ConsumerState<PathsPage> {
  String? _positionId;

  void _reload() => ref.invalidate(_pathProvider(_positionId!));

  @override
  Widget build(BuildContext context) {
    final positions = ref.watch(positionsProvider);
    final modules = ref.watch(modulesListProvider).value ?? [];
    final titles = {for (final m in modules) if (latestVersion(m) != null) m['id'] as String: latestVersion(m)!['title'] as String};
    final publishedIds = {
      for (final m in modules)
        if ((m['module_versions'] as List).any((v) => v['status'] == 'published')) m['id'] as String,
    };

    return AdminPage(
      breadcrumb: 'Asuh',
      title: 'Learning paths',
      subtitle: 'A new hire, or someone who changes position, gets the path of their position automatically.',
      actions: [
        SizedBox(
          width: 320,
          child: AdminAsync(
            value: positions,
            builder: (ps) {
              _positionId ??= ps.firstOrNull?.id;
              return DropdownButtonFormField<String>(
                initialValue: _positionId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Position'),
                items: [for (final p in ps) DropdownMenuItem(value: p.id, child: Text('${p.department} · ${p.name}'))],
                onChanged: (v) => setState(() => _positionId = v),
              );
            },
          ),
        ),
      ],
      children: [
        if (_positionId != null)
          AdminAsync(
            value: ref.watch(_pathProvider(_positionId!)),
            builder: (path) {
              if (path == null) {
                return AdminSection(
                  child: Row(children: [
                    const Expanded(child: Text('This position has no learning path yet.')),
                    AdminButton('Create path', primary: true, icon: Icons.add, onPressed: _createPath),
                  ]),
                );
              }
              final items = (path['learning_path_items'] as List).cast<Map<String, dynamic>>()
                ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
              return AdminSection(
                title: path['name'] as String,
                trailing: Wrap(spacing: 8, children: [
                  TextButton(onPressed: () => _rename(path), child: const Text('Rename')),
                  AdminButton('Add module', icon: Icons.add, primary: true, onPressed: () => _addModule(path, items, titles, publishedIds)),
                ]),
                child: items.isEmpty
                    ? const Text('No modules yet.', style: TextStyle(color: AppColors.textSecondary))
                    : AdminTable(
                        columns: const ['#', 'Module', 'Due by', 'Mandatory', ''],
                        rows: [
                          for (var i = 0; i < items.length; i++)
                            DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(titles[items[i]['module_id']] ?? '–', style: const TextStyle(fontWeight: FontWeight.w700)),
                                if (!publishedIds.contains(items[i]['module_id'])) ...[
                                  const SizedBox(width: 8),
                                  const Pill('Not published · not assigned yet', tone: Tone.warning, small: true),
                                ],
                              ])),
                              DataCell(DropdownButton<int>(
                                value: _dueOptions.containsKey(items[i]['due_days']) ? items[i]['due_days'] as int : null,
                                hint: Text('${items[i]['due_days']} days'),
                                underline: const SizedBox(),
                                items: [for (final e in _dueOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                                onChanged: (v) => _update(items[i], {'due_days': v}),
                              )),
                              DataCell(Switch(
                                value: items[i]['is_mandatory'] as bool,
                                onChanged: (v) => _update(items[i], {'is_mandatory': v}),
                              )),
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(tooltip: 'Move up', onPressed: () => _move(items, i, -1), icon: const Icon(Icons.arrow_upward, size: 18)),
                                IconButton(tooltip: 'Move down', onPressed: () => _move(items, i, 1), icon: const Icon(Icons.arrow_downward, size: 18)),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                                  onPressed: () => _remove(items[i]),
                                ),
                              ])),
                            ]),
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _createPath() async {
    final positions = ref.read(positionsProvider).value ?? [];
    final p = positions.firstWhere((x) => x.id == _positionId);
    final ok = await runAction(
      context,
      () => ref.read(supabaseProvider).from('learning_paths').insert({'position_id': _positionId, 'name': '${p.name} path'}),
    );
    if (ok) _reload();
  }

  Future<void> _rename(Map<String, dynamic> path) async {
    final name = TextEditingController(text: path['name'] as String);
    final ok = await showFormDialog(context,
        title: 'Rename path',
        fields: [FormText('Name', name)],
        onSave: () => ref.read(supabaseProvider).from('learning_paths').update({'name': name.text.trim()}).eq('id', path['id']));
    if (ok) _reload();
  }

  Future<void> _addModule(Map<String, dynamic> path, List<Map<String, dynamic>> items, Map<String, String> titles, Set<String> published) async {
    final have = items.map((i) => i['module_id']).toSet();
    final options = {for (final e in titles.entries) if (!have.contains(e.key)) e.key: e.value};
    String? moduleId = options.keys.firstOrNull;
    int due = 7;
    bool mandatory = true;
    final ok = await showFormDialog(context,
        title: 'Add module to path',
        save: 'Add',
        fields: [
          FormSelect<String>('Module', items: options, initial: moduleId, onChanged: (v) => moduleId = v),
          FormSelect<int>('Due by', items: _dueOptions, initial: due, onChanged: (v) => due = v ?? 7),
          FormCheck('Mandatory', initial: mandatory, onChanged: (v) => mandatory = v),
          const Text('Everyone in this position gets the module as soon as it is published.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        onSave: () async {
          if (moduleId == null) throw Exception('Pick a module');
          final next = items.fold<int>(0, (m, i) => (i['sort'] as int) > m ? i['sort'] as int : m) + 1;
          await ref.read(supabaseProvider).from('learning_path_items').insert({
            'path_id': path['id'],
            'module_id': moduleId,
            'sort': next,
            'is_mandatory': mandatory,
            'due_days': due,
          });
        });
    if (ok) _reload();
  }

  Future<void> _update(Map<String, dynamic> item, Map<String, dynamic> change) async {
    final ok = await runAction(context, () => ref.read(supabaseProvider).from('learning_path_items').update(change).eq('id', item['id']));
    if (ok) _reload();
  }

  Future<void> _move(List<Map<String, dynamic>> items, int i, int delta) async {
    final j = i + delta;
    if (j < 0 || j >= items.length) return;
    final db = ref.read(supabaseProvider);
    final ok = await runAction(context, () async {
      await db.from('learning_path_items').update({'sort': items[j]['sort']}).eq('id', items[i]['id']);
      await db.from('learning_path_items').update({'sort': items[i]['sort']}).eq('id', items[j]['id']);
    });
    if (ok) _reload();
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final go = await confirmDialog(context,
        title: 'Remove from path?', message: 'People who already have this module keep it. New hires will not get it.');
    if (!go || !mounted) return;
    final ok = await runAction(context, () => ref.read(supabaseProvider).from('learning_path_items').delete().eq('id', item['id']));
    if (ok) _reload();
  }
}
