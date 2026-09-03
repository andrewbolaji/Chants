import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/presentation/settings/account_deletion_action.dart';

const kPolicyAcceptanceRequestTimeout = Duration(seconds: 15);

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
  final ValueNotifier<bool> _acceptingForOtherActions = ValueNotifier(false);

  void _setAccepting(bool value) {
    _acceptingForOtherActions.value = value;
    setState(() => _accepting = value);
  }

  String _acceptanceError(Object error) {
    if (error is FirebaseFunctionsException) {
      final details = error.details;
      final reason = details is Map ? details['reason'] : null;
      if (reason == 'maintenance') {
        return 'Chants is temporarily paused. Try again later. Nothing was changed.';
      }
      if (error.code == 'unauthenticated') {
        return 'Sign in again, then accept the updated Terms and Community Rules.';
      }
      if (error.code == 'permission-denied') {
        return 'Verify an email address or phone number, then try again.';
      }
      if (error.code == 'failed-precondition') {
        return 'Your account needs attention before this can be accepted.';
      }
      if (error.code == 'not-found') {
        return 'Your Chants profile is not ready yet. Sign out and sign in again, or contact Support.';
      }
      if (error.code == 'internal') {
        return 'Chants could not save this right now. Try again, or contact Support if it continues.';
      }
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return 'Chants could not be reached. Check your connection and try again.';
      }
    }
    return 'Could not save your acceptance. Check your connection and try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _accept() async {
    if (_accepting) return;
    _setAccepting(true);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .acceptPolicy()
          .timeout(kPolicyAcceptanceRequestTimeout);
      // No manual navigation: the app watches the profile stream and
      // moves on once it sees the acceptance. Restore local controls as a
      // fallback if that stream is delayed or unavailable.
      if (!mounted) return;
      _setAccepting(false);
      _showMessage('Acceptance saved. Finishing setup...');
    } on TimeoutException {
      if (!mounted) return;
      _setAccepting(false);
      _showMessage(
        'Chants is taking longer than expected. Try again, or use Other options for help.',
      );
    } catch (e) {
      if (!mounted) return;
      _setAccepting(false);
      _showMessage(_acceptanceError(e));
    }
  }

  @override
  void dispose() {
    _acceptingForOtherActions.dispose();
    super.dispose();
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
                    _PrivacyRoute(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.privacy),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _OtherActions(accepting: _acceptingForOtherActions),
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
                      ? Semantics(
                          excludeSemantics: true,
                          liveRegion: true,
                          label: 'Saving policy acceptance',
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: Spacing.sm),
                              Text('SAVING...'),
                            ],
                          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gold, width: 2),
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
                'BEFORE YOU CONTINUE',
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
          const SizedBox(height: Spacing.xl),
          Semantics(
            header: true,
            child: Text(
              'A QUICK RULES CHECK.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                height: 1.05,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Review the updated Terms and Community Rules, then agree to '
            'continue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textBody,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Effective $kPolicyEffectiveDate.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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

class _PrivacyRoute extends StatelessWidget {
  final VoidCallback onTap;

  const _PrivacyRoute({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Privacy Notice. Explains how Chants handles information. It is not part of this agreement.',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('policy-privacy-route'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'PRIVACY NOTICE  ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textHeadline),
                      ),
                      TextSpan(
                        text:
                            'How Chants handles information. Not part of this agreement.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherActions extends ConsumerWidget {
  final ValueListenable<bool> accepting;

  const _OtherActions({required this.accepting});

  void _openSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ValueListenableBuilder<bool>(
        valueListenable: accepting,
        builder: (sheetBodyContext, isAccepting, child) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.xs,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OTHER OPTIONS',
                      style: Theme.of(sheetBodyContext).textTheme.titleMedium,
                    ),
                    if (isAccepting) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Help and Support remain available while acceptance is saving.',
                        style: Theme.of(sheetBodyContext).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: Spacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.policy_outlined),
                      title: const Text('Help & policies'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushNamed(context, AppRouter.policyHub);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('Support'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushNamed(context, AppRouter.support);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      title: const Text(
                        'Delete account',
                        style: TextStyle(color: AppColors.error),
                      ),
                      enabled: !isAccepting,
                      onTap: isAccepting
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              showDeleteAccountDialog(context, ref);
                            },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign out'),
                      enabled: !isAccepting,
                      onTap: isAccepting
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              ref.read(authRepositoryProvider).signOut();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      key: const ValueKey('policy-other-options'),
      onPressed: () => _openSheet(context, ref),
      icon: const Icon(Icons.more_horiz),
      label: const Text('OTHER OPTIONS'),
    );
  }
}
