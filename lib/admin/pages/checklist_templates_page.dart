import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';

final templatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('checklist_templates')
      .select('id, name, kind, brand_id, archived_at, brands(name), '
          'checklist_template_versions(id, version, published_at), checklist_template_positions(positions(name)), '
          'checklist_schedules(id, shift, due_time, active)')
      .order('kind')
      .order('name');
  return (rows as List).cast<Map<String, dynamic>>();
});

/// Checklist and audit templates (A1). The same builder makes temperature and
/// FIFO logs, prep lists, equipment logs and area manager audit forms.
class ChecklistTemplatesPage extends ConsumerStatefulWidget {
  const ChecklistTemplatesPage({super.key});

  @override
  ConsumerState<ChecklistTemplatesPage> createState() => _ChecklistTemplatesPageState();
}

class _ChecklistTemplatesPageState extends ConsumerState<ChecklistTemplatesPage> {
  bool _showArchived = false;

  Future<void> _create() async {
    final name = TextEditingController();
    String kind = 'routine';
    String? id;
    final db = ref.read(supabaseProvider);
    final me = ref.read(requireSessionProvider).profile.id;
    final ok = await showFormDialog(context,
        title: 'New template',
        save: 'Create',
        fields: [
          FormText('Name', name, hint: 'e.g. Opening checklist · Service'),
          FormSelect<String>('Kind',
              items: const {'routine': 'Daily checklist (staff, scheduled)', 'audit': 'Visit audit (area manager)'},
              initial: kind,
              onChanged: (v) => kind = v ?? 'routine'),
        ],
        onSave: () async {
          final t = await db.from('checklist_templates').insert({'name': name.text.trim(), 'kind': kind, 'created_by': me}).select('id').single();
          id = t['id'] as String;
          await db.from('checklist_template_versions').insert({'template_id': id, 'version': 1, 'created_by': me});
        });
    if (ok && id != null && mounted) {
      ref.invalidate(templatesProvider);
      context.go('/checklists/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider);
    return AdminPage(
      breadcrumb: 'Aksi',
      title: 'Checklist templates',
      actions: [
        FilterChip(label: const Text('Show archived'), selected: _showArchived, onSelected: (v) => setState(() => _showArchived = v)),
        AdminButton('New template', icon: Icons.add, primary: true, onPressed: _create),
      ],
      children: [
        AdminSection(
          child: AdminAsync(
            value: templates,
            onRetry: () => ref.invalidate(templatesProvider),
            builder: (all) => AdminTable(
              minWidth: 860,
              columns: const ['Template', 'Kind', 'Brands', 'Positions', 'Schedule', 'Version'],
              rows: [
                for (final t in all.where((t) => _showArchived || t['archived_at'] == null))
                  DataRow(
                    onSelectChanged: (_) => context.go('/checklists/${t['id']}'),
                    cells: [
                      DataCell(Text(t['name'] as String,
                          style: TextStyle(fontWeight: FontWeight.w700, color: t['archived_at'] != null ? AppColors.textMuted : null))),
                      DataCell(Pill(t['kind'] == 'audit' ? 'Audit' : 'Daily', tone: t['kind'] == 'audit' ? Tone.info : Tone.primary, small: true)),
                      DataCell(Text((t['brands'] as Map?)?['name'] as String? ?? 'All brands')),
                      DataCell(Text((t['checklist_template_positions'] as List).map((p) => (p['positions'] as Map?)?['name']).join(', '))),
                      DataCell(Text(_schedule(t))),
                      DataCell(_versionChip(t)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _schedule(Map<String, dynamic> t) {
    if (t['kind'] == 'audit') return 'On visit';
    final s = (t['checklist_schedules'] as List).where((x) => x['active'] == true).toList();
    if (s.isEmpty) return 'Not scheduled';
    return s.map((x) => '${x['shift']} ${(x['due_time'] as String).substring(0, 5)}').toSet().join(', ');
  }

  static Widget _versionChip(Map<String, dynamic> t) {
    final vs = (t['checklist_template_versions'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (b['version'] as int).compareTo(a['version'] as int));
    final latest = vs.firstOrNull;
    if (latest == null) return const Text('–');
    final draft = latest['published_at'] == null;
    return Pill('v${latest['version']} · ${draft ? 'draft' : 'published'}', tone: draft ? Tone.warning : Tone.primary, small: true);
  }
}
