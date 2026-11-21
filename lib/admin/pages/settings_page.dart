import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/admin_widgets.dart';

final _settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('app_settings').select('key, value');
  return {for (final r in rows as List) r['key'] as String: r['value']};
});

/// System rules read by the server (mentor eligibility, rating privacy,
/// certificate reminders, on-site check).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_settingsProvider);
    return AdminPage(
      breadcrumb: 'System',
      title: 'Settings',
      children: [
        AdminAsync(value: settings, builder: (s) => _Form(settings: s)),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.settings});
  final Map<String, dynamic> settings;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final Map<String, dynamic> _rules = Map<String, dynamic>.from((widget.settings['mentor_rules'] as Map?) ?? {});
  late final _minLevel = TextEditingController(text: '${_rules['min_level'] ?? 2}');
  late final _maxTrainees = TextEditingController(text: '${_rules['max_trainees'] ?? 3}');
  late bool _pathComplete = (_rules['require_path_complete'] as bool?) ?? true;
  late final _ratingMin = TextEditingController(text: '${widget.settings['rating_min_count'] ?? 3}');
  late final _certDays = TextEditingController(text: '${widget.settings['certificate_reminder_days'] ?? 30}');
  late bool _geofence = (widget.settings['require_geofence'] as bool?) ?? true;

  Future<void> _save() async {
    final db = ref.read(supabaseProvider);
    final ok = await runAction(context, () async {
      await db.from('app_settings').upsert([
        {
          'key': 'mentor_rules',
          'value': {
            'min_level': int.parse(_minLevel.text.trim()),
            'max_trainees': int.parse(_maxTrainees.text.trim()),
            'require_path_complete': _pathComplete,
          },
        },
        {'key': 'rating_min_count', 'value': int.parse(_ratingMin.text.trim())},
        {'key': 'certificate_reminder_days', 'value': int.parse(_certDays.text.trim())},
        {'key': 'require_geofence', 'value': _geofence},
      ]);
    }, success: 'Settings saved');
    if (ok) ref.invalidate(_settingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    Widget field(Widget w) => SizedBox(width: 300, child: w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSection(
          title: 'Mentors',
          child: Wrap(spacing: 20, runSpacing: 12, children: [
            field(FormText('Minimum position level', _minLevel, number: true)),
            field(FormText('Most trainees per mentor', _maxTrainees, number: true)),
            SizedBox(
              width: 620,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _pathComplete,
                onChanged: (v) => setState(() => _pathComplete = v),
                title: const Text('Mentor must have finished their own mandatory modules'),
              ),
            ),
            field(FormText('Ratings needed before a mentor sees their average', _ratingMin, number: true)),
          ]),
        ),
        AdminSection(
          title: 'Training',
          child: field(FormText('Remind staff this many days before a certificate expires', _certDays, number: true)),
        ),
        AdminSection(
          title: 'Checklists',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _geofence,
            onChanged: (v) => setState(() => _geofence = v),
            title: const Text('Only accept checklists submitted inside the outlet area'),
            subtitle: const Text('Turn off only for testing. Outlets need a location and radius.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        Align(alignment: Alignment.centerLeft, child: AdminButton('Save settings', primary: true, onPressed: _save)),
      ],
    );
  }
}
