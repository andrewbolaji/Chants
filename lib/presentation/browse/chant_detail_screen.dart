import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/report/report_sheet.dart';
import 'package:chants/presentation/shared/vote_controls.dart';

class ChantDetailScreen extends ConsumerWidget {
  final Chant chant;
  const ChantDetailScreen({super.key, required this.chant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSignedIn = authState.valueOrNull != null;
    final textTheme = Theme.of(context).textTheme;

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
                chantId: chant.id,
                ref: ref,
              );
            },
          ),
        ],
      ),
      // Vote controls pinned at bottom as large tap targets
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
              VoteControls(chant: chant, large: true),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.lg),

            // Quiet metadata row: status, subject tag, real/parody
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              children: [
                if (chant.status == 'canonical')
                  const _Badge(label: 'Verified', isAmber: true),
                _Badge(label: chant.subjectTag, isAmber: false),
                if (chant.realOrParody == 'parody')
                  const _Badge(label: 'Parody', isAmber: false),
              ],
            ),
            const SizedBox(height: Spacing.xl),

            // Title: bold, large
            Text(
              chant.title,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: Spacing.lg),

            // Tune: icon + name
            Row(
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    chant.tuneName,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xxl),

            // Lyrics: the hero. Large, airy, high contrast.
            Text(
              chant.lyrics,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: Spacing.xxl),

            // Context notes (only when non-empty)
            if (chant.contextNotes != null &&
                chant.contextNotes!.isNotEmpty) ...[
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
                      'Context',
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      chant.contextNotes!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],

            // Media: only if present, no empty placeholder (Addition E)
            if (chant.mediaType != 'none') ...[
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
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isAmber;

  const _Badge({required this.label, required this.isAmber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isAmber
            ? AppColors.amber.withValues(alpha: 0.15)
            : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isAmber ? AppColors.amber : AppColors.textMuted,
              fontWeight: isAmber ? FontWeight.w600 : FontWeight.w500,
            ),
      ),
    );
  }
}
