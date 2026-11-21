import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/camera.dart';
import '../../core/media/media_widgets.dart';
import '../../core/offline/connectivity.dart';
import '../../core/widgets/widgets.dart';
import '../session/session_provider.dart';
import 'issue_repository.dart';

/// Raise an issue by hand, with an optional photo (S1).
class RaiseIssueScreen extends ConsumerStatefulWidget {
  const RaiseIssueScreen({super.key});

  @override
  ConsumerState<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class _RaiseIssueScreenState extends ConsumerState<RaiseIssueScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _severity = 'medium';
  String? _outletId;
  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _outletId == null) return;
    setState(() => _saving = true);
    String? id;
    final ok = await runAction(context, () async {
      id = await ref.read(issueRepositoryProvider).raise(
            outletId: _outletId!,
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            severity: _severity,
            photo: _photo,
          );
      invalidateIssues(ref, outletId: _outletId);
    }, success: context.l10n.issueRaised);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok && id != null) context.pushReplacement('/issues/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(requireSessionProvider);
    final outlets = session.outletsWith('issue.create');
    _outletId ??= outlets.where((o) => o.id == session.profile.outletId).firstOrNull?.id ?? outlets.firstOrNull?.id;
    final online = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.raiseIssue)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!online) ...[
            InfoBanner(icon: Icons.wifi_off_rounded, text: l10n.needConnectionToSend),
            const SizedBox(height: 12),
          ],
          if (outlets.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _outletId,
              decoration: InputDecoration(labelText: l10n.outlet),
              items: [for (final o in outlets) DropdownMenuItem(value: o.id, child: Text(o.name))],
              onChanged: (v) => setState(() => _outletId = v),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.whatIsWrong, hintText: l10n.whatIsWrongHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.detailsOptional, alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          Text(l10n.howUrgent, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'low', label: Text(l10n.severityLow)),
              ButtonSegment(value: 'medium', label: Text(l10n.severityMedium)),
              ButtonSegment(value: 'high', label: Text(l10n.severityHigh)),
            ],
            selected: {_severity},
            onSelectionChanged: (s) => setState(() => _severity = s.first),
          ),
          const SizedBox(height: 6),
          Text(l10n.fixWithinHours(slaHoursFor(_severity)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (_photo != null)
            LocalPhoto(_photo!.path, height: 180, onRemove: () => setState(() => _photo = null))
          else
            OutlinedButton.icon(
              onPressed: () async {
                final p = await capturePhoto();
                if (p != null) setState(() => _photo = p);
              },
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.addPhoto),
            ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton(
          onPressed: _saving || !online || _title.text.trim().isEmpty || _outletId == null ? null : _save,
          child: Text(l10n.raiseIssue),
        ),
      ),
    );
  }
}
