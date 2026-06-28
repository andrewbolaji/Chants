import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// Gold sticker badge for verified chants. Slight rotation and hard offset
/// shadow give the stuck-on fanzine feel. Community chants show no badge.
class GoldFoilBadge extends StatelessWidget {
  const GoldFoilBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -1.5 * math.pi / 180, // slight tilt
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + 2,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.goldFoilStart, AppColors.goldFoilEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.goldOnDark, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(1.5, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Text(
          'VERIFIED',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.goldOnDark,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
