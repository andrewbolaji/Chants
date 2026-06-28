import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// Fanzine empty state. Full personality: stamped mark, Anton headline,
/// fan-voiced nudge. This is a loud surface (no reading load).
class EmptyState extends StatelessWidget {
  final String headline;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    this.headline = 'NOTHING HERE YET',
    required this.message,
    this.icon = Icons.music_off_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stamped icon with slight rotation
            Transform.rotate(
              angle: -3 * math.pi / 180,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textFaint, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 32, color: AppColors.textFaint),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // Anton headline
            Text(
              headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Anton',
                fontSize: 22,
                color: AppColors.textHeadline,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // Fan-voiced nudge
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
