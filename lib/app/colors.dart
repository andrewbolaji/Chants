import 'package:flutter/material.dart';

/// Chants color tokens: matchnight, warmed with playful.
/// Warm charcoal base, gold accent, warm chalk text.
/// No raw hex literals in widgets.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Core palette: warm floodlit night
  static const background = Color(0xFF16140F);
  static const surface = Color(0xFF1E1A14);
  static const surfaceRaised = Color(0xFF231B11);

  // Text hierarchy: warm chalk
  static const textPrimary = Color(0xFFF6EEDC);
  static const textMuted = Color(0xFFB0A083); // 5.8:1 on base, AA
  static const textFaint = Color(0xFF6B5F4A); // 3.1:1, decorative only

  // The single accent: trophy gold. Action, active, and earned status.
  static const gold = Color(0xFFFFB627);
  static const goldOnDark = Color(0xFF16140F);

  // Gold foil gradient for the verified mark
  static const goldFoilStart = Color(0xFFFFB627);
  static const goldFoilEnd = Color(0xFFFFC94D);

  // Semantic
  static const error = Color(0xFFEF6461); // 5.0:1 on base, AA
  static const success = Color(0xFF66BB6A);

  // Structural
  static const divider = Color(0x14FFFFFF); // warm white ~8%
  static const outline = Color(0xFF3A3020);

  // Floodlight glow (detail hero)
  static const glowGold = Color(0x0FFFB627); // gold at ~6%

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
