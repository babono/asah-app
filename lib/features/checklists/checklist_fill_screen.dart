import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/camera.dart';
import '../../core/media/media_widgets.dart';
import '../../core/offline/connectivity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/location.dart';
import '../../core/widgets/widgets.dart';
import '../session/session_provider.dart';
import '../sync/sync_service.dart';
import 'checklist_repository.dart';
import 'draft_store.dart';
import 'models.dart';
import 'run_detail_screen.dart';

/// Fill a checklist or audit (PRD A3, A4, A6, F7; design screen 2).
class ChecklistFillScreen extends ConsumerWidget {
  const ChecklistFillScreen({super.key, required this.runId});
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider(runId));
    return run.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AsyncBody(value: run, builder: (_) => const SizedBox(), onRetry: () => ref.invalidate(runProvider(runId))),
      ),
      data: (r) {
        final pendingSync = ref.watch(syncProvider.select((s) => s.hasPendingSubmit(runId)));
        if (!r.isOpen && !pendingSync) return RunDetailScreen(runId: runId);
        final items = ref.watch(runItemsProvider(r.templateVersionId));
        return items.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: AsyncBody(
                value: items,
                builder: (_) => const SizedBox(),
                onRetry: () => ref.invalidate(runItemsProvider(r.templateVersionId))),
          ),
          data: (list) => _FillForm(run: r, items: list, pendingSync: pendingSync),
        );
      },
    );
  }
}

class _FillForm extends ConsumerStatefulWidget {
  const _FillForm({required this.run, required this.items, required this.pendingSync});
  final ChecklistRun run;
  final List<ChecklistItem> items;
  final bool pendingSync;

  @override
  ConsumerState<_FillForm> createState() => _FillFormState();
}

class _FillFormState extends ConsumerState<_FillForm> {
  late Map<String, Answer> _answers;
  final _numberControllers = <String, TextEditingController>{};
  final _textControllers = <String, TextEditingController>{};
  bool _submitting = false;
  bool _showMissing = false;

  @override
  void initState() {
    super.initState();
    _answers = ref.read(checklistDraftStoreProvider).load(widget.run.id);
    for (final item in widget.items) {
      final a = _answers[item.id];
      if (item.answerType == AnswerType.number) {
        _numberControllers[item.id] = TextEditingController(text: a?.number?.toString() ?? '');
      }
      if (item.answerType == AnswerType.text) {
        _textControllers[item.id] = TextEditingController(text: a?.text ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in [..._numberControllers.values, ..._textControllers.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Answer _answer(String itemId) => _answers.putIfAbsent(itemId, Answer.new);

  void _update(VoidCallback change) {
    setState(change);
    unawaited(ref.read(checklistDraftStoreProvider).save(widget.run.id, _answers));
  }

  int get _doneCount => widget.items.where((i) => _answers[i.id]?.isComplete(i) ?? false).length;
  int get _issueCount => widget.items.where((i) => _answers[i.id]?.fails(i) ?? false).length;

  Future<void> _takePhoto(ChecklistItem item) async {
    final photo = await capturePhoto();
    if (photo == null) return;
    _update(() => _answer(item.id).photoPaths.add(photo.path));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final missing = widget.items.where((i) => !(_answers[i.id]?.isComplete(i) ?? false)).length;
    if (missing > 0) {
      setState(() => _showMissing = true);
      showSnack(context, l10n.itemsStillMissing(missing), error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      // Location first: it is needed even offline, and GPS works without data.
      double? lat, lng;
      try {
        final pos = await currentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } on LocationUnavailable catch (e) {
        if (!mounted) return;
        showSnack(context, e.reason == 'denied' ? l10n.locationDenied : l10n.locationOff, error: true);
        return;
      }

      final outlet = ref.read(sessionProvider).value?.outlets[widget.run.outletId];
      if (outlet?.latitude != null && outlet?.longitude != null) {
        final d = distanceMeters(lat, lng, outlet!.latitude!, outlet.longitude!);
        if (d > outlet.geofenceRadiusM && mounted) {
          final go = await confirmDialog(context,
              title: l10n.outsideOutletTitle, message: l10n.outsideOutletBody(outlet.name, d.round()), confirm: l10n.submitAnyway);
          if (!go) return;
        }
      }

      final sync = ref.read(syncProvider.notifier);
      final job = await sync.enqueue('checklist_submit', {
        'label': widget.run.templateName,
        'run_id': widget.run.id,
        'outlet_id': widget.run.outletId,
        'answers': _answers.map((k, v) => MapEntry(k, v.toJson())),
        'lat': lat,
        'lng': lng,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      });

      final online = ref.read(isOnlineProvider).value ?? true;
      if (!online) {
        if (mounted) {
          showSnack(context, l10n.savedOfflineWillSync);
          context.pop();
        }
        return;
      }

      final result = await sync.run(job.id);
      if (!mounted) return;
      switch (result.outcome) {
        case JobOutcome.done:
          final failed = result.data?['failed'] as int? ?? 0;
          showSnack(context, failed > 0 ? l10n.submittedWithIssues(failed) : l10n.submittedThanks);
          ref.invalidate(myRunsTodayProvider);
          context.pop();
        case JobOutcome.retryLater:
          showSnack(context, l10n.savedOfflineWillSync);
          context.pop();
        case JobOutcome.failed:
          await sync.discard(job.id); // keep the draft so the person can fix and retry
          if (mounted) showSnack(context, result.message ?? l10n.somethingWentWrong, error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final run = widget.run;
    final total = widget.items.length;
    final online = ref.watch(isOnlineProvider).value ?? true;
    final outletName = ref.watch(sessionProvider).value?.outlets[run.outletId]?.name ?? '';
    final locked = widget.pendingSync;

    return Scaffold(
      appBar: AppBar(
        title: TwoLineTitle(run.templateName, l10n.doneOfDue(_doneCount, total, Fmt.time(run.dueAt))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: ProgressBar(value: total == 0 ? 0 : _doneCount / total),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoBanner(icon: Icons.cloud_upload_outlined, text: l10n.waitingToSync),
            )
          else if (!online)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoBanner(icon: Icons.wifi_off_rounded, text: l10n.offlineAnswersSaved),
            ),
          for (var i = 0; i < widget.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AbsorbPointer(absorbing: locked, child: _itemCard(i + 1, widget.items[i])),
            ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l10n.timeLocationAdded(outletName),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submitting || locked ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_issueCount > 0 ? l10n.submitRaisesIssues(_issueCount) : l10n.submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(int number, ChecklistItem item) {
    final l10n = context.l10n;
    final a = _answers[item.id];
    final fails = a?.fails(item) ?? false;
    final incomplete = _showMissing && !(a?.isComplete(item) ?? false);

    return AppCard(
      radius: 16,
      borderColor: incomplete ? AppColors.danger : AppColors.border,
      borderWidth: incomplete ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('$number · ${item.label}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (item.needsPhoto) ...[
                const SizedBox(width: 8),
                Pill(l10n.photoRequired, tone: Tone.warning, small: true),
              ],
            ],
          ),
          if (item.helpText != null) ...[
            const SizedBox(height: 4),
            Text(item.helpText!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          ..._input(item, a),
          if (item.allowsPhoto && item.answerType != AnswerType.photo) ...[
            const SizedBox(height: 12),
            _photos(item, a),
          ],
          if (item.answerType == AnswerType.photo) _photos(item, a),
          if (fails) ...[
            const SizedBox(height: 10),
            Text(
              item.answerType == AnswerType.number ? l10n.outOfRangeRaisesIssue : l10n.raisesIssue,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _input(ChecklistItem item, Answer? a) {
    final l10n = context.l10n;
    switch (item.answerType) {
      case AnswerType.yesNo:
        return [
          Row(children: [
            Expanded(
              child: ChoiceButton(
                label: l10n.yes,
                selected: a?.yes == true,
                onTap: () => _update(() => _answer(item.id).yes = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceButton(
                label: l10n.no,
                negative: item.failOnNo,
                selected: a?.yes == false,
                onTap: () => _update(() => _answer(item.id).yes = false),
              ),
            ),
          ]),
        ];
      case AnswerType.number:
        final fails = a?.fails(item) ?? false;
        String? range;
        if (item.minValue != null && item.maxValue != null) {
          range = l10n.allowedRange('${item.minValue}', '${item.maxValue}', item.unit ?? '');
        } else if (item.minValue != null) {
          range = l10n.allowedMin('${item.minValue}', item.unit ?? '');
        } else if (item.maxValue != null) {
          range = l10n.allowedMax('${item.maxValue}', item.unit ?? '');
        }
        return [
          Row(children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _numberControllers[item.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[.,]?\d*'))],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  suffixText: item.unit,
                  fillColor: fails ? AppColors.dangerSoft : AppColors.surface,
                  enabledBorder: fails
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.danger, width: 1.5))
                      : null,
                ),
                onChanged: (v) => _update(() => _answer(item.id).number = num.tryParse(v.replaceAll(',', '.'))),
              ),
            ),
            const SizedBox(width: 12),
            if (range != null)
              Expanded(child: Text(range, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ]),
        ];
      case AnswerType.text:
        return [
          TextField(
            controller: _textControllers[item.id],
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(hintText: l10n.writeANote),
            onChanged: (v) => _update(() => _answer(item.id).text = v),
          ),
        ];
      case AnswerType.photo:
        return const [];
    }
  }

  Widget _photos(ChecklistItem item, Answer? a) {
    final l10n = context.l10n;
    final photos = a?.photoPaths ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in photos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LocalPhoto(p, onRemove: () => _update(() => _answer(item.id).photoPaths.remove(p))),
          ),
        _TakePhotoButton(
          compact: photos.isNotEmpty || !item.needsPhoto,
          label: photos.isEmpty ? l10n.takePhoto : l10n.addAnotherPhoto,
          onTap: () => _takePhoto(item),
        ),
      ],
    );
  }
}

class _TakePhotoButton extends StatelessWidget {
  const _TakePhotoButton({required this.onTap, required this.label, this.compact = false});
  final VoidCallback onTap;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSunken,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.dashed, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: compact ? 52 : 112,
          child: compact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(context.l10n.inAppCameraOnly,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
        ),
      ),
    );
  }
}
