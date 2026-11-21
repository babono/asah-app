import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/widgets.dart';
import 'learning_repository.dart';
import 'models.dart';

/// Quiz: questions served without answers, graded on the server (T2).
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizSession? _session;
  String? _error;
  int _index = 0;
  final _answers = <String, String>{};
  bool _submitting = false;
  ({num score, bool passed})? _result;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _session = null;
      _result = null;
      _index = 0;
      _answers.clear();
    });
    try {
      final s = await ref.read(learningRepositoryProvider).startQuiz(widget.assignmentId);
      if (mounted) setState(() => _session = s);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final r = await ref.read(learningRepositoryProvider).submitQuiz(_session!.attemptId, _answers);
      ref.invalidate(moduleDetailProvider(widget.assignmentId));
      ref.invalidate(myAssignmentsProvider);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = ref.watch(moduleDetailProvider(widget.assignmentId)).value;
    final passMark = detail?.quiz?.passMarkPct;

    Widget body;
    Widget? footer;
    if (_error != null) {
      body = ErrorState(message: _error!, onRetry: _start);
    } else if (_session == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_result != null) {
      body = _ResultView(result: _result!, passMark: passMark);
      footer = BottomBar(
        child: FilledButton(onPressed: () => context.pop(), child: Text(l10n.backToModule)),
      );
    } else if (_session!.questions.isEmpty) {
      body = ErrorState(message: l10n.quizHasNoQuestions);
    } else {
      final qs = _session!.questions;
      final q = qs[_index];
      final picked = _answers[q.id];
      final last = _index == qs.length - 1;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(passMark == null ? l10n.quiz : l10n.quizPassMark(passMark),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    Text(l10n.questionOf(_index + 1, qs.length),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(q.prompt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: picked,
                  onChanged: (v) => setState(() => _answers[q.id] = v!),
                  child: Column(
                    children: [
                      for (final o in q.options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _OptionTile(
                            label: o.label,
                            value: o.id,
                            selected: picked == o.id,
                            onTap: () => setState(() => _answers[q.id] = o.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      footer = BottomBar(
        child: Row(
          children: [
            if (_index > 0) ...[
              Expanded(
                child: OutlinedButton(onPressed: () => setState(() => _index--), child: Text(l10n.previous)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: picked == null || _submitting
                    ? null
                    : last
                        ? _submit
                        : () => setState(() => _index++),
                child: Text(last ? l10n.submitAnswers : l10n.nextQuestion),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: TwoLineTitle(detail?.assignment.title ?? l10n.quiz, l10n.quiz)),
      body: body,
      bottomNavigationBar: footer,
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.inputBorder, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Radio<String>(value: value),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primary : AppColors.text)),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, this.passMark});
  final ({num score, bool passed}) result;
  final int? passMark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(result.passed ? Icons.emoji_events_outlined : Icons.replay_rounded,
                size: 56, color: result.passed ? AppColors.primary : AppColors.danger),
            const SizedBox(height: 16),
            Text('${result.score.round()}%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              result.passed ? l10n.quizPassedMessage : l10n.quizFailedMessage(passMark ?? 0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textStrong),
            ),
          ],
        ),
      ),
    );
  }
}
