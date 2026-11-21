import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/format.dart';
import '../../features/session/models.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';
import 'roles_page.dart';

final _usersProvider = FutureProvider<List<Profile>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('profiles').select(Profile.select).order('full_name');
  return (rows as List).map((r) => Profile.fromJson(r as Map<String, dynamic>)).toList();
});

final positionsProvider = FutureProvider<List<({String id, String name, int level, String department})>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('positions')
      .select('id, name, level, departments(name)')
      .isFilter('archived_at', null)
      .order('name');
  return (rows as List)
      .map((r) => (
            id: r['id'] as String,
            name: r['name'] as String,
            level: r['level'] as int,
            department: ((r['departments'] as Map?)?['name'] as String?) ?? '',
          ))
      .toList();
});

/// Grants for one user (needs role.manage).
final _grantsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('user_roles')
      .select('id, scope_type, scope_id, granted_at, expires_at, roles(id, name)')
      .eq('user_id', userId)
      .order('granted_at');
  return (rows as List).cast<Map<String, dynamic>>();
});

/// Users: create one or import a spreadsheet, edit job details, deactivate,
/// and grant roles with a scope (F4, R2, R4, R8).
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  String _query = '';
  String? _outletId;
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final canManage = session.hasGroup('user.manage');
    final canRoles = session.hasGroup('role.manage');
    final users = ref.watch(_usersProvider);
    final outlets = session.outlets;

    return AdminPage(
      breadcrumb: 'Setup',
      title: 'Users and roles',
      subtitle: 'Position and level describe the job. Roles decide what someone can do in ASAH.',
      actions: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or phone'),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String?>(
            initialValue: _outletId,
            decoration: const InputDecoration(labelText: 'Outlet'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All outlets')),
              for (final o in outlets.values) DropdownMenuItem(value: o.id, child: Text(o.name)),
            ],
            onChanged: (v) => setState(() => _outletId = v),
          ),
        ),
        FilterChip(label: const Text('Inactive'), selected: _showInactive, onSelected: (v) => setState(() => _showInactive = v)),
        if (canManage) AdminButton('Import spreadsheet', icon: Icons.upload_file_outlined, onPressed: _import),
        if (canManage) AdminButton('Add user', icon: Icons.person_add_alt_1_outlined, primary: true, onPressed: () => _edit()),
      ],
      children: [
        AdminSection(
          child: AdminAsync(
            value: users,
            onRetry: () => ref.invalidate(_usersProvider),
            builder: (all) {
              final list = all
                  .where((u) =>
                      (_showInactive || u.active) &&
                      (_outletId == null || u.outletId == _outletId) &&
                      (_query.isEmpty || u.fullName.toLowerCase().contains(_query) || (u.phone ?? '').contains(_query)))
                  .toList();
              return AdminTable(
                minWidth: 900,
                columns: const ['Name', 'Phone', 'Position', 'Outlet', 'Started', 'Status', ''],
                rows: [
                  for (final u in list)
                    DataRow(cells: [
                      DataCell(Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text(u.phone ?? '')),
                      DataCell(Text([u.positionName, if (u.positionLevel != null) 'L${u.positionLevel}'].whereType<String>().join(' · '))),
                      DataCell(Text(outlets[u.outletId]?.name ?? '–')),
                      DataCell(Text(u.hireDate == null ? '–' : Fmt.day(u.hireDate!))),
                      DataCell(StatusChip(u.active ? 'active' : 'inactive')),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        if (canRoles)
                          IconButton(tooltip: 'Roles', icon: const Icon(Icons.admin_panel_settings_outlined, size: 18), onPressed: () => _roles(u)),
                        if (canManage) IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _edit(u)),
                        if (canManage)
                          IconButton(
                            tooltip: u.active ? 'Deactivate' : 'Reactivate',
                            icon: Icon(u.active ? Icons.person_off_outlined : Icons.person_outline, size: 18),
                            onPressed: () => _toggleActive(u),
                          ),
                      ])),
                    ]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _edit([Profile? u]) async {
    final session = ref.read(requireSessionProvider);
    final positions = await ref.read(positionsProvider.future);
    if (!mounted) return;
    final name = TextEditingController(text: u?.fullName);
    final phone = TextEditingController(text: u?.phone);
    final hire = TextEditingController(text: u?.hireDate == null ? Fmt.isoDate(DateTime.now()) : Fmt.isoDate(u!.hireDate!));
    String? outletId = u?.outletId;
    String? positionId = u?.positionId;
    String locale = u?.locale ?? 'id';
    final db = ref.read(supabaseProvider);

    final ok = await showFormDialog(context,
        title: u == null ? 'Add user' : 'Edit ${u.fullName}',
        save: u == null ? 'Create' : 'Save',
        fields: [
          FormText('Full name', name),
          if (u == null) FormText('Phone number', phone, hint: '0812 3456 7890'),
          FormSelect<String>('Outlet',
              items: {for (final o in session.outlets.values) o.id: '${o.name} · ${o.brandName ?? ''}'},
              initial: outletId,
              onChanged: (v) => outletId = v),
          FormSelect<String>('Position',
              items: {for (final p in positions) p.id: '${p.department} · ${p.name} (L${p.level})'},
              initial: positionId,
              onChanged: (v) => positionId = v),
          FormText('First day (YYYY-MM-DD)', hire),
          FormSelect<String>('Language', items: const {'id': 'Bahasa Indonesia', 'en': 'English'}, initial: locale,
              onChanged: (v) => locale = v ?? 'id'),
          if (u == null)
            const Text('New users get only the Staff role at their outlet. The learning path for the position is assigned automatically.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (u != null)
            const Text('Changing position assigns the new learning path. Changing outlet ends current mentorships.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        onSave: () async {
          if (u == null) {
            final res = await db.functions.invoke('admin-users', body: {
              'users': [
                {
                  'full_name': name.text.trim(),
                  'phone': phone.text.trim(),
                  'outlet_id': outletId,
                  'position_id': positionId,
                  'hire_date': hire.text.trim().isEmpty ? null : hire.text.trim(),
                  'locale': locale,
                }
              ]
            });
            final r = ((res.data as Map)['results'] as List).first as Map;
            if (r['ok'] != true) throw Exception(r['error']);
          } else {
            await db.from('profiles').update({
              'full_name': name.text.trim(),
              'outlet_id': outletId,
              'position_id': positionId,
              'hire_date': hire.text.trim().isEmpty ? null : hire.text.trim(),
              'locale': locale,
            }).eq('id', u.id);
          }
        });
    if (ok) ref.invalidate(_usersProvider);
  }

  Future<void> _toggleActive(Profile u) async {
    if (u.active) {
      final go = await confirmDialog(context,
          title: 'Deactivate ${u.fullName}?',
          message: 'They lose access at once. Their roles are removed and their mentorships end. Records stay.',
          confirm: 'Deactivate');
      if (!go) return;
    }
    if (!mounted) return;
    final ok = await runAction(
      context,
      () => ref.read(supabaseProvider).from('profiles').update({'status': u.active ? 'inactive' : 'active'}).eq('id', u.id),
      success: u.active ? 'Deactivated' : 'Reactivated. Grant their roles again.',
    );
    if (ok) ref.invalidate(_usersProvider);
  }

  Future<void> _roles(Profile u) async {
    await showDialog(context: context, builder: (_) => _RolesDialog(user: u));
  }

  /// Bulk import (F4): columns name, phone, outlet, position, first_day.
  Future<void> _import() async {
    final session = ref.read(requireSessionProvider);
    final positions = await ref.read(positionsProvider.future);
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['csv']);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    // Delimiter is auto-detected, so Excel's semicolon exports work too.
    final table = Csv().decode(utf8.decode(bytes).replaceFirst('\uFEFF', ''));
    if (table.length < 2) {
      showSnack(context, 'The file has no rows.', error: true);
      return;
    }
    final header = table.first.map((c) => c.toString().trim().toLowerCase()).toList();
    int col(List<String> names) => header.indexWhere((h) => names.contains(h));
    final iName = col(['name', 'full_name', 'nama']);
    final iPhone = col(['phone', 'nomor hp', 'hp', 'phone_number']);
    final iOutlet = col(['outlet']);
    final iPosition = col(['position', 'posisi', 'jabatan']);
    final iDay = col(['first_day', 'hire_date', 'start', 'tanggal masuk']);
    if (iName < 0 || iPhone < 0) {
      showSnack(context, 'Columns needed: name, phone, outlet, position, first_day', error: true);
      return;
    }

    String? find(Map<String, String> byName, String? v) => v == null ? null : byName[v.trim().toLowerCase()];
    final outletByName = {for (final o in session.outlets.values) o.name.toLowerCase(): o.id};
    final positionByName = {for (final p in positions) p.name.toLowerCase(): p.id};

    final rows = <Map<String, dynamic>>[];
    final problems = <String>[];
    for (var r = 1; r < table.length; r++) {
      final line = table[r].map((c) => c.toString()).toList();
      String? cell(int i) => i < 0 || i >= line.length || line[i].trim().isEmpty ? null : line[i].trim();
      if (line.every((c) => c.trim().isEmpty)) continue;
      final outletId = find(outletByName, cell(iOutlet));
      final positionId = find(positionByName, cell(iPosition));
      if (cell(iOutlet) != null && outletId == null) problems.add('Row ${r + 1}: unknown outlet "${cell(iOutlet)}"');
      if (cell(iPosition) != null && positionId == null) problems.add('Row ${r + 1}: unknown position "${cell(iPosition)}"');
      rows.add({
        'full_name': cell(iName) ?? '',
        'phone': cell(iPhone) ?? '',
        'outlet_id': outletId,
        'position_id': positionId,
        'hire_date': cell(iDay),
      });
    }
    if (!mounted) return;

    final go = await confirmDialog(context,
        title: 'Import ${rows.length} users?',
        message: problems.isEmpty
            ? 'Each gets the Staff role at their outlet and the learning path of their position.'
            : '${problems.take(8).join('\n')}${problems.length > 8 ? '\n…' : ''}\n\nRows with unknown values are imported without them.',
        confirm: 'Import');
    if (!go || !mounted) return;

    try {
      final res = await ref.read(supabaseProvider).functions.invoke('admin-users', body: {'users': rows});
      final results = ((res.data as Map)['results'] as List).cast<Map>();
      final failed = results.where((r) => r['ok'] != true).toList();
      ref.invalidate(_usersProvider);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${results.length - failed.length} of ${results.length} imported'),
          content: failed.isEmpty
              ? const Text('All users were created.')
              : SizedBox(
                  width: 480,
                  child: SingleChildScrollView(child: Text(failed.map((f) => '${f['phone']}: ${f['error']}').join('\n'))),
                ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }
}

class _RolesDialog extends ConsumerWidget {
  const _RolesDialog({required this.user});
  final Profile user;

  String _scopeName(Session s, Map<String, dynamic> g, Map<String, String> names) {
    final type = g['scope_type'] as String;
    if (type == 'group') return 'Whole group';
    return '${type[0].toUpperCase()}${type.substring(1)}: ${names[g['scope_id']] ?? s.outlets[g['scope_id']]?.name ?? g['scope_id']}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(requireSessionProvider);
    final grants = ref.watch(_grantsProvider(user.id));
    final names = <String, String>{
      for (final o in session.outlets.values) ...{o.brandId: o.brandName ?? '', o.areaId: o.areaName ?? '', o.id: o.name},
    };
    return AlertDialog(
      title: Text('Roles · ${user.fullName}'),
      content: SizedBox(
        width: 560,
        child: AdminAsync(
          value: grants,
          builder: (list) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (list.isEmpty) const Text('No roles. This person cannot do anything in ASAH yet.'),
              for (final g in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((g['roles'] as Map)['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_scopeName(session, g, names)),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                    onPressed: () async {
                      final ok = await runAction(context, () => ref.read(supabaseProvider).from('user_roles').delete().eq('id', g['id']),
                          success: 'Role removed');
                      if (ok) ref.invalidate(_grantsProvider(user.id));
                    },
                  ),
                ),
              const SizedBox(height: 8),
              const Text('Every change is written to the audit log.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => _grant(context, ref, session, names),
          child: const Text('Grant role'),
        ),
      ],
    );
  }

  Future<void> _grant(BuildContext context, WidgetRef ref, Session session, Map<String, String> names) async {
    final roles = await ref.read(rolesProvider.future);
    if (!context.mounted) return;
    String? roleId = roles.firstOrNull?['id'] as String?;
    String scopeType = 'outlet';
    String? scopeId = user.outletId;
    final brands = {for (final o in session.outlets.values) o.brandId: o.brandName ?? ''};
    final areas = {for (final o in session.outlets.values) o.areaId: o.areaName ?? ''};
    final outlets = {for (final o in session.outlets.values) o.id: o.name};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final scopeItems = switch (scopeType) { 'brand' => brands, 'area' => areas, 'outlet' => outlets, _ => <String, String>{} };
          if (scopeType != 'group' && !scopeItems.containsKey(scopeId)) scopeId = scopeItems.keys.firstOrNull;
          return AlertDialog(
            title: const Text('Grant role'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: roleId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: [
                      for (final r in roles)
                        DropdownMenuItem(value: r['id'] as String, child: Text(r['name'] as String)),
                    ],
                    onChanged: (v) => setState(() => roleId = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: scopeType,
                    decoration: const InputDecoration(labelText: 'Scope'),
                    items: const [
                      DropdownMenuItem(value: 'outlet', child: Text('One outlet')),
                      DropdownMenuItem(value: 'area', child: Text('One area')),
                      DropdownMenuItem(value: 'brand', child: Text('One brand')),
                      DropdownMenuItem(value: 'group', child: Text('Whole group')),
                    ],
                    onChanged: (v) => setState(() => scopeType = v ?? 'outlet'),
                  ),
                  if (scopeType != 'group') ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(scopeType),
                      initialValue: scopeId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: scopeType[0].toUpperCase() + scopeType.substring(1)),
                      items: [for (final e in scopeItems.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                      onChanged: (v) => setState(() => scopeId = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Grant'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || roleId == null || !context.mounted) return;
    final done = await runAction(
      context,
      () => ref.read(supabaseProvider).from('user_roles').insert({
        'user_id': user.id,
        'role_id': roleId,
        'scope_type': scopeType,
        'scope_id': scopeType == 'group' ? null : scopeId,
        'granted_by': session.profile.id,
      }),
      success: 'Role granted',
    );
    if (done) ref.invalidate(_grantsProvider(user.id));
  }
}
