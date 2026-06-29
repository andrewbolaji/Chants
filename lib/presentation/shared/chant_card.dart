import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/gold_foil_badge.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

class ChantCard extends StatelessWidget {
  final Chant chant;
  final String? teamName;
  final String? playerName;
  final VoidCallback onTap;

  const ChantCard({
    super.key,
    required this.chant,
    this.teamName,
    this.playerName,
    required this.onTap,
  });

  String get _whoLine {
    if (playerName != null && teamName != null) {
      return '$playerName / $teamName';
    }
    if (playerName != null) return playerName!;
    if (teamName != null) return teamName!;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final who = _whoLine;

    final subjectLabel = chant.subjectTag.toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow: tune name in Space Mono + verified sticker
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
                  if (chant.status == 'canonical') ...[
                    const SizedBox(width: Spacing.xs),
                    const GoldFoilBadge(),
                  ],
                ],
              ),
              const SizedBox(height: Spacing.xs),

              // Title: Anton, smaller than screen titles
              Text(
                chant.title.toUpperCase(),
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Gold who-it-is-for line
              if (who.isNotEmpty)
                Text(
                  who,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: AppColors.gold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: Spacing.xs),

              // One-line lyric preview in Fraunces
              Text(
                chant.lyrics.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Fraunces',
                  fontVariations: const [FontVariation('wght', 400)],
                  color: AppColors.textBody,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: Spacing.sm),

              // Footer: subject tag + parody pill (left) | vote chip (right)
              Row(
                children: [
                  Text(
                    subjectLabel,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (chant.realOrParody == 'parody') ...[
                    const SizedBox(width: Spacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: const Text(
                        'PARODY',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: AppColors.gold,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  VoteControls(chant: chant, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
