import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

/// Fanzine error/offline state. Full personality: stamped error mark,
/// Anton headline, clear statement, loud retry button.
class ErrorState extends StatelessWidget {
  final String headline;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.headline = 'SOMETHING WENT WRONG',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stamped error icon with tilt
            Transform.rotate(
              angle: 2 * math.pi / 180,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 32,
                  color: AppColors.error,
                ),
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
            // Clear message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: onRetry,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
