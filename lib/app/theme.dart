import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

class ChantTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.amber,
        onPrimary: AppColors.amberOnDark,
        secondary: AppColors.amber,
        onSecondary: AppColors.amberOnDark,
        error: AppColors.error,
        onError: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.outline,
        surfaceContainerHighest: AppColors.surfaceRaised,
      ),
      textTheme: _textTheme,
      extensions: const [AppColors()],

      // App bar: flat, dark, no elevation
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Cards: surface color, no shadow, hairline border
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),

      // Dividers: hairline
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),

      // Primary button: amber fill, near-black text, 48px min height
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.amberOnDark,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textFaint,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button: amber text for secondary actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon buttons: minimum 48px tap target
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),

      // Input fields: dark fill, outline border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.outline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.amber, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textFaint),
      ),

      // Chips: quiet surface, compact
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      ),

      // Bottom sheet: surface color, rounded top
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.lg),
          ),
        ),
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: Spacing.md,
        contentPadding: EdgeInsets.symmetric(horizontal: Spacing.lg),
        iconColor: AppColors.textMuted,
      ),

      // FAB: amber
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.amberOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),

      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.amber,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.amber,
        dividerColor: AppColors.divider,
      ),

      // Segmented button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.amber;
            }
            return AppColors.surfaceRaised;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.amberOnDark;
            }
            return AppColors.textMuted;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber;
          return AppColors.surfaceRaised;
        }),
        checkColor: WidgetStateProperty.all(AppColors.amberOnDark),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber;
          return AppColors.textMuted;
        }),
      ),
    );
  }

  static const _textTheme = TextTheme(
    // App title, big hero text
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    // Screen titles
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
    // Card titles, section headers
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // Tune name, secondary titles
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // Lyrics (the sacred style: large, airy, high contrast)
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.7,
    ),
    // Previews, secondary text
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    // Metadata, timestamps
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    // Labels, overlines
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
    // Badges, chips, tags
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    ),
  );
}
