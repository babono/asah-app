import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../widgets/admin_widgets.dart';

final _mentorsProvider = FutureProvider<List<({String id, String name})>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('mentorships')
      .select('mentor_id, mentor:profiles!mentorships_mentor_id_fkey(full_name)');
  final out = <String, String>{};
  for (final r in rows as List) {
    out[r['mentor_id'] as String] = ((r['mentor'] as Map?)?['full_name'] as String?) ?? '';
  }
  final list = out.entries.map((e) => (id: e.key, name: e.value)).toList()..sort((a, b) => a.name.compareTo(b.name));
  return list;
});

/// Who rated a mentor: HR and senior management only, and every view is
/// logged (M7, R5).
class MentorRatingsPage extends ConsumerStatefulWidget {
  const MentorRatingsPage({super.key});

  @override
  ConsumerState<MentorRatingsPage> createState() => _MentorRatingsPageState();
}

class _MentorRatingsPageState extends ConsumerState<MentorRatingsPage> {
  String? _mentorId;
  List<Map<String, dynamic>>? _ratings;
  bool _loading = false;

  Future<void> _load(String mentorId) async {
    setState(() {
      _mentorId = mentorId;
      _loading = true;
      _ratings = null;
    });
    final ok = await runAction(context, () async {
      final rows = await ref.read(supabaseProvider).rpc('mentor_ratings_with_raters', params: {'p_mentor': mentorId});
      _ratings = (rows as List).cast<Map<String, dynamic>>();
    });
    if (mounted) setState(() => _loading = false);
    if (!ok) _ratings = null;
  }

  @override
  Widget build(BuildContext context) {
    final mentors = ref.watch(_mentorsProvider);
    final avg = _ratings == null || _ratings!.isEmpty
        ? null
        : _ratings!.fold<num>(0, (s, r) => s + (r['score'] as num)) / _ratings!.length;
    return AdminPage(
      breadcrumb: 'Asuh',
      title: 'Mentor ratings',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: InfoBanner(
            icon: Icons.visibility_outlined,
            text: 'Ratings are anonymous to mentors. Opening a mentor here shows who rated them and is written to the access log with your name.',
          ),
        ),
        AdminSection(
          child: AdminAsync(
            value: mentors,
            builder: (list) => Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in list) ChoiceChip(label: Text(m.name), selected: _mentorId == m.id, onSelected: (_) => _load(m.id)),
              if (list.isEmpty) const Text('No mentors yet.'),
            ]),
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_ratings != null)
          AdminSection(
            title: avg == null ? 'No ratings yet' : 'Average ${avg.toStringAsFixed(1)} from ${_ratings!.length}',
            child: AdminTable(
              columns: const ['Score', 'Rated by', 'Comment', 'Date'],
              rows: [
                for (final r in _ratings!)
                  DataRow(cells: [
                    DataCell(Text('★ ${r['score']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning))),
                    DataCell(Text(r['rater_name'] as String? ?? '')),
                    DataCell(Text(r['comment'] as String? ?? '')),
                    DataCell(Text(Fmt.day(DateTime.parse(r['created_at'] as String)))),
                  ]),
              ],
            ),
          ),
      ],
    );
  }
}
