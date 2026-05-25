import 'package:flutter/material.dart';

/// Chants color tokens. The single source of truth for every color in the app.
/// No raw hex literals in widgets. Reference via Theme.of(context).extension with AppColors
/// or the static constants for non-context use.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Core palette
  static const background = Color(0xFF0B0B0C);
  static const surface = Color(0xFF141416);
  static const surfaceRaised = Color(0xFF1C1C1F);

  // Text hierarchy
  static const textPrimary = Color(0xFFF4F4F2);
  static const textMuted = Color(0xFF8A8A8F);
  static const textFaint = Color(0xFF56565B); // Decorative only, never body text

  // The single accent: warm amber. Action and earned status only.
  static const amber = Color(0xFFFFB627);
  static const amberOnDark = Color(0xFF0B0B0C); // Text on amber fill

  // Semantic
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF66BB6A);

  // Structural
  static const divider = Color(0x12FFFFFF); // white at ~7% opacity
  static const outline = Color(0xFF2E2E32);

  // Instance fields for ThemeExtension
  final Color accentColor;
  final Color surfaceColor;
  final Color surfaceRaisedColor;
  final Color textMutedColor;
  final Color textFaintColor;
  final Color dividerColor;

  const AppColors({
    this.accentColor = amber,
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
