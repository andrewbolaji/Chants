import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:firebase_core/firebase_core.dart';

final discoveryProvider = FutureProvider<List<Chant>>((ref) {
  return ref.watch(chantRepositoryProvider).discoveryChants();
});

final allTeamsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref
      .watch(teamRepositoryProvider)
      .teamsForCompetitionStream(competitionId: 'premier-league')
      .map((teams) => {for (final t in teams) t.id: t.name});
});

bool isChantPermissionDenied(Object? error) {
  if (error is! FirebaseException) return false;
  final code = error.code.toLowerCase().replaceAll('_', '-');
  return code == 'permission-denied';
}

class DiscoverySection extends ConsumerWidget {
  final String searchQuery;
  final bool groupByTrust;

  const DiscoverySection({
    super.key,
    this.searchQuery = '',
    this.groupByTrust = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chantsFuture = ref.watch(discoveryProvider);
    final teamsMap = ref.watch(allTeamsProvider);

    return chantsFuture.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => ErrorState(
        message: 'Could not load chants. Try again.',
        onRetry: () => ref.invalidate(discoveryProvider),
      ),
      data: (chants) {
        if (chants.isEmpty) {
          return const EmptyState(
            headline: 'NO CHANTS YET',
            message: 'Check back soon. The terrace is warming up.',
          );
        }

        final teamNames = teamsMap.valueOrNull ?? {};
        final isSearching = searchQuery.isNotEmpty;

        // Filter by search query (title, lyrics, tune, team name)
        final filtered = isSearching
            ? chants.where((c) {
                final q = searchQuery.toLowerCase();
                final team = teamNames[c.teamId]?.toLowerCase() ?? '';
                return c.title.toLowerCase().contains(q) ||
                    c.lyrics.toLowerCase().contains(q) ||
                    c.tuneName.toLowerCase().contains(q) ||
                    team.contains(q);
              }).toList()
            : chants;

        if (isSearching && filtered.isEmpty) {
          return const EmptyState(
            headline: 'NOTHING MATCHES THAT',
            message:
                'Try a different word or browse the clubs to find what you want.',
            icon: Icons.search_off,
          );
        }

        if (groupByTrust && !isSearching) {
          final terraceProven = filtered
              .where((chant) => chant.status == 'canonical')
              .take(1)
              .toList();
          final chantLab = filtered
              .where((chant) => chant.status == 'community')
              .take(1)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSectionHeader(
                label: 'Terrace Proven',
                accent: AppColors.gold,
                onShuffle: () => ref.invalidate(discoveryProvider),
              ),
              if (terraceProven.isEmpty)
                _HomeGroupEmpty(
                  message: 'No Terrace Proven chant in this mix.',
                  actionLabel: 'SHUFFLE',
                  onAction: () => ref.invalidate(discoveryProvider),
                )
              else
                ...terraceProven.map(
                  (chant) => _LiveChantCard(
                    key: ValueKey(chant.id),
                    initialChant: chant,
                    teamName: teamNames[chant.teamId],
                    homePreview: true,
                  ),
                ),
              const SizedBox(height: Spacing.md),
              const _HomeSectionHeader(
                label: 'Chant Lab',
                accent: AppColors.chantLab,
                icon: Icons.bolt_rounded,
              ),
              if (chantLab.isEmpty)
                _HomeGroupEmpty(
                  message: 'No new ideas in this mix. Choose a club to start.',
                  actionLabel: 'BROWSE CLUBS',
                  onAction: () => Navigator.pushNamed(
                    context,
                    AppRouter.competition,
                    arguments: const {
                      'id': 'premier-league',
                      'name': 'Premier League',
                    },
                  ),
                )
              else
                ...chantLab.map(
                  (chant) => _LiveChantCard(
                    key: ValueKey(chant.id),
                    initialChant: chant,
                    teamName: teamNames[chant.teamId],
                    rising: true,
                    homePreview: true,
                  ),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  SectionEyebrow(
                    text: isSearching ? 'Search results' : 'Discover',
                    gold: isSearching,
                  ),
                  const Spacer(),
                  if (!isSearching)
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      tooltip: 'Shuffle',
                      onPressed: () => ref.invalidate(discoveryProvider),
                    ),
                ],
              ),
            ),
            ...filtered
                .take(20)
                .map(
                  (chant) => _LiveChantCard(
                    key: ValueKey(chant.id),
                    initialChant: chant,
                    teamName: teamNames[chant.teamId],
                    homePreview: groupByTrust,
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Wraps a ChantCard with a live single-doc stream so scores update
/// without reshuffling the Discover order.
class _LiveChantCard extends ConsumerWidget {
  final Chant initialChant;
  final String? teamName;
  final bool rising;
  final bool homePreview;

  const _LiveChantCard({
    super.key,
    required this.initialChant,
    this.teamName,
    this.rising = false,
    this.homePreview = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(chantRepositoryProvider)
        .chantStream(initialChant.id);

    return StreamBuilder<LiveChantSnapshot>(
      stream: stream,
      initialData: LiveChantSnapshot(chant: initialChant, isFromCache: true),
      builder: (context, snap) {
        final permissionDenied = isChantPermissionDenied(snap.error);
        final currentSnapshot = snap.data;
        final hasAuthoritativeValue =
            snap.connectionState == ConnectionState.active &&
            !snap.hasError &&
            currentSnapshot != null &&
            !currentSnapshot.isFromCache;
        final current = currentSnapshot?.chant;
        if (permissionDenied ||
            (hasAuthoritativeValue &&
                (current == null || current.hidden || current.removed))) {
          return const SizedBox.shrink();
        }

        final live = current ?? initialChant;
        if (live.hidden || live.removed) return const SizedBox.shrink();
        return ChantCard(
          chant: live,
          teamName: teamName,
          rising: rising,
          actionsEnabled: hasAuthoritativeValue,
          homePreview: homePreview,
          margin: homePreview
              ? const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.xs,
                )
              : null,
          risingColor: homePreview ? AppColors.chantLab : AppColors.success,
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.chantDetail,
            arguments: ChantDetailRouteArguments(chant: live),
          ),
        );
      },
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData? icon;
  final VoidCallback? onShuffle;

  const _HomeSectionHeader({
    required this.label,
    required this.accent,
    this.icon,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
        Spacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: Spacing.sm),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 12,
                      color: AppColors.textHeadline,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Container(width: 56, height: 2, color: accent),
                ],
              ),
            ),
          ),
          if (onShuffle != null)
            IconButton(
              tooltip: 'Shuffle Home chants',
              onPressed: onShuffle,
              icon: const Icon(Icons.shuffle_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}

class _HomeGroupEmpty extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _HomeGroupEmpty({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.sm,
            Spacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
