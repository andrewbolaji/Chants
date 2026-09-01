import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';
import 'package:chants/presentation/settings/account_deletion_action.dart';

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
      appBar: AppBar(title: const Text('BEFORE YOU CONTINUE')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            Spacing.xxxl,
          ),
          children: [
            Text(
              'We updated our Terms and Community Rules. Read them, then '
              'agree to keep using Chants. The Privacy Notice explains how '
              'information is handled; it is not part of this agreement.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.terms),
                  child: const Text('READ TERMS'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.privacy),
                  child: const Text('PRIVACY NOTICE'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.policyHub),
                  child: const Text('HELP & POLICIES'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.support),
                  child: const Text('SUPPORT'),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: _accepting
                      ? null
                      : () => showDeleteAccountDialog(context, ref),
                  child: const Text(
                    'DELETE ACCOUNT',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _accepting
                      ? null
                      : () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('SIGN OUT'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            const Divider(),
            const SizedBox(height: Spacing.lg),
            const ContentPolicyBody(),
            const SizedBox(height: Spacing.lg),
            FilledButton(
              onPressed: _accepting ? null : _accept,
              child: _accepting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('AGREE AND CONTINUE'),
            ),
          ],
        ),
      ),
    );
  }
}
