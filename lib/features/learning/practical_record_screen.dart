import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/l10n/l10n.dart';
import '../../core/media/camera.dart';
import '../../core/media/media_repository.dart';
import '../../core/offline/connectivity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/widgets.dart';
import 'learning_repository.dart';

/// Trainee records the practical test in the app; the mentor scores it (T3).
class PracticalRecordScreen extends ConsumerStatefulWidget {
  const PracticalRecordScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  ConsumerState<PracticalRecordScreen> createState() => _PracticalRecordScreenState();
}

class _PracticalRecordScreenState extends ConsumerState<PracticalRecordScreen> {
  XFile? _video;
  VideoPlayerController? _preview;
  bool _uploading = false;

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    final v = await recordVideo();
    if (v == null) return;
    await _preview?.dispose();
    final c = VideoPlayerController.file(File(v.path));
    await c.initialize();
    if (!mounted) return c.dispose();
    setState(() {
      _video = v;
      _preview = c;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _uploading = true);
    try {
      final mediaId = await ref.read(mediaRepositoryProvider).uploadVideo(_video!, kind: 'practical_video');
      await ref.read(learningRepositoryProvider).submitPractical(widget.assignmentId, mediaId);
      ref.invalidate(moduleDetailProvider(widget.assignmentId));
      if (!mounted) return;
      showSnack(context, l10n.practicalSent);
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = ref.watch(moduleDetailProvider(widget.assignmentId));
    final online = ref.watch(isOnlineProvider).value ?? true;
    final c = _preview;

    return Scaffold(
      appBar: AppBar(title: TwoLineTitle(l10n.practicalTest, detail.value?.assignment.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 220,
              color: AppColors.videoBackground,
              alignment: Alignment.center,
              child: c == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_outlined, size: 40, color: Colors.white70),
                        const SizedBox(height: 8),
                        Text(l10n.recordInApp, style: const TextStyle(color: Colors.white70)),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                      child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.whatMentorChecks, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final r in detail.value?.rubric ?? const [])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              if (r.description != null)
                                Text(r.description!,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!online) ...[
            const SizedBox(height: 12),
            InfoBanner(icon: Icons.wifi_off_rounded, text: l10n.needConnectionToSend),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _uploading ? null : _record,
                child: Text(_video == null ? l10n.record : l10n.recordAgain),
              ),
            ),
            if (_video != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _uploading || !online ? null : _submit,
                  child: _uploading
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(l10n.sendToMentor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
