import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The calm utility half of the Chants release system.
///
/// Stage owns the black broadcast treatment. Club directories, club Songbooks,
/// and saved matchday copies use this light, club-neutral signal treatment so
/// supporters can scan names and saved status quickly.
abstract final class ClubSignalTheme {
  static ThemeData from(ThemeData base) {
    final signalTextTheme = base.textTheme
        .apply(
          bodyColor: AppColors.signalInk,
          displayColor: AppColors.signalInk,
        )
        .copyWith(
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: AppColors.signalTextMuted,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: AppColors.signalTextMuted,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            color: AppColors.signalTextMuted,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            color: AppColors.signalTextMuted,
          ),
        );

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.signalCanvas,
      colorScheme: const ColorScheme.light(
        surface: AppColors.signalPaper,
        primary: AppColors.signalForest,
        onPrimary: AppColors.signalPaper,
        secondary: AppColors.signalGold,
        onSecondary: AppColors.signalInk,
        error: AppColors.error,
        onError: Colors.white,
        onSurface: AppColors.signalInk,
        onSurfaceVariant: AppColors.signalTextMuted,
        outline: AppColors.signalRule,
        surfaceContainerHighest: AppColors.signalPaperMuted,
      ),
      textTheme: signalTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.signalForest,
        foregroundColor: AppColors.signalPaper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Anton',
          color: AppColors.signalPaper,
          fontSize: 21,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.signalPaper, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.stageChrome,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.signalPaper,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.signalRule, width: 0.5),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.signalRule,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: Spacing.md,
        contentPadding: EdgeInsets.symmetric(horizontal: Spacing.lg),
        iconColor: AppColors.signalForestMuted,
        textColor: AppColors.signalInk,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.signalForest,
          foregroundColor: AppColors.signalPaper,
          disabledBackgroundColor: AppColors.signalPaperMuted,
          disabledForegroundColor: AppColors.signalForestMuted,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.signalForest,
        foregroundColor: AppColors.signalPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.signalPaperMuted,
        indicatorColor: AppColors.gold,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.signalForest;
            }
            return AppColors.signalPaper;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.signalPaper;
            }
            return AppColors.signalTextMuted;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.signalRule),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.signalGold,
      ),
      snackBarTheme: base.snackBarTheme,
    );
  }
}

class ClubSignalHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String message;

  const ClubSignalHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xl,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: AppColors.signalGold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Anton',
              color: AppColors.signalInk,
              fontSize: 28,
              height: 1.05,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.signalTextMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ClubSignalState extends StatelessWidget {
  final String headline;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ClubSignalState({
    super.key,
    required this.headline,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.signalPaper,
                border: Border.all(color: AppColors.signalRule),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, color: AppColors.signalForestMuted, size: 28),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              headline.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Anton',
                fontSize: 20,
                color: AppColors.signalInk,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.signalTextMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
