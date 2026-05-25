import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/report/report_sheet.dart';

class ChantDetailScreen extends ConsumerWidget {
  final Chant chant;
  const ChantDetailScreen({super.key, required this.chant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isSignedIn = authState.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(chant.title),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image placeholder
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.music_note,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            // Status and tags
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Badge(
                  label: chant.status == 'canonical' ? 'Canonical' : 'Community',
                  isPrimary: chant.status == 'canonical',
                  context: context,
                ),
                _Badge(
                  label: chant.subjectTag,
                  isPrimary: false,
                  context: context,
                ),
                if (chant.realOrParody == 'parody')
                  _Badge(
                    label: 'Parody',
                    isPrimary: false,
                    context: context,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Tune
            Text(
              'To the tune of:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              chant.tuneName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 24),

            // Lyrics
            Text(
              'Lyrics',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chant.lyrics,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Context notes (if present)
            if (chant.contextNotes != null &&
                chant.contextNotes!.isNotEmpty) ...[
              Text(
                'Context',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(chant.contextNotes!),
              const SizedBox(height: 24),
            ],

            // Media placeholder (only if media exists)
            if (chant.mediaType != 'none') ...[
              Text(
                'Media',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      'Audio will be available soon.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final BuildContext context;

  const _Badge({
    required this.label,
    required this.isPrimary,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
