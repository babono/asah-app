import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';

final modulesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('modules')
      .select('id, category, archived_at, module_versions!module_versions_module_id_fkey(id, version, status, title, author_id, updated_at)')
      .order('created_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
});

Map<String, dynamic>? latestVersion(Map<String, dynamic> module) {
  final vs = (module['module_versions'] as List).cast<Map<String, dynamic>>()
    ..sort((a, b) => (b['version'] as int).compareTo(a['version'] as int));
  return vs.firstOrNull;
}

/// Learning modules: drafts, review queue and published modules (T1, T4, T5).
class ModulesPage extends ConsumerStatefulWidget {
  const ModulesPage({super.key});

  @override
  ConsumerState<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends ConsumerState<ModulesPage> {
  String _query = '';

  Future<void> _create() async {
    final title = TextEditingController();
    final category = TextEditingController();
    final db = ref.read(supabaseProvider);
    final me = ref.read(requireSessionProvider).profile.id;
    String? id;
    final ok = await showFormDialog(context,
        title: 'New module',
        save: 'Create',
        fields: [FormText('Title', title, hint: 'e.g. Table setting'), FormText('Category', category, hint: 'e.g. Service, Kitchen, Food safety')],
        onSave: () async {
          final m = await db.from('modules').insert({'category': category.text.trim(), 'created_by': me}).select('id').single();
          id = m['id'] as String;
          await db.from('module_versions').insert({
            'module_id': id,
            'version': 1,
            'status': 'draft',
            'title': title.text.trim(),
            'author_id': me,
          });
        });
    if (ok && id != null && mounted) {
      ref.invalidate(modulesListProvider);
      context.go('/modules/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final modules = ref.watch(modulesListProvider);
    final canAuthor = session.hasGroup('module.author');
    final canReview = session.hasGroup('module.review');

    return AdminPage(
      breadcrumb: 'Asuh',
      title: 'Learning modules',
      subtitle: 'Trainers write modules; a training manager reviews and publishes them. Authors cannot approve their own.',
      actions: [
        SizedBox(
          width: 240,
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search modules'),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        if (canAuthor) AdminButton('New module', icon: Icons.add, primary: true, onPressed: _create),
      ],
      children: [
        AdminAsync(
          value: modules,
          onRetry: () => ref.invalidate(modulesListProvider),
          builder: (all) {
            final list = all
                .where((m) => m['archived_at'] == null)
                .where((m) => _query.isEmpty || '${latestVersion(m)?['title']} ${m['category']}'.toLowerCase().contains(_query))
                .toList();
            final inReview = list.where((m) => latestVersion(m)?['status'] == 'in_review').toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canReview && inReview.isNotEmpty)
                  AdminSection(
                    title: 'Waiting for your review',
                    child: Column(
                      children: [
                        for (final m in inReview)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const IconTile(Icons.rate_review_outlined, tone: Tone.info, size: 40),
                            title: Text(latestVersion(m)!['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${m['category']} · version ${latestVersion(m)!['version']}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go('/modules/${m['id']}'),
                          ),
                      ],
                    ),
                  ),
                AdminSection(
                  child: AdminTable(
                    columns: const ['Module', 'Category', 'Version', 'Status', 'Updated'],
                    rows: [
                      for (final m in list)
                        if (latestVersion(m) case final v?)
                          DataRow(
                            onSelectChanged: (_) => context.go('/modules/${m['id']}'),
                            cells: [
                              DataCell(Text(v['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(m['category'] as String)),
                              DataCell(Text('v${v['version']}')),
                              DataCell(StatusChip(v['status'] as String)),
                              DataCell(Text(Fmt.day(DateTime.parse(v['updated_at'] as String)),
                                  style: const TextStyle(color: AppColors.textSecondary))),
                            ],
                          ),
                    ],
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
