import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// Compact trust badge for chants with accepted evidence of match use.
/// Community chants show no badge.
class GoldFoilBadge extends StatelessWidget {
  const GoldFoilBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Terrace Proven. Verified as sung at matches.',
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: AppColors.gold, width: 0.75),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: AppColors.gold,
                        size: 13,
                      ),
                      SizedBox(width: Spacing.xs),
                      Text(
                        'TERRACE PROVEN',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
