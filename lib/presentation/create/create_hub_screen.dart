import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';

class CreateHubScreen extends StatelessWidget {
  final VoidCallback onChooseClub;

  const CreateHubScreen({super.key, required this.onChooseClub});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CREATE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xxxl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              'GIVE THE NEXT CHANT A FIRST VOICE.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Write the idea, or find an existing chant and give it a voice in '
            'a 30-second performance.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: Spacing.xl),
          const SectionEyebrow(text: 'Perform a chant', gold: true),
          const SizedBox(height: Spacing.sm),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: const BorderSide(color: AppColors.gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    color: AppColors.gold,
                    size: 36,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'GIVE IT A VOICE',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'Browse a club, open a chant, then record a take or choose '
                    'an edited video from your library.',
                    style: TextStyle(color: AppColors.textBody),
                  ),
                  const SizedBox(height: Spacing.lg),
                  FilledButton(
                    onPressed: onChooseClub,
                    child: const Text('FIND A CHANT'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          const SectionEyebrow(text: 'Write a chant'),
          const SizedBox(height: Spacing.sm),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(
                color: AppColors.chantLab.withValues(alpha: 0.72),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note_outlined,
                    color: AppColors.chantLab,
                    size: 36,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'START IN CHANT LAB',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: Spacing.sm),
                  const Text(
                    'Pick the club, add the words and tune, and tell everyone '
                    'whether it is already sung or your original idea.',
                    style: TextStyle(color: AppColors.textBody),
                  ),
                  const SizedBox(height: Spacing.lg),
                  FilledButton(
                    onPressed: onChooseClub,
                    child: const Text('CHOOSE A CLUB'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
