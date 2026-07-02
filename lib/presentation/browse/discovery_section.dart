import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

final discoveryProvider = FutureProvider<List<Chant>>((ref) {
  return ref.watch(chantRepositoryProvider).discoveryChants();
});

final allTeamsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref
      .watch(teamRepositoryProvider)
      .teamsForCompetitionStream(competitionId: 'premier-league')
      .map((teams) => {for (final t in teams) t.id: t.name});
});

class DiscoverySection extends ConsumerWidget {
  final String searchQuery;

  const DiscoverySection({super.key, this.searchQuery = ''});

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
        message: 'Could not load chants. Pull down to try again.',
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
            ...filtered.take(20).map((chant) => _LiveChantCard(
                  initialChant: chant,
                  teamName: teamNames[chant.teamId],
                )),
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

  const _LiveChantCard({required this.initialChant, this.teamName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(chantRepositoryProvider).chantStream(initialChant.id);

    return StreamBuilder<Chant?>(
      stream: stream,
      initialData: initialChant,
      builder: (context, snap) {
        final live = snap.data ?? initialChant;
        return ChantCard(
          chant: live,
          teamName: teamName,
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.chantDetail,
            arguments: live,
          ),
        );
      },
    );
  }
}
