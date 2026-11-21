import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/media_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../learning/models.dart';
import '../session/people.dart';
import 'mentor_screen.dart';
import 'mentorship_repository.dart';

final _submissionProvider = FutureProvider.family<(PracticalSubmission, List<RubricCriterion>), String>((ref, id) async {
  final repo = ref.watch(mentorshipRepositoryProvider);
  final s = await repo.submission(id);
  final rubric = s.moduleVersionId == null ? <RubricCriterion>[] : await repo.rubric(s.moduleVersionId!);
  return (s, rubric);
});

/// Mentor watches the recording and scores every rubric line (T3; design screen 5).
class PracticalScoreScreen extends ConsumerStatefulWidget {
  const PracticalScoreScreen({super.key, required this.submissionId});
  final String submissionId;

  @override
  ConsumerState<PracticalScoreScreen> createState() => _PracticalScoreScreenState();
}

class _PracticalScoreScreenState extends ConsumerState<PracticalScoreScreen> {
  final _results = <String, String>{};
  final _feedback = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _save(List<RubricCriterion> rubric) async {
    final l10n = context.l10n;
    if (_results.length < rubric.length) {
      showSnack(context, l10n.scoreEveryLine, error: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await runAction(context, () async {
      final outcome = await ref.read(mentorshipRepositoryProvider).scorePractical(
            widget.submissionId,
            _results,
            feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
          );
      ref.invalidate(mentorDashboardProvider);
      if (mounted) showSnack(context, outcome == 'passed' ? l10n.practicalMarkedPassed : l10n.practicalAskedRedo);
    });
    if (mounted) setState(() => _saving = false);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(_submissionProvider(widget.submissionId));
    final trainee = data.value == null ? null : ref.watch(peopleProvider(data.value!.$1.userId)).value?[data.value!.$1.userId];

    return Scaffold(
      appBar: AppBar(title: TwoLineTitle(l10n.practicalTest, [trainee?.name, data.value?.$1.moduleTitle].whereType<String>().join(' · '))),
      body: AsyncBody(
        value: data,
        onRetry: () => ref.invalidate(_submissionProvider(widget.submissionId)),
        builder: (d) {
          final (sub, rubric) = d;
          final scored = sub.status != 'pending';
          final passCount = _results.values.where((v) => v == 'pass').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamVideo(mediaId: sub.mediaFileId, caption: l10n.recordedInApp(Fmt.dayTime(sub.submittedAt)), height: 200),
              const SizedBox(height: 16),
              if (scored)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoBanner(icon: Icons.info_outline, text: l10n.alreadyScored),
                ),
              AppCard(
                radius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.rubric, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                        Text(l10n.passedOf(passCount, rubric.length),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final c in rubric) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  if (c.description != null)
                                    Text(c.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            ChoiceButton(
                              label: l10n.pass,
                              compact: true,
                              selected: _results[c.id] == 'pass',
                              onTap: scored ? null : () => setState(() => _results[c.id] = 'pass'),
                            ),
                            const SizedBox(width: 6),
                            ChoiceButton(
                              label: l10n.redo,
                              compact: true,
                              negative: true,
                              selected: _results[c.id] == 'redo',
                              onTap: scored ? null : () => setState(() => _results[c.id] = 'redo'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedback,
                enabled: !scored,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.feedbackFor(trainee?.name ?? ''),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: data.maybeWhen(
        data: (d) {
          if (d.$1.status != 'pending') return null;
          final allPass = _results.length == d.$2.length && _results.values.every((v) => v == 'pass');
          return BottomBar(
            child: FilledButton(
              onPressed: _saving ? null : () => _save(d.$2),
              child: Text(allPass ? l10n.pass : l10n.askToRedo),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
