import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

class ChantCard extends StatelessWidget {
  final Chant chant;
  final String? teamName;
  final String? playerName;
  final bool rising;
  final bool actionsEnabled;
  final bool homePreview;
  final EdgeInsetsGeometry? margin;
  final Color risingColor;
  final VoidCallback onTap;

  const ChantCard({
    super.key,
    required this.chant,
    this.teamName,
    this.playerName,
    this.rising = false,
    this.actionsEnabled = true,
    this.homePreview = false,
    this.margin,
    this.risingColor = AppColors.success,
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
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
      shape: homePreview
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(
                color: chant.status == 'community'
                    ? AppColors.chantLab.withValues(alpha: 0.32)
                    : AppColors.outline,
              ),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: homePreview ? Spacing.lg : Spacing.md,
            vertical: homePreview ? Spacing.md : Spacing.sm,
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
                  const SizedBox(width: Spacing.xs),
                  Flexible(child: ChantProvenanceLabel(chant: chant)),
                ],
              ),
              const SizedBox(height: Spacing.xs),

              // Title: Anton, smaller than screen titles, subtle gold echo
              Text(
                chant.title.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  fontSize: homePreview ? 20 : null,
                  shadows: [
                    Shadow(
                      color: AppColors.gold.withValues(alpha: 0.30),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
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
              if (homePreview)
                const Divider(height: Spacing.lg, color: AppColors.outline)
              else
                const SizedBox(height: Spacing.sm),

              // Footer: subject tag (left) | comment count + vote chip (right)
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
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
                        if (rising)
                          Text(
                            'RISING',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 9,
                              color: risingColor,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (chant.commentCount > 0) ...[
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      '${chant.commentCount}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                  ],
                  VoteControls(
                    key: ValueKey(chant.id),
                    chant: chant,
                    compact: true,
                    enabled: actionsEnabled,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
