import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// Gold foil gradient badge for verified chants. Feels earned, not flat.
/// Shared across chant card and chant detail.
class GoldFoilBadge extends StatelessWidget {
  const GoldFoilBadge({super.key});

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
              fontVariations: const [FontVariation('wght', 700)],
              color: AppColors.goldOnDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
