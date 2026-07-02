import 'package:flutter/material.dart';

/// Chants color tokens v3: Ink and Gold direction.
/// Neutral deep-charcoal surfaces, near-black base, gold accent.
/// No raw hex literals in widgets.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Core palette: ink-dark neutral base
  static const background = Color(0xFF060606);
  static const surface = Color(0xFF161616);
  static const surfaceRaised = Color(0xFF1C1C1C);

  // Text hierarchy: softened off pure white for comfort
  static const textHeadline = Color(0xFFE9E0CE); // titles, headlines
  static const textBody = Color(0xFFD9CFBD); // reading, body text
  static const textMuted = Color(0xFFA1937D); // secondary, metadata
  static const textFaint = Color(0xFF6B5F4A); // decorative only

  // Legacy alias so existing code compiles during migration
  static const textPrimary = textHeadline;

  // The single accent: trophy gold (Ink and Gold, punchier).
  static const gold = Color(0xFFFFC02E);
  static const goldBright = Color(0xFFFFD04D);
  static const goldOnDark = Color(0xFF060606);

  // Gold foil gradient for the verified sticker
  static const goldFoilStart = Color(0xFFFFC02E);
  static const goldFoilEnd = Color(0xFFFFD04D);

  // Semantic
  static const error = Color(0xFFEF6461);
  static const success = Color(0xFF66BB6A);

  // Structural
  static const divider = Color(0x14FFFFFF); // neutral white ~8%
  static const outline = Color(0xFF2B2B28);

  // Floodlight glow (detail hero)
  static const glowGold = Color(0x0FFFC02E); // gold at ~6%

  // Instance fields for ThemeExtension
  final Color accentColor;
  final Color surfaceColor;
  final Color surfaceRaisedColor;
  final Color textMutedColor;
  final Color textFaintColor;
  final Color dividerColor;

  const AppColors({
    this.accentColor = gold,
    this.surfaceColor = surface,
    this.surfaceRaisedColor = surfaceRaised,
    this.textMutedColor = textMuted,
    this.textFaintColor = textFaint,
    this.dividerColor = divider,
  });

  @override
  AppColors copyWith({
    Color? accentColor,
    Color? surfaceColor,
    Color? surfaceRaisedColor,
    Color? textMutedColor,
    Color? textFaintColor,
    Color? dividerColor,
  }) {
    return AppColors(
      accentColor: accentColor ?? this.accentColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceRaisedColor: surfaceRaisedColor ?? this.surfaceRaisedColor,
      textMutedColor: textMutedColor ?? this.textMutedColor,
      textFaintColor: textFaintColor ?? this.textFaintColor,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      surfaceRaisedColor:
          Color.lerp(surfaceRaisedColor, other.surfaceRaisedColor, t)!,
      textMutedColor: Color.lerp(textMutedColor, other.textMutedColor, t)!,
      textFaintColor: Color.lerp(textFaintColor, other.textFaintColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
    );
  }
}
