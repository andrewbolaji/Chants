import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';

/// Provider that fetches all visible chants, shuffled, for discovery.
final discoveryProvider = FutureProvider<List<Chant>>((ref) {
  return ref.watch(chantRepositoryProvider).discoveryChants();
});

/// Provider that fetches all teams for name lookup.
final allTeamsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref
      .watch(teamRepositoryProvider)
      .teamsForCompetitionStream(competitionId: 'premier-league')
      .map((teams) => {for (final t in teams) t.id: t.name});
});

class DiscoverySection extends ConsumerWidget {
  const DiscoverySection({super.key});

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
            message: 'No chants to show yet. Check back soon.',
          );
        }
        final teamNames = teamsMap.valueOrNull ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Discover',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.shuffle, size: 20),
                    tooltip: 'Shuffle',
                    onPressed: () => ref.invalidate(discoveryProvider),
                  ),
                ],
              ),
            ),
            ...chants.take(20).map((chant) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChantCard(
                    chant: chant,
                    teamName: teamNames[chant.teamId],
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.chantDetail,
                      arguments: chant,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
