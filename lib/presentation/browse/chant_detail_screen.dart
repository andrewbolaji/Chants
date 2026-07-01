import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/gold_foil_badge.dart';
import 'package:chants/presentation/shared/halftone_painter.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

/// Whether lyrics should be centered (anthem feel) or left-aligned.
/// Fall back to left if any line > 45 chars or > 10 lines total.
TextAlign _lyricsAlignment(String lyrics) {
  final lines = lyrics.split('\n');
  if (lines.length > 10) return TextAlign.left;
  if (lines.any((l) => l.length > 45)) return TextAlign.left;
  return TextAlign.center;
}

class ChantDetailScreen extends ConsumerWidget {
  final Chant chant;
  const ChantDetailScreen({super.key, required this.chant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSignedIn = authState.valueOrNull != null;
    final textTheme = Theme.of(context).textTheme;

    // Live single-doc stream so VoteControls.didUpdateWidget fires when
    // the CF updates score, and the delete window self-corrects.
    final chantStream = ref
        .watch(chantRepositoryProvider)
        .chantStream(chant.id);

    return StreamBuilder<Chant?>(
      stream: chantStream,
      initialData: chant,
      builder: (context, snap) {
        final live = snap.data ?? chant;
        return _buildScaffold(
          context, ref, live, isSignedIn, textTheme);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    Chant live,
    bool isSignedIn,
    TextTheme textTheme,
  ) {
    final lyricAlign = _lyricsAlignment(live.lyrics);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report this chant',
            onPressed: () {
              if (!isSignedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sign in to report this chant.'),
                  ),
                );
                return;
              }
              showReportSheet(
                context: context,
                chantId: live.id,
                ref: ref,
              );
            },
          ),
        ],
      ),
      // Stamped vote control pinned at bottom
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VoteControls(chant: live, large: true),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOUD HEADER ZONE: halftone wash, Anton title with print-echo
            // shadow, sticker badge, mono tune line
            CustomPaint(
              painter: const HalftonePainter(opacity: 0.04),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [AppColors.glowGold, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl, Spacing.lg, Spacing.xl, Spacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata row: badge + parody flag
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.xs,
                      children: [
                        if (live.status == 'canonical') const GoldFoilBadge(),
                        if (live.realOrParody == 'parody')
                          _ParodyFlag(),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Title: Anton with 1.5px print-echo gold shadow
                    Text(
                      live.title.toUpperCase(),
                      style: textTheme.headlineLarge?.copyWith(
                        shadows: const [
                          Shadow(
                            color: AppColors.gold,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content below the loud header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tune line: Space Mono
                  Row(
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          live.tuneName.toUpperCase(),
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // LYRICS: Fraunces, large, centered or left-aligned
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      live.lyrics,
                      textAlign: lyricAlign,
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),

                  // Context notes
                  if (live.contextNotes != null &&
                      live.contextNotes!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTEXT',
                            style: textTheme.labelMedium,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            live.contextNotes!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],

                  // Variations: "Also sung as"
                  if (live.variations.isNotEmpty) ...[
                    Text(
                      'ALSO SUNG AS',
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: Spacing.md),
                    ...live.variations.map((v) {
                      final varAlign = _lyricsAlignment(v.lyric);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Spacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  v.lyric,
                                  textAlign: varAlign,
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              if (v.contextNote != null &&
                                  v.contextNote!.isNotEmpty) ...[
                                const SizedBox(height: Spacing.sm),
                                Text(
                                  v.contextNote!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: Spacing.md),
                  ],

                  // Media placeholder
                  if (live.mediaType != 'none') ...[
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'Audio will be available soon.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],

                  const SizedBox(height: Spacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParodyFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'PARODY',
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 9,
          color: AppColors.gold,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
