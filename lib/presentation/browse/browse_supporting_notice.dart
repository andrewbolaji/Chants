import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

class BrowseSupportingNotice extends StatelessWidget {
  final String label;
  final String message;
  final IconData icon;
  final bool signalAppearance;

  const BrowseSupportingNotice({
    super.key,
    required this.label,
    required this.message,
    required this.icon,
    this.signalAppearance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label. $message',
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          0,
        ),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: signalAppearance ? AppColors.signalPaper : AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: signalAppearance ? AppColors.signalRule : AppColors.outline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: signalAppearance
                  ? AppColors.signalForestMuted
                  : AppColors.textMuted,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: Spacing.xs),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
