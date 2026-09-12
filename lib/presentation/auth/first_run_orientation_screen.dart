import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

class FirstRunOrientationScreen extends StatefulWidget {
  final Future<void> Function() onSkip;
  final Future<void> Function() onContinue;
  final Future<void> Function() onCreateAccount;

  const FirstRunOrientationScreen({
    super.key,
    required this.onSkip,
    required this.onContinue,
    required this.onCreateAccount,
  });

  @override
  State<FirstRunOrientationScreen> createState() =>
      _FirstRunOrientationScreenState();
}

class _FirstRunOrientationScreenState extends State<FirstRunOrientationScreen> {
  static const _steps = <_OrientationStep>[
    _OrientationStep(
      label: 'SONGBOOK',
      headline: 'KNOW EVERY WORD',
      body:
          'Find chants by club or player. Save the ones you need for matchday.',
      badge: 'LEARN AND SAVE',
      icon: Icons.menu_book_outlined,
    ),
    _OrientationStep(
      label: 'CHANT LAB',
      headline: 'BACK WHAT COMES NEXT',
      body:
          'Back new ideas with your vote. Evidence they have been sung at matches earns Terrace Proven.',
      badge: 'IDEAS ARE NOT PROOF',
      icon: Icons.lightbulb_outline,
    ),
    _OrientationStep(
      label: 'STAGE',
      headline: 'ADD YOUR VOICE',
      body: 'Write a chant or perform one. Videos stay private until reviewed.',
      badge: 'CREATE WITH CONFIDENCE',
      icon: Icons.mic_none_outlined,
    ),
  ];

  late final PageController _pageController;
  int _stepIndex = 0;
  String? _leavingLabel;

  bool get _isLastStep => _stepIndex == _steps.length - 1;
  bool get _isLeaving => _leavingLabel != null;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLeaving || _isLastStep) return;
    final nextStep = _stepIndex + 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(nextStep);
      return;
    }
    _pageController.animateToPage(
      nextStep,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _leave(String label, Future<void> Function() action) async {
    if (_isLeaving) return;
    setState(() => _leavingLabel = label);
    await action();
    if (mounted) setState(() => _leavingLabel = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            Spacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrientationHeader(
                enabled: !_isLeaving,
                onSkip: () => _leave('CONTINUING TO SIGN IN', widget.onSkip),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'HOW CHANTS WORKS  ${_stepIndex + 1} / ${_steps.length}',
                key: const Key('first-run-step-label'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Expanded(
                child: PageView.builder(
                  key: const Key('first-run-pages'),
                  controller: _pageController,
                  physics: _isLeaving
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  allowImplicitScrolling: true,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    if (_isLeaving || index == _stepIndex) return;
                    setState(() => _stepIndex = index);
                  },
                  itemBuilder: (context, index) => SingleChildScrollView(
                    key: Key('first-run-page-scroll-${index + 1}'),
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _OrientationContent(
                      step: _steps[index],
                      number: index + 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              _StepDots(currentIndex: _stepIndex, count: _steps.length),
              const SizedBox(height: Spacing.lg),
              if (_isLeaving) ...[
                Semantics(
                  liveRegion: true,
                  label: _leavingLabel,
                  child: Column(
                    children: [
                      const LinearProgressIndicator(
                        color: AppColors.gold,
                        backgroundColor: AppColors.surfaceRaised,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        _leavingLabel!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                FilledButton(
                  key: const Key('first-run-primary-action'),
                  onPressed: _isLastStep
                      ? () => _leave('CONTINUING TO SIGN IN', widget.onContinue)
                      : _next,
                  child: Text(_isLastStep ? 'CONTINUE TO SIGN IN' : 'NEXT'),
                ),
                const SizedBox(height: Spacing.xs),
                TextButton.icon(
                  key: const Key('first-run-create-account'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: AppColors.gold,
                  ),
                  onPressed: () => _leave(
                    'OPENING ACCOUNT CREATION',
                    widget.onCreateAccount,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('CREATE ACCOUNT'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrientationHeader extends StatelessWidget {
  final bool enabled;
  final VoidCallback onSkip;

  const _OrientationHeader({required this.enabled, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Image.asset(
            'assets/icon/splash.png',
            key: const Key('first-run-brand-mark'),
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: Spacing.md),
        const Expanded(
          child: Text(
            'CHANTS',
            style: TextStyle(
              color: AppColors.textHeadline,
              fontFamily: 'Anton',
              fontSize: 24,
              letterSpacing: 1.4,
            ),
          ),
        ),
        TextButton(
          key: const Key('first-run-skip'),
          onPressed: enabled ? onSkip : null,
          child: const Text('SKIP'),
        ),
      ],
    );
  }
}

class _OrientationContent extends StatelessWidget {
  final _OrientationStep step;
  final int number;

  const _OrientationContent({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: Key('first-run-visual-$number'),
          clipBehavior: Clip.antiAlias,
          height: 148,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.outline),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: Key('first-run-dot-field-$number'),
                  painter: const _OrientationDotFieldPainter(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: AppColors.gold, size: 31),
                        const Spacer(),
                        Text(
                          'STEP ${number.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppColors.textFaint,
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                    Text(
                      step.badge,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          step.label,
          style: const TextStyle(
            color: AppColors.gold,
            fontFamily: 'SpaceMono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Semantics(
          header: true,
          child: Text(
            step.headline,
            key: const Key('first-run-headline'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.textHeadline,
              fontSize: 29,
              height: 1.06,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          step.body,
          key: const Key('first-run-body'),
          style: const TextStyle(
            color: AppColors.textBody,
            fontFamily: 'Nunito',
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _OrientationDotFieldPainter extends CustomPainter {
  const _OrientationDotFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint();
    const horizontalGap = 17.0;
    const verticalGap = 15.0;
    var row = 0;
    for (var y = 0.0; y < size.height + verticalGap; y += verticalGap) {
      final progress = (y / size.height).clamp(0.0, 1.0);
      final alpha = 0.012 + (0.043 * progress);
      dot.color = AppColors.textHeadline.withValues(alpha: alpha);
      final inset = row.isOdd ? horizontalGap / 2 : 0.0;
      for (
        var x = -horizontalGap + inset;
        x < size.width + horizontalGap;
        x += horizontalGap
      ) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
      row += 1;
    }
  }

  @override
  bool shouldRepaint(covariant _OrientationDotFieldPainter oldDelegate) {
    return false;
  }
}

class _StepDots extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _StepDots({required this.currentIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentIndex + 1} of $count',
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++) ...[
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              width: index == currentIndex ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == currentIndex
                    ? AppColors.gold
                    : AppColors.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (index != count - 1) const SizedBox(width: Spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _OrientationStep {
  final String label;
  final String headline;
  final String body;
  final String badge;
  final IconData icon;

  const _OrientationStep({
    required this.label,
    required this.headline,
    required this.body,
    required this.badge,
    required this.icon,
  });
}
