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
          'Find chants by club and player, then save the ones you need to your phone for matchday.',
      badge: 'LEARN AND SAVE',
      icon: Icons.menu_book_outlined,
      accent: AppColors.gold,
    ),
    _OrientationStep(
      label: 'CHANT LAB',
      headline: 'BACK WHAT COMES NEXT',
      body:
          'New ideas live in Chant Lab. Votes help them rise, but only real-world evidence makes a chant Terrace Proven.',
      badge: 'IDEAS ARE NOT PROOF',
      icon: Icons.lightbulb_outline,
      accent: AppColors.chantLab,
    ),
    _OrientationStep(
      label: 'STAGE',
      headline: 'ADD YOUR VOICE',
      body:
          'Write a chant or perform one. Performance videos stay private until a moderator reviews them.',
      badge: 'CREATE WITH CONFIDENCE',
      icon: Icons.mic_none_outlined,
      accent: AppColors.goldBright,
    ),
  ];

  int _stepIndex = 0;
  String? _leavingLabel;

  bool get _isLastStep => _stepIndex == _steps.length - 1;
  bool get _isLeaving => _leavingLabel != null;

  void _next() {
    if (_isLeaving || _isLastStep) return;
    setState(() => _stepIndex += 1);
  }

  Future<void> _leave(String label, Future<void> Function() action) async {
    if (_isLeaving) return;
    setState(() => _leavingLabel = label);
    await action();
    if (mounted) setState(() => _leavingLabel = null);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              key: const Key('first-run-orientation-scroll'),
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.lg,
                Spacing.xl,
                Spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - Spacing.lg - Spacing.xl,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OrientationHeader(
                        enabled: !_isLeaving,
                        onSkip: () =>
                            _leave('CONTINUING TO SIGN IN', widget.onSkip),
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
                      const SizedBox(height: Spacing.md),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.035, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: _OrientationContent(
                              key: ValueKey(_stepIndex),
                              step: step,
                              number: _stepIndex + 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
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
                              ? () => _leave(
                                  'CONTINUING TO SIGN IN',
                                  widget.onContinue,
                                )
                              : _next,
                          child: Text(
                            _isLastStep ? 'CONTINUE TO SIGN IN' : 'NEXT',
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        OutlinedButton.icon(
                          key: const Key('first-run-create-account'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.lg),
                            ),
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
          },
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
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: const Icon(
            Icons.graphic_eq,
            color: AppColors.goldOnDark,
            size: 24,
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

  const _OrientationContent({
    super.key,
    required this.step,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: Key('first-run-visual-$number'),
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 176),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: step.accent.withValues(alpha: 0.52)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                bottom: -24,
                child: ExcludeSemantics(
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: step.accent.withValues(alpha: 0.08),
                      fontFamily: 'Anton',
                      fontSize: 132,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: step.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: step.accent.withValues(alpha: 0.72),
                        ),
                      ),
                      child: Icon(step.icon, color: step.accent, size: 34),
                    ),
                    const SizedBox(height: Spacing.xl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: step.accent,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        child: Text(
                          step.badge,
                          style: const TextStyle(
                            color: AppColors.goldOnDark,
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          step.label,
          style: TextStyle(
            color: step.accent,
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
              fontSize: 32,
              height: 1.04,
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
  final Color accent;

  const _OrientationStep({
    required this.label,
    required this.headline,
    required this.body,
    required this.badge,
    required this.icon,
    required this.accent,
  });
}
