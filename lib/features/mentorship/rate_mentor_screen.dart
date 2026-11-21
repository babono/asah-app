import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/offline/local_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import 'mentorship_repository.dart';

/// Ratings cannot be read back (they are anonymous), so the phone remembers
/// which mentorships this person already rated.
bool hasRated(LocalStore store, String mentorshipId) => store.getString('rated:$mentorshipId') != null;

/// Anonymous mentor rating at the end of the mentorship (M7).
class RateMentorScreen extends ConsumerStatefulWidget {
  const RateMentorScreen({super.key, required this.mentorshipId});
  final String mentorshipId;

  @override
  ConsumerState<RateMentorScreen> createState() => _RateMentorScreenState();
}

class _RateMentorScreenState extends ConsumerState<RateMentorScreen> {
  int _score = 0;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final l10n = context.l10n;
    final ok = await runAction(context, () async {
      await ref.read(mentorshipRepositoryProvider).rateMentor(widget.mentorshipId, _score, _comment.text);
    }, success: l10n.thanksForRating);
    if (ok) {
      await ref.read(localStoreProvider).setString('rated:${widget.mentorshipId}', DateTime.now().toIso8601String());
      ref.invalidate(myMentorshipsProvider);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ms = ref.watch(mentorshipProvider(widget.mentorshipId)).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rateYourMentor)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.howWasMentor(ms?.mentorName ?? ''), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 40,
                  tooltip: '$i',
                  onPressed: () => setState(() => _score = i),
                  icon: Icon(i <= _score ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i <= _score ? AppColors.accent : AppColors.dashed),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(labelText: l10n.commentOptional, alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          InfoBanner(icon: Icons.lock_outline, text: l10n.ratingAnonymousNote),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton(onPressed: _score == 0 || _saving ? null : _submit, child: Text(l10n.sendRating)),
      ),
    );
  }
}
