import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';
import 'checklist_templates_page.dart';
import 'users_page.dart';

class _TemplateData {
  _TemplateData(this.template, this.versions, this.items, this.positions, this.schedules);
  final Map<String, dynamic> template;
  final List<Map<String, dynamic>> versions; // newest first
  final List<Map<String, dynamic>> items;
  final Set<String> positions;
  final List<Map<String, dynamic>> schedules;

  Map<String, dynamic> get latest => versions.first;
  bool get isDraft => latest['published_at'] == null;
  bool get isAudit => template['kind'] == 'audit';
}

final _templateProvider = FutureProvider.family<_TemplateData, String>((ref, id) async {
  final db = ref.watch(supabaseProvider);
  final t = await db.from('checklist_templates').select().eq('id', id).single();
  final versions = ((await db.from('checklist_template_versions').select().eq('template_id', id).order('version', ascending: false)) as List)
      .cast<Map<String, dynamic>>();
  final results = await Future.wait<dynamic>([
    db.from('checklist_items').select().eq('template_version_id', versions.first['id']).order('sort'),
    db.from('checklist_template_positions').select('position_id').eq('template_id', id),
    db.from('checklist_schedules').select().eq('template_id', id).order('due_time'),
  ]);
  return _TemplateData(
    t,
    versions,
    (results[0] as List).cast<Map<String, dynamic>>(),
    (results[1] as List).map((r) => r['position_id'] as String).toSet(),
    (results[2] as List).cast<Map<String, dynamic>>(),
  );
});

const _answerTypes = {'yes_no': 'Yes / No', 'number': 'Number', 'text': 'Note', 'photo': 'Photo only'};
const _photoRules = {'none': 'No photo', 'optional': 'Optional', 'required': 'Required'};
const _shifts = {'opening': 'Opening', 'mid': 'Mid-day', 'closing': 'Closing', 'other': 'Other'};
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Checklist template builder: items, positions, brand, what happens on a
/// failed item, and when it runs (A1, A2, A4; design screen 9).
class ChecklistBuilderPage extends ConsumerWidget {
  const ChecklistBuilderPage({super.key, required this.templateId});
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_templateProvider(templateId));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(_templateProvider(templateId))),
      data: (d) => _Builder(data: d),
    );
  }
}

class _Builder extends ConsumerWidget {
  const _Builder({required this.data});
  final _TemplateData data;

  String get id => data.template['id'] as String;

  void _reload(WidgetRef ref) {
    ref.invalidate(_templateProvider(id));
    ref.invalidate(templatesProvider);
  }

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() action, [String? ok]) async {
    if (await runAction(context, action, success: ok)) _reload(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(supabaseProvider);
    final d = data;
    final t = d.template;
    final photos = d.items.where((i) => i['photo_rule'] == 'required' || i['answer_type'] == 'photo').length;
    final archived = t['archived_at'] != null;

    return AdminPage(
      breadcrumb: 'Checklist templates / ${t['name']}',
      title: t['name'] as String,
      subtitle: d.isAudit ? 'Visit audit · started by area managers · findings become issues' : 'Daily checklist',
      actions: [
        Pill('v${d.latest['version']} · ${d.isDraft ? 'draft' : 'published'}', tone: d.isDraft ? Tone.warning : Tone.primary),
        AdminButton(archived ? 'Restore' : 'Archive',
            onPressed: () => _act(context, ref,
                () => db.from('checklist_templates').update({'archived_at': archived ? null : DateTime.now().toUtc().toIso8601String()}).eq('id', id),
                archived ? 'Restored' : 'Archived. No new runs will be created.')),
        if (!d.isDraft) AdminButton('Edit items (new version)', icon: Icons.copy_all_outlined, onPressed: () => _newVersion(context, ref)),
        if (d.isDraft)
          AdminButton('Publish', primary: true, onPressed: d.items.isEmpty ? null : () => _publish(context, ref)),
      ],
      children: [
        Wrap(
          spacing: 20,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSection(child: _Settings(data: d, onSaved: () => _reload(ref))),
                  AdminSection(
                    title: 'Items',
                    trailing: Text('${d.items.length} items · $photos need a photo', style: const TextStyle(color: AppColors.textSecondary)),
                    child: _Items(data: d, onChanged: () => _reload(ref)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!d.isAudit) AdminSection(title: 'Schedule', child: _Schedules(data: d, onChanged: () => _reload(ref))),
                  const AdminSection(
                    title: 'Proof on every submit',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Check('Photos from in-app camera only'),
                        _Check('Server time stamp'),
                        _Check('Submit only inside the outlet area'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final go = await confirmDialog(context,
        title: 'Publish v${data.latest['version']}?',
        message: 'Items are frozen once published. Runs created from tomorrow use this version.',
        confirm: 'Publish');
    if (!go || !context.mounted) return;
    await _act(
      context,
      ref,
      () => ref.read(supabaseProvider).from('checklist_template_versions').update({'published_at': DateTime.now().toUtc().toIso8601String()}).eq('id', data.latest['id']),
      'Published',
    );
  }

  Future<void> _newVersion(BuildContext context, WidgetRef ref) => _act(context, ref, () async {
        final db = ref.read(supabaseProvider);
        final me = ref.read(requireSessionProvider).profile.id;
        final v = await db
            .from('checklist_template_versions')
            .insert({'template_id': id, 'version': (data.latest['version'] as int) + 1, 'created_by': me})
            .select('id')
            .single();
        if (data.items.isNotEmpty) {
          await db.from('checklist_items').insert([
            for (final i in data.items)
              {
                ...Map.of(i)..remove('id')..remove('template_version_id'),
                'template_version_id': v['id'],
              },
          ]);
        }
      }, 'Draft created. Publish it when ready.');
}

class _Check extends StatelessWidget {
  const _Check(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}

class _Settings extends ConsumerStatefulWidget {
  const _Settings({required this.data, required this.onSaved});
  final _TemplateData data;
  final VoidCallback onSaved;

  @override
  ConsumerState<_Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<_Settings> {
  late final _name = TextEditingController(text: t['name'] as String);
  late final _sla = TextEditingController(text: '${t['fail_issue_sla_hours']}');
  late String? _brandId = t['brand_id'] as String?;
  late String _severity = t['fail_issue_severity'] as String;

  Map<String, dynamic> get t => widget.data.template;
  SupabaseClient get db => ref.read(supabaseProvider);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final brands = {for (final o in session.outlets.values) o.brandId: o.brandName ?? ''};
    final positions = ref.watch(positionsProvider).value ?? [];
    Widget box(double w, Widget c) => SizedBox(width: w, child: c);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            box(340, FormText('Name', _name)),
            box(340, DropdownButtonFormField<String?>(
              initialValue: brands.containsKey(_brandId) ? _brandId : null,
              decoration: const InputDecoration(labelText: 'Brands'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All brands')),
                for (final b in brands.entries) DropdownMenuItem(value: b.key, child: Text(b.value)),
              ],
              onChanged: (v) => setState(() => _brandId = v),
            )),
            box(220, DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Failed item raises'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low issue')),
                DropdownMenuItem(value: 'medium', child: Text('Medium issue')),
                DropdownMenuItem(value: 'high', child: Text('High issue')),
              ],
              onChanged: (v) => setState(() => _severity = v ?? 'medium'),
            )),
            box(220, FormText('Fix within (hours)', _sla, number: true)),
            box(
              92,
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () async {
                  final ok = await runAction(
                    context,
                    () => db.from('checklist_templates').update({
                      'name': _name.text.trim(),
                      'brand_id': _brandId,
                      'fail_issue_severity': _severity,
                      'fail_issue_sla_hours': int.tryParse(_sla.text.trim()) ?? 4,
                    }).eq('id', t['id']),
                    success: 'Saved',
                  );
                  if (ok) widget.onSaved();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('A failed item (out of range, "no", missing required photo) raises an issue for the outlet manager, '
            'and escalates to the area manager when it passes this deadline.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (!widget.data.isAudit) ...[
          const SizedBox(height: 16),
          const Text('Positions that fill it', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textStrong)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in positions)
              FilterChip(
                label: Text(p.name),
                selected: widget.data.positions.contains(p.id),
                onSelected: (on) async {
                  final ok = await runAction(context, () async {
                    if (on) {
                      await db.from('checklist_template_positions').insert({'template_id': t['id'], 'position_id': p.id});
                    } else {
                      await db.from('checklist_template_positions').delete().eq('template_id', t['id']).eq('position_id', p.id);
                    }
                  });
                  if (ok) widget.onSaved();
                },
              ),
          ]),
        ],
      ],
    );
  }
}

class _Items extends ConsumerWidget {
  const _Items({required this.data, required this.onChanged});
  final _TemplateData data;
  final VoidCallback onChanged;

  String _failsWhen(Map<String, dynamic> i) {
    final parts = <String>[];
    switch (i['answer_type']) {
      case 'yes_no':
        if (i['fail_on_no'] == true) parts.add('No');
      case 'number':
        final min = i['min_value'], max = i['max_value'];
        if (min != null && max != null) {
          parts.add('Outside $min to $max');
        } else if (min != null) {
          parts.add('Below $min');
        } else if (max != null) {
          parts.add('Above $max');
        }
    }
    if (i['photo_rule'] == 'required') parts.add('no photo');
    return parts.isEmpty ? '–' : parts.join(', or ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(supabaseProvider);
    final editable = data.isDraft;
    final items = data.items;

    Future<void> move(int i, int delta) async {
      final j = i + delta;
      if (j < 0 || j >= items.length) return;
      final ok = await runAction(context, () async {
        await db.from('checklist_items').update({'sort': -1}).eq('id', items[i]['id']);
        await db.from('checklist_items').update({'sort': items[i]['sort']}).eq('id', items[j]['id']);
        await db.from('checklist_items').update({'sort': items[j]['sort']}).eq('id', items[i]['id']);
      });
      if (ok) onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!editable)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InfoBanner(icon: Icons.lock_outline, text: 'Published items are frozen. Use "Edit items (new version)" to change them.'),
          ),
        AdminTable(
          minWidth: 680,
          columns: const ['Item', 'Answer type', 'Fails when', 'Photo', ''],
          rows: [
            for (var k = 0; k < items.length; k++)
              DataRow(
                onSelectChanged: editable ? (_) => _edit(context, ref, items[k]) : null,
                cells: [
                  DataCell(Text(items[k]['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(items[k]['answer_type'] == 'number'
                      ? 'Number${items[k]['unit'] == null ? '' : ', ${items[k]['unit']}'}'
                      : _answerTypes[items[k]['answer_type']]!)),
                  DataCell(Text(_failsWhen(items[k]), style: const TextStyle(color: AppColors.textSecondary))),
                  DataCell(items[k]['photo_rule'] == 'required'
                      ? const Pill('Required', tone: Tone.warning, small: true)
                      : Text(_photoRules[items[k]['photo_rule']]!, style: const TextStyle(color: AppColors.textSecondary))),
                  DataCell(editable
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(tooltip: 'Move up', onPressed: () => move(k, -1), icon: const Icon(Icons.arrow_upward, size: 18)),
                          IconButton(tooltip: 'Move down', onPressed: () => move(k, 1), icon: const Icon(Icons.arrow_downward, size: 18)),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            onPressed: () async {
                              final ok = await runAction(context, () => db.from('checklist_items').delete().eq('id', items[k]['id']));
                              if (ok) onChanged();
                            },
                          ),
                        ])
                      : const SizedBox()),
                ],
              ),
          ],
        ),
        if (editable)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add item · yes/no, number, photo or note'),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [Map<String, dynamic>? i]) async {
    final db = ref.read(supabaseProvider);
    final label = TextEditingController(text: i?['label'] as String?);
    final help = TextEditingController(text: i?['help_text'] as String?);
    final min = TextEditingController(text: i?['min_value']?.toString());
    final max = TextEditingController(text: i?['max_value']?.toString());
    final unit = TextEditingController(text: i?['unit'] as String?);
    String type = (i?['answer_type'] as String?) ?? 'yes_no';
    String photo = (i?['photo_rule'] as String?) ?? 'none';
    bool failOnNo = (i?['fail_on_no'] as bool?) ?? true;

    final ok = await showFormDialog(context,
        title: i == null ? 'New item' : 'Edit item',
        fields: [
          FormText('Item', label, hint: 'e.g. Chiller temperature'),
          FormText('Help text (optional)', help),
          FormSelect<String>('Answer type', items: _answerTypes, initial: type, onChanged: (v) => type = v ?? 'yes_no'),
          Row(children: [
            Expanded(child: FormText('Min (number)', min, number: true)),
            const SizedBox(width: 10),
            Expanded(child: FormText('Max (number)', max, number: true)),
            const SizedBox(width: 10),
            Expanded(child: FormText('Unit', unit, hint: '°C')),
          ]),
          FormSelect<String>('Photo', items: _photoRules, initial: photo, onChanged: (v) => photo = v ?? 'none'),
          FormCheck('"No" fails the item (yes/no)', initial: failOnNo, onChanged: (v) => failOnNo = v),
        ],
        onSave: () async {
          final row = {
            'label': label.text.trim(),
            'help_text': help.text.trim().isEmpty ? null : help.text.trim(),
            'answer_type': type,
            'photo_rule': type == 'photo' ? 'required' : photo,
            'min_value': type == 'number' ? num.tryParse(min.text.trim()) : null,
            'max_value': type == 'number' ? num.tryParse(max.text.trim()) : null,
            'unit': type == 'number' && unit.text.trim().isNotEmpty ? unit.text.trim() : null,
            'fail_on_no': failOnNo,
          };
          if (i == null) {
            final next = data.items.fold<int>(0, (m, x) => (x['sort'] as int) > m ? x['sort'] as int : m) + 1;
            await db.from('checklist_items').insert({...row, 'template_version_id': data.latest['id'], 'sort': next});
          } else {
            await db.from('checklist_items').update(row).eq('id', i['id']);
          }
        });
    if (ok) onChanged();
  }
}

class _Schedules extends ConsumerWidget {
  const _Schedules({required this.data, required this.onChanged});
  final _TemplateData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(requireSessionProvider);
    final db = ref.read(supabaseProvider);
    final brandId = data.template['brand_id'] as String?;
    final outlets = {
      for (final o in session.outlets.values)
        if (brandId == null || o.brandId == brandId) o.id: o.name,
    };

    Future<void> edit([Map<String, dynamic>? s]) async {
      String? outletId = s?['outlet_id'] as String?;
      String shift = (s?['shift'] as String?) ?? 'opening';
      final due = TextEditingController(text: (s?['due_time'] as String?)?.substring(0, 5) ?? '09:00');
      final days = ((s?['days_of_week'] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5, 6, 7]).toSet();
      final ok = await showFormDialog(context,
          title: s == null ? 'Add schedule' : 'Edit schedule',
          fields: [
            FormSelect<String?>('Outlet',
                items: {null: brandId == null ? 'Every outlet' : 'Every outlet of this brand', ...outlets},
                initial: outletId,
                onChanged: (v) => outletId = v),
            FormSelect<String>('Shift', items: _shifts, initial: shift, onChanged: (v) => shift = v ?? 'opening'),
            FormText('Due (outlet local time, HH:MM)', due),
            StatefulBuilder(
              builder: (context, setState) => Wrap(spacing: 6, children: [
                for (var k = 1; k <= 7; k++)
                  FilterChip(
                    label: Text(_days[k - 1]),
                    selected: days.contains(k),
                    onSelected: (on) => setState(() => on ? days.add(k) : days.remove(k)),
                  ),
              ]),
            ),
            const Text('Runs are created each night. Staff get a reminder before the due time; the manager is alerted when one is missed.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          onSave: () async {
            if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(due.text.trim())) throw Exception('Use HH:MM, e.g. 09:00');
            final row = {
              'template_id': data.template['id'],
              'outlet_id': outletId,
              'shift': shift,
              'due_time': due.text.trim(),
              'days_of_week': (days.toList()..sort()),
            };
            if (s == null) {
              await db.from('checklist_schedules').insert(row);
            } else {
              await db.from('checklist_schedules').update(row).eq('id', s['id']);
            }
          });
      if (ok) onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.schedules.isEmpty)
          const Text('Not scheduled. Add when and where it runs.', style: TextStyle(color: AppColors.textSecondary)),
        for (final s in data.schedules)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Switch(
                value: s['active'] as bool,
                onChanged: (v) async {
                  final ok = await runAction(context, () => db.from('checklist_schedules').update({'active': v}).eq('id', s['id']));
                  if (ok) onChanged();
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () => edit(s),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_shifts[s['shift']]} · due ${(s['due_time'] as String).substring(0, 5)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${s['outlet_id'] == null ? 'All outlets' : outlets[s['outlet_id']] ?? 'Outlet'} · '
                      '${(s['days_of_week'] as List).length == 7 ? 'Every day' : (s['days_of_week'] as List).map((d) => _days[(d as int) - 1]).join(' ')}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                onPressed: () async {
                  final ok = await runAction(context, () => db.from('checklist_schedules').delete().eq('id', s['id']));
                  if (ok) onChanged();
                },
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => edit(), icon: const Icon(Icons.add), label: const Text('Add schedule'))),
      ],
    );
  }
}
