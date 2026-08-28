import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool isQualifiedPerformancePlayback({
  required Duration position,
  required bool completed,
}) {
  return completed || position >= const Duration(seconds: 3);
}

class PerformanceVideoPlayer extends StatefulWidget {
  final Future<Uri> Function() resolveMediaUri;
  final Future<void> Function()? onQualifiedView;
  final String semanticLabel;

  const PerformanceVideoPlayer({
    super.key,
    required this.resolveMediaUri,
    this.onQualifiedView,
    required this.semanticLabel,
  });

  @override
  State<PerformanceVideoPlayer> createState() => _PerformanceVideoPlayerState();
}

class _PerformanceVideoPlayerState extends State<PerformanceVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _qualifiedViewSent = false;
  Object? _error;

  void _handleControllerChange() {
    final controller = _controller;
    final callback = widget.onQualifiedView;
    if (!_qualifiedViewSent &&
        callback != null &&
        controller != null &&
        isQualifiedPerformancePlayback(
          position: controller.value.position,
          completed: controller.value.isCompleted,
        )) {
      _qualifiedViewSent = true;
      unawaited(callback().catchError((_) {}));
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    final existing = _controller;
    if (existing != null && existing.value.isInitialized) {
      if (existing.value.isPlaying) {
        await existing.pause();
      } else {
        if (existing.value.isCompleted) await existing.seekTo(Duration.zero);
        await existing.play();
      }
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    VideoPlayerController? controller;
    try {
      final mediaUri = await widget.resolveMediaUri();
      if (!mounted) return;
      controller = VideoPlayerController.networkUrl(mediaUri);
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_handleControllerChange);
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initializedController =
        controller != null && controller.value.isInitialized
        ? controller
        : null;
    final ready = initializedController != null;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      hint: ready && initializedController.value.isPlaying
          ? 'Pause performance'
          : _error == null
          ? 'Play performance'
          : 'Retry performance playback',
      child: InkWell(
        onTap: _loading ? null : _toggle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (initializedController != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: initializedController.value.size.width,
                  height: initializedController.value.size.height,
                  child: VideoPlayer(initializedController),
                ),
              )
            else
              const _Poster(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Icon(
                          _error != null
                              ? Icons.refresh
                              : ready && initializedController.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.gold,
                          size: 34,
                        ),
                      ),
                    ),
            ),
            if (_error != null)
              const Positioned(
                left: Spacing.md,
                right: Spacing.md,
                bottom: Spacing.md,
                child: Text(
                  'Playback failed. Tap to try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textHeadline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster();

  @override
  Widget build(BuildContext context) {
    return const _FallbackPoster();
  }
}

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.chantLab, AppColors.surfaceRaised],
        ),
      ),
      child: Center(
        child: Icon(Icons.graphic_eq, color: AppColors.textHeadline, size: 72),
      ),
    );
  }
}
