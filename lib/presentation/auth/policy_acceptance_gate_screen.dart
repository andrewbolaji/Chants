import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/content_policy/content_policy_screen.dart';

/// One-time gate shown before the app is usable, for any signed-in user
/// whose profile does not show acceptance of the current content policy
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
          content:
              Text('Could not save your acceptance. Check your connection and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BEFORE YOU CONTINUE')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'We updated our content policy. Read it, then tap agree to keep using Chants.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textBody,
                    ),
              ),
              const SizedBox(height: Spacing.lg),
              const Expanded(
                child: SingleChildScrollView(child: ContentPolicyBody()),
              ),
              const SizedBox(height: Spacing.lg),
              FilledButton(
                onPressed: _accepting ? null : _accept,
                child: _accepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I AGREE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
