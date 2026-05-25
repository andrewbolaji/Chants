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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top line: muted metadata (status, tune, team)
            Row(
              children: [
                if (chant.status == 'canonical')
                  _AmberBadge(label: 'Canonical')
                else
                  Text('Community', style: textTheme.labelSmall),
                const SizedBox(width: Spacing.sm),
                Text('\u00b7', style: textTheme.labelSmall),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    chant.tuneName,
                    style: textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            // Bold title
            Text(
              chant.title,
              style: textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (teamName != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(teamName!, style: textTheme.bodySmall),
            ],
            const SizedBox(height: Spacing.xs),

            // One-line lyrics preview
            Text(
              chant.lyrics.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),

            // Quiet vote row
            Row(
              children: [
                if (chant.subjectTag != 'club') ...[
                  Text(
                    chant.subjectTag,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textFaint,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                if (chant.realOrParody == 'parody')
                  Text(
                    'parody',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textFaint,
                    ),
                  ),
                const Spacer(),
                VoteControls(chant: chant),
              ],
            ),

            // Hairline separator
            const Padding(
              padding: EdgeInsets.only(top: Spacing.md),
              child: Divider(height: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmberBadge extends StatelessWidget {
  final String label;
  const _AmberBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
