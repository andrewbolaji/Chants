import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/gold_foil_badge.dart';

class ChantProvenanceLabel extends StatelessWidget {
  final String status;
  final ChantOrigin? origin;

  ChantProvenanceLabel({super.key, required Chant chant})
    : status = chant.status,
      origin = chant.origin;

  const ChantProvenanceLabel.fromValues({
    super.key,
    required this.status,
    required this.origin,
  });

  String get _label {
    return switch (origin) {
      ChantOrigin.alreadySung => 'ALREADY SUNG, UNVERIFIED',
      ChantOrigin.originalIdea => 'ORIGINAL IDEA',
      null => 'COMMUNITY CHANT',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'canonical') return const GoldFoilBadge();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        _label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
