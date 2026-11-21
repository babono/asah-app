import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../utils/errors.dart';
import '../utils/format.dart';
import 'media_repository.dart';
import 'offline_videos.dart';

/// Image stored in Supabase Storage, shown through a signed URL.
class MediaImage extends ConsumerWidget {
  const MediaImage(this.mediaId, {super.key, this.height = 168, this.caption});
  final String mediaId;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(signedUrlProvider(mediaId));
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppColors.photoPlaceholder,
        child: Stack(
          fit: StackFit.expand,
          children: [
            url.when(
              data: (u) => Image.network(u, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.textSecondary),
            ),
            if (caption != null) Positioned(left: 10, bottom: 10, child: _Caption(caption!)),
          ],
        ),
      ),
    );
  }
}

/// A local file photo (taken but not yet uploaded).
class LocalPhoto extends StatelessWidget {
  const LocalPhoto(this.path, {super.key, this.height = 112, this.onRemove});
  final String path;
  final double height;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),
            if (onRemove != null)
              Positioned(
                right: 6,
                top: 6,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  tooltip: context.l10n.removePhoto,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

/// Plays a Cloudflare Stream video, or its downloaded copy when available.
class StreamVideo extends ConsumerStatefulWidget {
  const StreamVideo({super.key, required this.mediaId, this.caption, this.onFinished, this.height = 200});
  final String mediaId;
  final String? caption;
  final VoidCallback? onFinished;
  final double height;

  @override
  ConsumerState<StreamVideo> createState() => _StreamVideoState();
}

class _StreamVideoState extends ConsumerState<StreamVideo> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = false;
  bool _finishedReported = false;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final local = ref.read(offlineVideosProvider).localFile(widget.mediaId);
      final VideoPlayerController c;
      if (local != null) {
        c = VideoPlayerController.file(local);
      } else {
        final playback = await ref.read(mediaRepositoryProvider).playback(widget.mediaId);
        if (playback.status != null && playback.status != 'ready') {
          throw Exception(mounted ? context.l10n.videoProcessing : 'Processing');
        }
        c = VideoPlayerController.networkUrl(Uri.parse(playback.hlsUrl));
      }
      await c.initialize();
      c.addListener(_onTick);
      await c.play();
      if (!mounted) return c.dispose();
      setState(() => _controller = c);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || _finishedReported) return;
    final v = c.value;
    if (v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 800)) {
      _finishedReported = true;
      widget.onFinished?.call();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        color: AppColors.videoBackground,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (c != null && c.value.isInitialized)
              Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
            if (c == null)
              _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _PlayButton(onTap: _start, label: context.l10n.playVideo),
            if (c != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                  child: AnimatedOpacity(
                    opacity: c.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Center(child: _PlayButton(onTap: c.play, label: context.l10n.playVideo)),
                  ),
                ),
              ),
            if (_error != null)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            if (widget.caption != null || c != null)
              Positioned(
                left: 12,
                bottom: 12,
                child: _Caption(c != null
                    ? '${Fmt.duration(c.value.position.inSeconds)} / ${Fmt.duration(c.value.duration.inSeconds)}'
                    : widget.caption!),
              ),
            if (c != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  c,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(playedColor: AppColors.accent, bufferedColor: Colors.white30),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.play_arrow_rounded, size: 34, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
