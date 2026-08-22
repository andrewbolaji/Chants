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
  final VoidCallback onTap;

  const SavedChantCard({
    super.key,
    required this.chant,
    required this.teamName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
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
                  shadows: [
                    Shadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              Text(
                teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                chant.lyrics.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Fraunces',
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              const Text(
                'SAVED COPY',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
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

  const SavedFreshnessNotice({
    super.key,
    required this.refreshedAt,
    this.message,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.offline_pin_outlined,
            size: 20,
            color: AppColors.gold,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED COPY  •  LAST REFRESHED ${savedSongbookDate(refreshedAt)}',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeadline,
                    letterSpacing: 0.5,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    message!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
