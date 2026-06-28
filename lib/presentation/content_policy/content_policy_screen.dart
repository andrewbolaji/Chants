import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('CONTENT POLICY')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.lg,
        ),
        child: Column(
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
        ),
      ),
    );
  }
}
