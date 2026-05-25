import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  bool _showFullSquad = false;

  @override
  Widget build(BuildContext context) {
    final chantsStream = ref
        .watch(chantRepositoryProvider)
        .chantsForTeamStream(teamId: widget.team.id);
    final playersStream = ref
        .watch(playerRepositoryProvider)
        .playersForTeamStream(teamId: widget.team.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.team.name)),
      body: StreamBuilder<List<Chant>>(
        stream: chantsStream,
        builder: (context, chantSnap) {
          return StreamBuilder<List<Player>>(
            stream: playersStream,
            builder: (context, playerSnap) {
              if (chantSnap.hasError || playerSnap.hasError) {
                return ErrorState(
                  message:
                      'Could not load chants. Pull down to try again.',
                );
              }
              if (!chantSnap.hasData || !playerSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allChants = chantSnap.data!;
              final allPlayers = playerSnap.data!;

              // Partition chants
              final clubChants = allChants
                  .where((c) => c.playerId == null)
                  .toList();
              final playerChantMap = <String, List<Chant>>{};
              for (final c in allChants.where((c) => c.playerId != null)) {
                playerChantMap
                    .putIfAbsent(c.playerId!, () => [])
                    .add(c);
              }

              // Players with chants
              final playersWithChants = allPlayers
                  .where((p) => playerChantMap.containsKey(p.id))
                  .toList();
              if (allChants.isEmpty && allPlayers.isEmpty) {
                return EmptyState(
                  message:
                      'No chants for ${widget.team.name} yet. They are on the way.',
                );
              }

              return ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Club chants
                  if (clubChants.isNotEmpty) ...[
                    _SectionHeader(title: 'Club chants'),
                    ...clubChants.map((c) => ChantCard(
                          chant: c,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.chantDetail,
                            arguments: c,
                          ),
                        )),
                  ],

                  // Players with chants
                  if (playersWithChants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'Player chants'),
                    ...playersWithChants.expand((player) => [
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(player.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.player,
                              arguments: player,
                            ),
                          ),
                          ...playerChantMap[player.id]!.map((c) => Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: ChantCard(
                                  chant: c,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRouter.chantDetail,
                                    arguments: c,
                                  ),
                                ),
                              )),
                        ]),
                  ],

                  // Empty chants message
                  if (allChants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        message:
                            'No chants for ${widget.team.name} yet. They are on the way.',
                      ),
                    ),

                  // Full squad (collapsible)
                  if (allPlayers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () =>
                          setState(() => _showFullSquad = !_showFullSquad),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Full squad (${allPlayers.length})',
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Icon(_showFullSquad
                                ? Icons.expand_less
                                : Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    if (_showFullSquad)
                      ...allPlayers.map((player) => ListTile(
                            leading: const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person_outline, size: 18),
                            ),
                            title: Text(player.name),
                            dense: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.player,
                              arguments: player,
                            ),
                          )),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
