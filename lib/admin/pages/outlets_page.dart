import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';

typedef _Named = ({String id, String name, bool archived});

final _brandsProvider = FutureProvider<List<_Named>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('brands').select('id, name, archived_at').order('name');
  return (rows as List).map((r) => (id: r['id'] as String, name: r['name'] as String, archived: r['archived_at'] != null)).toList();
});

final _areasProvider = FutureProvider<List<_Named>>((ref) async {
  final rows = await ref.watch(supabaseProvider).from('areas').select('id, name, archived_at').order('name');
  return (rows as List).map((r) => (id: r['id'] as String, name: r['name'] as String, archived: r['archived_at'] != null)).toList();
});

final _outletsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('outlets')
      .select('id, name, brand_id, area_id, address, latitude, longitude, geofence_radius_m, timezone, archived_at, brands(name), areas(name)')
      .order('name');
  return (rows as List).cast<Map<String, dynamic>>();
});

const _timezones = {'Asia/Jakarta': 'WIB (Asia/Jakarta)', 'Asia/Makassar': 'WITA (Asia/Makassar)', 'Asia/Jayapura': 'WIT (Asia/Jayapura)'};

/// Brands, areas and outlets with the location used for the on-site check (F3).
class OutletsPage extends ConsumerWidget {
  const OutletsPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(_brandsProvider);
    ref.invalidate(_areasProvider);
    ref.invalidate(_outletsProvider);
    ref.invalidate(sessionProvider);
  }

  Future<void> _editNamed(BuildContext context, WidgetRef ref, String table, String label, [_Named? row]) async {
    final name = TextEditingController(text: row?.name);
    final db = ref.read(supabaseProvider);
    final ok = await showFormDialog(context,
        title: row == null ? 'New $label' : 'Edit $label',
        fields: [FormText('Name', name)],
        onSave: () async {
          if (row == null) {
            await db.from(table).insert({'name': name.text.trim()});
          } else {
            await db.from(table).update({'name': name.text.trim()}).eq('id', row.id);
          }
        });
    if (ok) _refresh(ref);
  }

  Future<void> _editOutlet(BuildContext context, WidgetRef ref, [Map<String, dynamic>? o]) async {
    final brands = (ref.read(_brandsProvider).value ?? []).where((b) => !b.archived).toList();
    final areas = (ref.read(_areasProvider).value ?? []).where((a) => !a.archived).toList();
    final name = TextEditingController(text: o?['name'] as String?);
    final address = TextEditingController(text: o?['address'] as String?);
    final lat = TextEditingController(text: o?['latitude']?.toString());
    final lng = TextEditingController(text: o?['longitude']?.toString());
    final radius = TextEditingController(text: '${o?['geofence_radius_m'] ?? 150}');
    String? brandId = o?['brand_id'] as String? ?? brands.firstOrNull?.id;
    String? areaId = o?['area_id'] as String? ?? areas.firstOrNull?.id;
    String tz = (o?['timezone'] as String?) ?? 'Asia/Makassar';
    final db = ref.read(supabaseProvider);

    final ok = await showFormDialog(context,
        title: o == null ? 'New outlet' : 'Edit outlet',
        fields: [
          FormText('Name', name),
          FormSelect<String>('Brand', items: {for (final b in brands) b.id: b.name}, initial: brandId, onChanged: (v) => brandId = v),
          FormSelect<String>('Area', items: {for (final a in areas) a.id: a.name}, initial: areaId, onChanged: (v) => areaId = v),
          FormText('Address', address, maxLines: 2),
          Row(children: [
            Expanded(child: FormText('Latitude', lat, number: true, hint: '-8.650000')),
            const SizedBox(width: 12),
            Expanded(child: FormText('Longitude', lng, number: true, hint: '115.216000')),
          ]),
          FormText('On-site radius (metres)', radius, number: true),
          FormSelect<String>('Time zone', items: _timezones, initial: tz, onChanged: (v) => tz = v ?? tz),
          const Text('Checklists can only be submitted within the radius of this point. Copy the coordinates from Google Maps.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        onSave: () async {
          final row = {
            'name': name.text.trim(),
            'brand_id': brandId,
            'area_id': areaId,
            'address': address.text.trim().isEmpty ? null : address.text.trim(),
            'latitude': double.tryParse(lat.text.trim()),
            'longitude': double.tryParse(lng.text.trim()),
            'geofence_radius_m': int.tryParse(radius.text.trim()) ?? 150,
            'timezone': tz,
          };
          if (o == null) {
            await db.from('outlets').insert(row);
          } else {
            await db.from('outlets').update(row).eq('id', o['id']);
          }
        });
    if (ok) _refresh(ref);
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref, String table, String id, bool archived) async {
    final ok = await runAction(
      context,
      () => ref.read(supabaseProvider).from(table).update({'archived_at': archived ? null : DateTime.now().toUtc().toIso8601String()}).eq('id', id),
      success: archived ? 'Restored' : 'Archived',
    );
    if (ok) _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(_brandsProvider);
    final areas = ref.watch(_areasProvider);
    final outlets = ref.watch(_outletsProvider);

    Widget chips(AsyncValue<List<_Named>> v, String table, String label) => AdminAsync(
          value: v,
          builder: (list) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in list)
                InputChip(
                  label: Text(b.name, style: TextStyle(color: b.archived ? AppColors.textMuted : null)),
                  onPressed: () => _editNamed(context, ref, table, label, b),
                  deleteIcon: Icon(b.archived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                  onDeleted: () => _toggleArchive(context, ref, table, b.id, b.archived),
                ),
              ActionChip(avatar: const Icon(Icons.add, size: 16), label: Text('Add $label'), onPressed: () => _editNamed(context, ref, table, label)),
            ],
          ),
        );

    return AdminPage(
      breadcrumb: 'Setup',
      title: 'Outlets',
      actions: [AdminButton('New outlet', icon: Icons.add, primary: true, onPressed: () => _editOutlet(context, ref))],
      children: [
        Wrap(
          spacing: 20,
          children: [
            SizedBox(width: 460, child: AdminSection(title: 'Brands', child: chips(brands, 'brands', 'brand'))),
            SizedBox(width: 460, child: AdminSection(title: 'Areas', child: chips(areas, 'areas', 'area'))),
          ],
        ),
        AdminSection(
          title: 'Outlets',
          child: AdminAsync(
            value: outlets,
            builder: (list) => AdminTable(
              minWidth: 900,
              columns: const ['Outlet', 'Brand', 'Area', 'Location', 'Radius', 'Time zone', ''],
              rows: [
                for (final o in list)
                  DataRow(
                    onSelectChanged: (_) => _editOutlet(context, ref, o),
                    cells: [
                      DataCell(Text(o['name'] as String,
                          style: TextStyle(fontWeight: FontWeight.w700, color: o['archived_at'] != null ? AppColors.textMuted : null))),
                      DataCell(Text((o['brands'] as Map?)?['name'] as String? ?? '')),
                      DataCell(Text((o['areas'] as Map?)?['name'] as String? ?? '')),
                      DataCell(o['latitude'] == null
                          ? const Pill('Not set · on-site check fails', tone: Tone.danger, small: true)
                          : Text('${o['latitude']}, ${o['longitude']}')),
                      DataCell(Text('${o['geofence_radius_m']} m')),
                      DataCell(Text(_timezones[o['timezone']]?.split(' ').first ?? o['timezone'] as String)),
                      DataCell(IconButton(
                        tooltip: o['archived_at'] == null ? 'Archive' : 'Restore',
                        icon: Icon(o['archived_at'] == null ? Icons.archive_outlined : Icons.unarchive_outlined, size: 18),
                        onPressed: () => _toggleArchive(context, ref, 'outlets', o['id'] as String, o['archived_at'] != null),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
