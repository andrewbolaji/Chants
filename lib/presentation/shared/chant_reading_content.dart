import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_evidence.dart';
import 'package:chants/presentation/shared/evidence_link_action.dart';
import 'package:chants/presentation/shared/halftone_painter.dart';
import 'package:flutter/material.dart';

TextAlign chantLyricsAlignment(String lyrics) {
  final lines = lyrics.split('\n');
  if (lines.length > 10) return TextAlign.left;
  if (lines.any((line) => line.length > 45)) return TextAlign.left;
  return TextAlign.center;
}

class ChantReadingContent extends StatelessWidget {
  final String title;
  final String lyrics;
  final String tuneName;
  final String? contextNotes;
  final List<ChantVariation> variations;
  final Widget provenanceLabel;
  final ChantEvidence? evidence;
  final bool showMediaPlaceholder;
  final bool signalAppearance;

  const ChantReadingContent({
    super.key,
    required this.title,
    required this.lyrics,
    required this.tuneName,
    required this.contextNotes,
    required this.variations,
    required this.provenanceLabel,
    this.evidence,
    this.showMediaPlaceholder = false,
    this.signalAppearance = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lyricAlign = chantLyricsAlignment(lyrics);
    final accentColor = signalAppearance
        ? AppColors.signalGold
        : AppColors.gold;
    final titleColor = signalAppearance
        ? AppColors.signalInk
        : AppColors.textHeadline;
    final bodyColor = signalAppearance
        ? AppColors.signalInk
        : AppColors.textBody;
    final mutedColor = signalAppearance
        ? AppColors.signalTextMuted
        : AppColors.textMuted;
    final panelColor = signalAppearance
        ? AppColors.signalPaper
        : AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          painter: HalftonePainter(opacity: signalAppearance ? 0 : 0.04),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: signalAppearance ? AppColors.signalPaper : null,
              gradient: signalAppearance
                  ? null
                  : const RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [AppColors.glowGold, Colors.transparent],
                    ),
              border: signalAppearance
                  ? const Border(
                      bottom: BorderSide(color: AppColors.signalRule),
                    )
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.lg,
              Spacing.xl,
              Spacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                provenanceLabel,
                const SizedBox(height: Spacing.xl),
                Text(
                  title.toUpperCase(),
                  style: textTheme.headlineLarge?.copyWith(
                    color: titleColor,
                    shadows: [
                      Shadow(
                        color: accentColor.withValues(
                          alpha: signalAppearance ? 0.22 : 1,
                        ),
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.music_note_outlined, size: 14, color: mutedColor),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      tuneName.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(color: mutedColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xxl),
              SizedBox(
                width: double.infinity,
                child: Text(
                  lyrics,
                  textAlign: lyricAlign,
                  style: textTheme.bodyLarge?.copyWith(color: bodyColor),
                ),
              ),
              const SizedBox(height: Spacing.xxl),
              if (contextNotes != null && contextNotes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: signalAppearance
                        ? Border.all(color: AppColors.signalRule)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTEXT',
                        style: textTheme.labelMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        contextNotes!,
                        style: textTheme.bodyMedium?.copyWith(color: bodyColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),
              ],
              if (ChantEvidenceParser.isCanonical(evidence)) ...[
                EvidenceLinkAction(evidence: evidence!),
                const SizedBox(height: Spacing.xl),
              ],
              if (variations.isNotEmpty) ...[
                Text(
                  'ALSO SUNG AS',
                  style: textTheme.labelMedium?.copyWith(color: mutedColor),
                ),
                const SizedBox(height: Spacing.md),
                for (final variation in variations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: signalAppearance
                            ? Border.all(color: AppColors.signalRule)
                            : null,
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
                              color: mutedColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              variation.label.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 9,
                                color: mutedColor,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              variation.lyric,
                              textAlign: chantLyricsAlignment(variation.lyric),
                              style: textTheme.bodyLarge?.copyWith(
                                color: bodyColor,
                              ),
                            ),
                          ),
                          if (variation.contextNote != null &&
                              variation.contextNote!.isNotEmpty) ...[
                            const SizedBox(height: Spacing.sm),
                            Text(
                              variation.contextNote!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: bodyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.md),
              ],
              if (showMediaPlaceholder) ...[
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: mutedColor,
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
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}
