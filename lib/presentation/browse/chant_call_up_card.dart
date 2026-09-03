import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

class ChantCallUpCard extends StatelessWidget {
  final String playerName;
  final String clubName;
  final bool isSignedIn;
  final VoidCallback onWrite;
  final VoidCallback? onNextPlayer;
  final bool signalAppearance;

  const ChantCallUpCard({
    super.key,
    required this.playerName,
    required this.clubName,
    required this.isSignedIn,
    required this.onWrite,
    this.onNextPlayer,
    this.signalAppearance = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final panelColor = signalAppearance
        ? AppColors.signalPaper
        : AppColors.surface;
    final borderColor = signalAppearance
        ? AppColors.signalRule
        : AppColors.chantLab;
    final headlineColor = signalAppearance
        ? AppColors.signalInk
        : AppColors.textHeadline;
    final bodyColor = signalAppearance
        ? AppColors.signalTextMuted
        : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(
            signalAppearance ? Radii.sm : Radii.lg,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined, color: AppColors.chantLab),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'CHANT CALL-UP',
                    style: text.labelMedium?.copyWith(
                      color: AppColors.chantLab,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Semantics(
              header: true,
              child: Text(
                playerName.toUpperCase(),
                style: text.headlineMedium?.copyWith(color: headlineColor),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              "Who's got a song for them?",
              style: text.titleMedium?.copyWith(color: headlineColor),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'No chant for them at $clubName in Chants yet. Funny or full of heart, '
              'start with the words.',
              style: text.bodyMedium?.copyWith(color: bodyColor),
            ),
            const SizedBox(height: Spacing.lg),
            FilledButton.icon(
              key: const Key('call-up-write'),
              style: FilledButton.styleFrom(
                backgroundColor: signalAppearance
                    ? AppColors.signalForest
                    : AppColors.chantLab,
                foregroundColor: signalAppearance
                    ? AppColors.signalPaper
                    : AppColors.goldOnDark,
              ),
              onPressed: onWrite,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: Text(isSignedIn ? 'WRITE THIS CHANT' : 'SIGN IN TO WRITE'),
            ),
            if (onNextPlayer != null)
              TextButton(
                key: const Key('call-up-next'),
                style: TextButton.styleFrom(
                  foregroundColor: signalAppearance
                      ? AppColors.signalForest
                      : AppColors.gold,
                ),
                onPressed: () {
                  onNextPlayer!();
                  // A shorter next name must not leave the new card above
                  // the viewport after the fan scrolled through a long one.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) Scrollable.ensureVisible(context);
                  });
                },
                child: const Text('Choose another player'),
              ),
          ],
        ),
      ),
    );
  }
}
