import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/policy.dart';
import 'package:chants/app/spacing.dart';

/// The Community Rules, shared between the signed-out document and the
/// versioned acceptance gate.
class ContentPolicyBody extends StatelessWidget {
  final bool showHeader;

  const ContentPolicyBody({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text('COMMUNITY RULES', style: textTheme.headlineMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            'Effective $kPolicyEffectiveDate. Accepted contract version '
            '$kCurrentPolicyVersion.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Spacing.lg),
        ],
        Text(
          'Funny, brilliant, ridiculous, or a first attempt: football '
          'creativity belongs here. Swearing and ordinary rivalry are not '
          'automatically abuse. Context matters.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
        ),
        const SizedBox(height: Spacing.lg),
        const _Rule(
          title: 'BANTER IS WELCOME. HATE IS NOT.',
          body:
              'No racist, discriminatory, or dehumanizing abuse, protected-characteristic slurs, or targeted harassment.',
        ),
        const _Rule(
          title: 'NO THREATS OR TRAGEDY CHANTING.',
          body:
              'Do not encourage violence, celebrate real deaths or disasters, mock victims, or share private information to intimidate someone.',
        ),
        const _Rule(
          title: 'NO SEXUAL EXPLOITATION OR EXPLICIT SEXUAL CONTENT.',
          body:
              'No non-consensual intimate material, sexual harassment, grooming, sextortion, trafficking, or child sexual abuse material, including synthetic material.',
        ),
        const _Rule(
          title: 'RESPECT RIGHTS AND PRIVACY.',
          body:
              'Share only material you are entitled to use. Do not pass off another creator\'s work as your own or feature people in a way that invades their privacy.',
        ),
        const _Rule(
          title: 'KEEP THE COMPETITION HONEST.',
          body:
              'No scams, impersonation, spam, fake engagement, coordinated false reports, or attempts to evade account restrictions.',
        ),
        Text(
          'New videos are reviewed before publication. Text is not all '
          'reviewed in advance. Reports and automated checks can temporarily '
          'hide content, and operators can remove content or restrict '
          'accounts. Serious safety concerns are prioritized.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Use Report for abuse or safety, Suggest an edit for wrong or '
          'outdated chant information, and Block to filter a creator in '
          'supported signed-in views. If someone is in immediate danger, '
          'contact local emergency services. Chants is not an emergency '
          'service.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
        ),
        const SizedBox(height: Spacing.lg),
        const _Rule(
          title: 'URGENT CHILD SAFETY',
          body:
              'Email $kSupportEmail with the subject “Urgent child safety”. '
              'Do not download or forward abusive material. Send its Chants '
              'location or ID and a description. If someone is in immediate '
              'danger, contact local emergency services. Chants is not an '
              'emergency service.',
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final String title;
  final String body;

  const _Rule({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
          ),
        ],
      ),
    );
  }
}

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COMMUNITY RULES')),
      body: const SelectionArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.lg,
          ),
          child: ContentPolicyBody(),
        ),
      ),
    );
  }
}
