import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';

/// The first Flutter-owned launch frame.
///
/// The native splash stays static and instant. This surface continues the
/// same black-and-gold scene, then reveals the wordmark once while Firebase
/// and the account gates finish resolving behind it.
class LaunchRevealScreen extends StatefulWidget {
  final Duration animationDuration;
  final bool showProgress;

  const LaunchRevealScreen({
    super.key,
    this.animationDuration = const Duration(milliseconds: 1100),
    this.showProgress = false,
  });

  @override
  State<LaunchRevealScreen> createState() => _LaunchRevealScreenState();
}

class _LaunchRevealScreenState extends State<LaunchRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.animationDuration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        label: widget.showProgress
            ? 'Chants. Getting things ready.'
            : 'Chants. Find your voice in the crowd.',
        container: true,
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _LaunchAtmospherePainter(progress)),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxHeight < 460 ||
                          constraints.maxWidth > constraints.maxHeight;
                      final mark = _LaunchMark(
                        progress: progress,
                        size: compact ? 124 : 172,
                      );
                      final details = _LaunchDetails(
                        progress: progress,
                        showProgress: widget.showProgress,
                      );
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 24 : 28,
                          vertical: compact ? 20 : 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: compact
                                ? Row(
                                    children: [
                                      Expanded(flex: 2, child: mark),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 3, child: details),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      mark,
                                      const SizedBox(height: 18),
                                      details,
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LaunchMark extends StatelessWidget {
  final double progress;
  final double size;

  const _LaunchMark({required this.progress, required this.size});

  @override
  Widget build(BuildContext context) {
    final reveal = _interval(progress, 0, 0.36);
    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset(0, 24 * (1 - reveal)),
        child: Image.asset(
          'assets/icon/splash.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _LaunchDetails extends StatelessWidget {
  final double progress;
  final bool showProgress;

  const _LaunchDetails({required this.progress, required this.showProgress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WordReveal(progress: progress),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _interval(progress, 0.44, 0.86),
            child: const Divider(
              color: AppColors.gold,
              thickness: 4,
              height: 4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Opacity(
          opacity: _interval(progress, 0.72, 1),
          child: const Text(
            'FIND YOUR VOICE IN THE CROWD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'SpaceMono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SoundBars(progress: progress),
        if (showProgress) ...[
          const SizedBox(height: 16),
          const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              ),
              Text(
                'GETTING THINGS READY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WordReveal extends StatelessWidget {
  final double progress;

  const _WordReveal({required this.progress});

  @override
  Widget build(BuildContext context) {
    const word = 'CHANTS';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        key: const ValueKey('launch-reveal-word'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < word.length; index++)
            Builder(
              builder: (context) {
                final start = 0.2 + (index * 0.055);
                final letterProgress = _interval(progress, start, start + 0.3);
                return Opacity(
                  key: ValueKey('launch-letter-$index'),
                  opacity: letterProgress,
                  child: Transform.translate(
                    offset: Offset(0, 34 * (1 - letterProgress)),
                    child: Text(
                      word[index],
                      style: const TextStyle(
                        color: AppColors.textHeadline,
                        fontFamily: 'Anton',
                        fontSize: 74,
                        height: 0.9,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: AppColors.gold,
                            offset: Offset(1.5, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SoundBars extends StatelessWidget {
  final double progress;

  const _SoundBars({required this.progress});

  @override
  Widget build(BuildContext context) {
    const heights = [8.0, 16.0, 28.0, 42.0, 28.0, 16.0, 8.0];
    return Opacity(
      opacity: _interval(progress, 0.52, 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < heights.length; index++)
            Container(
              width: 4,
              height:
                  4 +
                  ((heights[index] - 4) *
                      _interval(progress, 0.48 + index * 0.035, 0.82)),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              color: index == 3 ? AppColors.chantLab : AppColors.gold,
            ),
        ],
      ),
    );
  }
}

class _LaunchAtmospherePainter extends CustomPainter {
  final double progress;

  const _LaunchAtmospherePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = AppColors.gold.withValues(alpha: 0.07);
    final faint = Paint()
      ..color = AppColors.textHeadline.withValues(alpha: 0.035);

    final leftFloodlight = Path()
      ..moveTo(size.width * 0.06, 0)
      ..lineTo(size.width * 0.47, size.height * 0.74)
      ..lineTo(size.width * 0.21, size.height * 0.74)
      ..close();
    final rightFloodlight = Path()
      ..moveTo(size.width * 0.94, 0)
      ..lineTo(size.width * 0.79, size.height * 0.74)
      ..lineTo(size.width * 0.53, size.height * 0.74)
      ..close();
    canvas.drawPath(leftFloodlight, gold);
    canvas.drawPath(rightFloodlight, gold);

    final dotProgress = Curves.easeOut.transform(
      _interval(progress, 0.08, 0.72),
    );
    for (var row = 0; row < 8; row++) {
      final y = size.height * 0.67 + row * 22;
      final inset = (row % 2) * 8.0;
      for (var x = -8.0 + inset; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.4 * dotProgress, faint);
      }
    }

    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.26 * progress)
      ..strokeWidth = 1;
    final horizon = size.height * 0.665;
    canvas.drawLine(Offset(0, horizon), Offset(size.width, horizon), line);

    final echo = Paint()
      ..color = AppColors.chantLab.withValues(alpha: 0.11 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.4),
        width: math.min(size.width * 1.4, 520),
        height: math.min(size.width * 0.62, 250),
      ),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      echo,
    );
  }

  @override
  bool shouldRepaint(covariant _LaunchAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

double _interval(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return Curves.easeOutCubic.transform((value - start) / (end - start));
}
