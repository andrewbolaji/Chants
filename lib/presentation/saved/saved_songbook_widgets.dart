import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/presentation/shared/chant_provenance_label.dart';
import 'package:flutter/material.dart';

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

String savedSongbookDate(DateTime timestamp) {
  final local = timestamp.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

class SavedChantCard extends StatelessWidget {
  final SavedChantSnapshot chant;
  final String teamName;
  final bool signalAppearance;
  final VoidCallback onTap;

  const SavedChantCard({
    super.key,
    required this.chant,
    required this.teamName,
    this.signalAppearance = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cardColor = signalAppearance
        ? AppColors.signalPaper
        : AppColors.surfaceRaised;
    final borderColor = signalAppearance
        ? AppColors.signalRule
        : AppColors.outline;
    final titleColor = signalAppearance
        ? AppColors.signalInk
        : AppColors.textHeadline;
    final bodyColor = signalAppearance
        ? AppColors.signalTextMuted
        : AppColors.textBody;
    final metadataColor = signalAppearance
        ? AppColors.signalForestMuted
        : AppColors.textMuted;
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(
          signalAppearance ? Radii.sm : Radii.lg,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          signalAppearance ? Radii.sm : Radii.lg,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chant.tuneName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: ChantProvenanceLabel.fromValues(
                      status: chant.status,
                      origin: chant.origin,
                      signalAppearance: signalAppearance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                chant.title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  shadows: [
                    Shadow(
                      color: AppColors.signalGold.withValues(
                        alpha: signalAppearance ? 0.18 : 0.3,
                      ),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              Text(
                teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  color: signalAppearance
                      ? AppColors.signalGold
                      : AppColors.gold,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                chant.lyrics.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Fraunces',
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'SAVED COPY',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: metadataColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedFreshnessNotice extends StatelessWidget {
  final DateTime refreshedAt;
  final String? message;
  final bool signalAppearance;

  const SavedFreshnessNotice({
    super.key,
    required this.refreshedAt,
    this.message,
    this.signalAppearance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.md,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: signalAppearance ? AppColors.signalPaper : AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
          color: signalAppearance ? AppColors.signalRule : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.offline_pin_outlined,
            size: 20,
            color: signalAppearance ? AppColors.signalGold : AppColors.gold,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED COPY  •  LAST REFRESHED ${savedSongbookDate(refreshedAt)}',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: signalAppearance
                        ? AppColors.signalInk
                        : AppColors.textHeadline,
                    letterSpacing: 0.5,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: signalAppearance
                          ? AppColors.signalTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
