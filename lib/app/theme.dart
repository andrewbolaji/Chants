import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';

// Variable font weight axis values. Pin the actual rendered weight
// because pubspec weight alone does not set a variable font's wght axis.
//
// Anton: static single-weight font, no FontVariation needed.
// Space Mono: static Regular + Bold, no FontVariation needed.
// Fraunces: variable font, pin wght axis.
// Nunito: variable font, pin wght axis.
const _fraunces400 = [FontVariation('wght', 400)];
const _nunito400 = [FontVariation('wght', 400)];
const _nunito700 = [FontVariation('wght', 700)];

class ChantTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.gold,
        onPrimary: AppColors.goldOnDark,
        secondary: AppColors.gold,
        onSecondary: AppColors.goldOnDark,
        error: AppColors.error,
        onError: AppColors.textHeadline,
        onSurface: AppColors.textHeadline,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.outline,
        surfaceContainerHighest: AppColors.surfaceRaised,
      ),
      fontFamily: 'Nunito',
      textTheme: _textTheme,
      extensions: const [AppColors()],

      // App bar: warm background, Anton title
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textHeadline,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Anton',
          color: AppColors.textHeadline,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textHeadline,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Cards: warm surface, rounded
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaised,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      // Dividers: warm hairline
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),

      // Primary button: gold fill, warm-dark text, rounded, 48px min
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldOnDark,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textFaint,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Anton',
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text button: gold text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontVariations: _nunito700,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Icon buttons: 48px minimum
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),

      // Input fields: warm fill, warm outline
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.gold, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontVariations: _nunito400,
          color: AppColors.textMuted,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontVariations: _nunito400,
          color: AppColors.textFaint,
        ),
      ),

      // Chips: warm surface, Space Mono
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      ),

      // Bottom sheet: warm surface, rounded top
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
        contentTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontVariations: _nunito400,
          color: AppColors.textHeadline,
        ),
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

      // FAB: gold, rounded
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      // Popup menu: warm
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),

      // Tab bar: gold active, Anton labels
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.gold,
        dividerColor: AppColors.divider,
        labelStyle: TextStyle(
          fontFamily: 'Anton',
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Anton',
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),

      // Segmented button: gold selected
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.gold;
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.goldOnDark;
            }
            return AppColors.textMuted;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
          textStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Nunito',
            fontVariations: _nunito700,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),

      // Progress indicator: gold
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),

      // Checkbox: gold
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return AppColors.surface;
        }),
        checkColor: WidgetStateProperty.all(AppColors.goldOnDark),
      ),

      // Radio: gold
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return AppColors.textMuted;
        }),
      ),
    );
  }

  // Three-voice type system: Anton (shout) + SpaceMono (zine) + Fraunces (reading) + Nunito (UI body)
  static const _textTheme = TextTheme(
    // Hero display: Anton condensed uppercase
    headlineLarge: TextStyle(
      fontFamily: 'Anton',
      fontSize: 28,
      color: AppColors.textHeadline,
      letterSpacing: 1.0,
    ),
    // Screen titles: Anton
    headlineMedium: TextStyle(
      fontFamily: 'Anton',
      fontSize: 24,
      color: AppColors.textHeadline,
      letterSpacing: 0.5,
    ),
    // Card titles: Anton condensed (smaller than screen titles)
    titleMedium: TextStyle(
      fontFamily: 'Anton',
      fontSize: 17,
      color: AppColors.textHeadline,
      letterSpacing: 0.3,
    ),
    // Small headers: Anton
    titleSmall: TextStyle(
      fontFamily: 'Anton',
      fontSize: 14,
      color: AppColors.textHeadline,
      letterSpacing: 0.5,
    ),
    // LYRICS: the singable centerpiece. Fraunces, large, warm.
    bodyLarge: TextStyle(
      fontFamily: 'Fraunces',
      fontVariations: _fraunces400,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: AppColors.textBody,
      height: 1.6,
    ),
    // Body text, previews: Nunito
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontVariations: _nunito400,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    // Metadata: Nunito
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontVariations: _nunito400,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    // Eyebrows, labels: Space Mono uppercase
    labelMedium: TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: 11,
      color: AppColors.textMuted,
      letterSpacing: 1.2,
    ),
    // Badges, chips, vote numbers: Space Mono
    labelSmall: TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: 11,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    ),
  );
}
