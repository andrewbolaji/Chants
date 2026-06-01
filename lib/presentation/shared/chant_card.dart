import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

class ChantCard extends StatelessWidget {
  final Chant chant;
  final String? teamName;
  final VoidCallback onTap;

  const ChantCard({
    super.key,
    required this.chant,
    this.teamName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: tune in small caps + verified foil badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chant.tuneName.toUpperCase(),
                      style: textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chant.status == 'canonical') const _GoldFoilBadge(),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Bold condensed title
              Text(
                chant.title.toUpperCase(),
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (teamName != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(teamName!, style: textTheme.bodySmall),
              ],
              const SizedBox(height: Spacing.sm),

              // One-line lyrics preview
              Text(
                chant.lyrics.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.md),

              // Quiet vote row with bold condensed score
              Row(
                children: [
                  if (chant.subjectTag != 'club') ...[
                    Text(chant.subjectTag, style: textTheme.labelSmall),
                    const SizedBox(width: Spacing.sm),
                  ],
                  if (chant.realOrParody == 'parody')
                    Text('parody', style: textTheme.labelSmall),
                  const Spacer(),
                  VoteControls(chant: chant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold foil gradient badge for verified chants. Feels earned, not flat.
class _GoldFoilBadge extends StatelessWidget {
  const _GoldFoilBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.goldFoilStart, AppColors.goldFoilEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        'VERIFIED',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: 'Oswald',
              color: AppColors.goldOnDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
