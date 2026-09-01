import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/settings/account_deletion_action.dart';
import 'package:chants/presentation/shared/halftone_painter.dart';

/// One-time gate shown before the app is usable, for any signed-in user
/// whose profile does not show acceptance of the current Terms and Rules
/// version. Fires for existing accounts on the first open after this
/// feature ships, and for the brief window during a fresh sign-up before
/// acceptPolicy has finished (see ChantApp).
class PolicyAcceptanceGateScreen extends ConsumerStatefulWidget {
  const PolicyAcceptanceGateScreen({super.key});

  @override
  ConsumerState<PolicyAcceptanceGateScreen> createState() =>
      _PolicyAcceptanceGateScreenState();
}

class _PolicyAcceptanceGateScreenState
    extends ConsumerState<PolicyAcceptanceGateScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(moderationRepositoryProvider).acceptPolicy();
      // No manual navigation: the app watches the profile stream and
      // moves on once it sees the acceptance.
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your acceptance. Check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              key: const ValueKey('policy-gate-scroll'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.lg,
                  Spacing.xl,
                  Spacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PolicyGateHero(),
                    const SizedBox(height: Spacing.xxl),
                    Text(
                      'YOU ARE AGREEING TO TWO DOCUMENTS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _PolicyRouteRow(
                      number: '01',
                      title: 'TERMS OF USE',
                      description: 'The legal agreement for using Chants.',
                      actionLabel: 'READ TERMS',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.terms),
                    ),
                    _PolicyRouteRow(
                      number: '02',
                      title: 'COMMUNITY RULES',
                      description:
                          'What supporters can post and how moderation works.',
                      actionLabel: 'READ RULES',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.community),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Container(
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          left: BorderSide(color: AppColors.chantLab, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIVACY STAYS SEPARATE',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'The Privacy Notice explains how information is '
                            'handled. It is not part of this agreement.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textBody),
                          ),
                          const SizedBox(height: Spacing.sm),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRouter.privacy),
                            child: const Text('PRIVACY NOTICE'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _SupportActions(accepting: _accepting),
                    const SizedBox(height: Spacing.xxxl),
                    const _SectionRule(
                      kicker: 'THE RULES, PLAINLY',
                      title: 'FUNNY BELONGS HERE. HATE DOES NOT.',
                    ),
                    const SizedBox(height: Spacing.lg),
                    const SelectionArea(
                      child: ContentPolicyBody(showHeader: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.md,
              Spacing.xl,
              Spacing.lg,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 632),
                child: FilledButton(
                  key: const ValueKey('policy-accept-button'),
                  onPressed: _accepting ? null : _accept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                  ),
                  child: _accepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'AGREE AND CONTINUE',
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyGateHero extends StatelessWidget {
  const _PolicyGateHero();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const HalftonePainter(
        dotRadius: 1.25,
        spacing: 10,
        opacity: 0.065,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.lg,
          Spacing.xl,
          Spacing.xxl,
        ),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gold, width: 5),
            bottom: BorderSide(color: AppColors.outline),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.lg,
              runSpacing: Spacing.sm,
              children: [
                Text(
                  'ONE QUICK THING',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'POLICY $kCurrentPolicyVersion',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: Spacing.xxl),
            Semantics(
              header: true,
              child: Text(
                'KEEP THE TERRACE LOUD.\nKEEP IT SAFE.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 46,
                  height: 0.94,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(color: AppColors.gold, offset: Offset(1.5, 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'We updated our Terms and Community Rules. Read them, then '
              'agree to keep using Chants.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textBody,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Effective $kPolicyEffectiveDate. Accepted contract version '
              '$kCurrentPolicyVersion.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacing.xl),
            const _TerraceSignal(),
          ],
        ),
      ),
    );
  }
}

class _TerraceSignal extends StatelessWidget {
  const _TerraceSignal();

  @override
  Widget build(BuildContext context) {
    const heights = [8.0, 15.0, 25.0, 36.0, 25.0, 15.0, 8.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < heights.length; index++)
          Container(
            width: 5,
            height: heights[index],
            margin: const EdgeInsets.only(right: Spacing.xs),
            color: index == 3 ? AppColors.chantLab : AppColors.gold,
          ),
        const SizedBox(width: Spacing.md),
        Expanded(child: Container(height: 1, color: AppColors.outline)),
      ],
    );
  }
}

class _PolicyRouteRow extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _PolicyRouteRow({
    required this.number,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description $actionLabel',
      onTap: onTap,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final document = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Spacing.xs),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
          final action = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHeadline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              const Icon(Icons.arrow_outward, size: 18, color: AppColors.gold),
            ],
          );
          return InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PolicyNumber(number: number),
                            Expanded(child: document),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: action,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PolicyNumber(number: number),
                        Expanded(child: document),
                        const SizedBox(width: Spacing.sm),
                        action,
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PolicyNumber extends StatelessWidget {
  final String number;

  const _PolicyNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        number,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupportActions extends ConsumerWidget {
  final bool accepting;

  const _SupportActions({required this.accepting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.policyHub),
              child: const Text('HELP & POLICIES'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.support),
              child: const Text('SUPPORT'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            TextButton(
              onPressed: accepting
                  ? null
                  : () => showDeleteAccountDialog(context, ref),
              child: const Text(
                'DELETE ACCOUNT',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: accepting
                  ? null
                  : () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('SIGN OUT'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionRule extends StatelessWidget {
  final String kicker;
  final String title;

  const _SectionRule({required this.kicker, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: Spacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}
