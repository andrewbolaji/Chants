import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
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
    final isSignedIn = ref.watch(authStateProvider).valueOrNull != null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.team.name)),
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRouter.submitChant,
                arguments: {
                  'teamId': widget.team.id,
                  'sportId': widget.team.sportId,
                  'competitionId': widget.team.competitionId,
                  'playerId': null,
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add a chant'),
            )
          : null,
      body: StreamBuilder<List<Chant>>(
        stream: chantsStream,
        builder: (context, chantSnap) {
          return StreamBuilder<List<Player>>(
            stream: playersStream,
            builder: (context, playerSnap) {
              if (chantSnap.hasError || playerSnap.hasError) {
                return const ErrorState(
                  message: 'Could not load chants. Pull down to try again.',
                );
              }
              if (!chantSnap.hasData || !playerSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allChants = chantSnap.data!;
              final allPlayers = playerSnap.data!;

              final clubChants =
                  allChants.where((c) => c.playerId == null).toList();
              final playerChantMap = <String, List<Chant>>{};
              for (final c
                  in allChants.where((c) => c.playerId != null)) {
                playerChantMap
                    .putIfAbsent(c.playerId!, () => [])
                    .add(c);
              }
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
                padding: const EdgeInsets.only(
                  top: Spacing.sm,
                  bottom: Spacing.xxxl * 2,
                ),
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
                    const SizedBox(height: Spacing.lg),
                    _SectionHeader(title: 'Player chants'),
                    ...playersWithChants.expand((player) => [
                          ListTile(
                            title: Text(player.name, style: textTheme.titleSmall),
                            trailing: Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.textFaint,
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.player,
                              arguments: {
                                'player': player,
                                'sportId': widget.team.sportId,
                                'competitionId': widget.team.competitionId,
                              },
                            ),
                          ),
                          ...playerChantMap[player.id]!.map(
                              (c) => ChantCard(
                                    chant: c,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.chantDetail,
                                      arguments: c,
                                    ),
                                  )),
                        ]),
                  ],

                  if (allChants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                      child: EmptyState(
                        message:
                            'No chants for ${widget.team.name} yet. They are on the way.',
                      ),
                    ),

                  // Full squad (collapsible)
                  if (allPlayers.isNotEmpty) ...[
                    const SizedBox(height: Spacing.lg),
                    const Divider(indent: Spacing.lg, endIndent: Spacing.lg),
                    InkWell(
                      onTap: () =>
                          setState(() => _showFullSquad = !_showFullSquad),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Full squad (${allPlayers.length})',
                              style: textTheme.labelMedium,
                            ),
                            const Spacer(),
                            Icon(
                              _showFullSquad
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showFullSquad)
                      ...allPlayers.map((player) => ListTile(
                            title: Text(
                              player.name,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            dense: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.player,
                              arguments: {
                                'player': player,
                                'sportId': widget.team.sportId,
                                'competitionId': widget.team.competitionId,
                              },
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
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}
