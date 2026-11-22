import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              data: (u) => Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
              ),
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
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
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
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_reportFinished);
      setState(() => _controller = c);
      await c.play();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Reports once that the video was watched to the end. The controls redraw
  /// themselves from the controller, so this listener does not rebuild.
  void _reportFinished() {
    final v = _controller?.value;
    if (v == null || _finishedReported) return;
    if (v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 800)) {
      _finishedReported = true;
      widget.onFinished?.call();
    }
  }

  Future<void> _openFullScreen() async {
    final c = _controller;
    if (c == null) return;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, _, _) => _FullScreenVideo(controller: c),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_reportFinished);
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
        child: c != null
            ? _VideoView(controller: c, onToggleFullScreen: _openFullScreen)
            : Stack(
                alignment: Alignment.center,
                children: [
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _PlayButton(onTap: _start, label: context.l10n.playVideo),
                  if (_error != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (widget.caption != null) Positioned(left: 12, bottom: 12, child: _Caption(widget.caption!)),
                ],
              ),
      ),
    );
  }
}

/// The video with its controls, used inline and in full screen. It listens to
/// the controller itself, so play/pause and the time are always current.
class _VideoView extends StatelessWidget {
  const _VideoView({required this.controller, required this.onToggleFullScreen, this.fullScreen = false});
  final VideoPlayerController controller;
  final VoidCallback onToggleFullScreen;
  final bool fullScreen;

  bool _atEnd(VideoPlayerValue v) => v.duration > Duration.zero && v.position >= v.duration;

  Future<void> _togglePlay() async {
    final v = controller.value;
    if (v.isPlaying) return controller.pause();
    // Finished: start again from the beginning.
    if (_atEnd(v)) await controller.seekTo(Duration.zero);
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, v, _) {
        final playing = v.isPlaying && !_atEnd(v);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (v.isInitialized)
              Center(
                child: AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(controller)),
              ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                child: IgnorePointer(
                  ignoring: playing,
                  child: AnimatedOpacity(
                    opacity: playing ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: v.isBuffering && v.isPlaying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : _PlayButton(onTap: _togglePlay, label: l10n.playVideo),
                    ),
                  ),
                ),
              ),
            ),
            if (playing)
              // Tapping a playing video pauses it; tell screen readers.
              Positioned.fill(
                child: Semantics(button: true, label: l10n.pauseVideo, onTap: _togglePlay),
              ),
            Positioned(
              left: 12,
              bottom: fullScreen ? 24 : 12,
              child: _Caption('${Fmt.duration(v.position.inSeconds)} / ${Fmt.duration(v.duration.inSeconds)}'),
            ),
            Positioned(
              right: 4,
              bottom: fullScreen ? 12 : 0,
              child: IconButton(
                onPressed: onToggleFullScreen,
                tooltip: fullScreen ? l10n.exitFullScreen : l10n.fullScreen,
                icon: Icon(fullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: fullScreen ? 8 : 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.only(top: fullScreen ? 12 : 4),
                colors: const VideoProgressColors(playedColor: AppColors.accent, bufferedColor: Colors.white30),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Full-screen player sharing the inline controller, so playback carries on
/// where it was. Landscape videos turn the screen sideways; the app goes back
/// to portrait on exit.
class _FullScreenVideo extends StatefulWidget {
  const _FullScreenVideo({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  @override
  void initState() {
    super.initState();
    final landscape = widget.controller.value.aspectRatio > 1;
    SystemChrome.setPreferredOrientations(
      landscape ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : [DeviceOrientation.portraitUp],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _VideoView(
          controller: widget.controller,
          fullScreen: true,
          onToggleFullScreen: () => Navigator.of(context).pop(),
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
