import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/admin_widgets.dart';

final rolesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('roles')
      .select('id, name, description, is_system, role_permissions(permission_code)')
      .order('is_system', ascending: false)
      .order('name');
  return (rows as List).cast<Map<String, dynamic>>();
});

final _permissionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('permissions').select('code, description, is_sensitive').order('code');
  return (rows as List).cast<Map<String, dynamic>>();
});

/// Roles are named bundles of permissions (R1, R3). Sensitive permissions are
/// marked; every change is logged (R5, F9).
class RolesPage extends ConsumerStatefulWidget {
  const RolesPage({super.key});

  @override
  ConsumerState<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends ConsumerState<RolesPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider);
    final perms = ref.watch(_permissionsProvider);

    return AdminPage(
      breadcrumb: 'Setup',
      title: 'Roles and permissions',
      subtitle: 'A new user has only the Staff role. Nothing is granted by default.',
      actions: [AdminButton('New role', icon: Icons.add, primary: true, onPressed: _newRole)],
      children: [
        AdminAsync(
          value: roles,
          onRetry: () => ref.invalidate(rolesProvider),
          builder: (rs) {
            _selected ??= rs.firstOrNull?['id'] as String?;
            final role = rs.where((r) => r['id'] == _selected).firstOrNull;
            return Wrap(
              spacing: 20,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: AdminSection(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final r in rs)
                          ListTile(
                            selected: r['id'] == _selected,
                            selectedTileColor: AppColors.primarySoft,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${(r['role_permissions'] as List).length} permissions${r['is_system'] == true ? ' · default' : ''}'),
                            onTap: () => setState(() => _selected = r['id'] as String),
                          ),
                      ],
                    ),
                  ),
                ),
                if (role != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AdminSection(
                      title: role['name'] as String,
                      child: AdminAsync(
                        value: perms,
                        builder: (ps) {
                          final has = (role['role_permissions'] as List).map((p) => p['permission_code'] as String).toSet();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (role['description'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(role['description'] as String, style: const TextStyle(color: AppColors.textSecondary)),
                                ),
                              for (final p in ps)
                                CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: has.contains(p['code']),
                                  title: Row(children: [
                                    Text(p['code'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                    if (p['is_sensitive'] == true) ...[
                                      const SizedBox(width: 8),
                                      const Pill('Sensitive · logged', tone: Tone.warning, small: true),
                                    ],
                                  ]),
                                  subtitle: Text(p['description'] as String),
                                  onChanged: (v) => _toggle(role['id'] as String, p['code'] as String, v ?? false),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggle(String roleId, String code, bool on) async {
    final db = ref.read(supabaseProvider);
    final ok = await runAction(context, () async {
      if (on) {
        await db.from('role_permissions').insert({'role_id': roleId, 'permission_code': code});
      } else {
        await db.from('role_permissions').delete().eq('role_id', roleId).eq('permission_code', code);
      }
    });
    if (ok) ref.invalidate(rolesProvider);
  }

  Future<void> _newRole() async {
    final name = TextEditingController();
    final description = TextEditingController();
    String? id;
    final ok = await showFormDialog(context,
        title: 'New role',
        fields: [FormText('Name', name), FormText('What it is for, and the scope to grant it at', description, maxLines: 2)],
        onSave: () async {
          final row = await ref
              .read(supabaseProvider)
              .from('roles')
              .insert({'name': name.text.trim(), 'description': description.text.trim()})
              .select('id')
              .single();
          id = row['id'] as String;
        });
    if (ok) {
      ref.invalidate(rolesProvider);
      setState(() => _selected = id);
    }
  }
}
