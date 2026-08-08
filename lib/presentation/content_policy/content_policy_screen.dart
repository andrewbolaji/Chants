import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// The policy text itself, shared between the always-accessible
/// [ContentPolicyScreen] and the one-time acceptance gate, so the copy
/// lives in exactly one place.
class ContentPolicyBody extends StatelessWidget {
  const ContentPolicyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTENT POLICY', style: textTheme.headlineMedium),
        const SizedBox(height: Spacing.lg),
        Text(
          'The full content policy will appear here before submissions '
          'go live. It covers what is and is not allowed on Chants.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textBody,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'In short: no hate speech, no threats, no tragedy chanting, '
          'nothing that targets people for who they are. '
          'The detailed rules are coming soon.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textBody,
          ),
        ),
      ],
    );
  }
}

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONTENT POLICY')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        child: ContentPolicyBody(),
      ),
    );
  }
}
