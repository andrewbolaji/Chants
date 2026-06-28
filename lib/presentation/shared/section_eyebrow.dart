import 'package:flutter/material.dart';
import 'package:chants/app/colors.dart';

/// Space Mono uppercase eyebrow for section headers.
/// Used for CLUB CHANTS, PLAYER CHANTS, DISCOVER, etc.
class SectionEyebrow extends StatelessWidget {
  final String text;
  final bool gold;

  const SectionEyebrow({super.key, required this.text, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 11,
        color: gold ? AppColors.gold : AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}
