import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';

class BrowseSupportingNotice extends StatelessWidget {
  final String label;
  final String message;
  final IconData icon;

  const BrowseSupportingNotice({
    super.key,
    required this.label,
    required this.message,
    required this.icon,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
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
