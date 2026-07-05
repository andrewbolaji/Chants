import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/services/chant_ranking.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  const TeamScreen({super.key, required this.team});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  bool _showFullSquad = false;

  /// Frozen order: list of chant IDs for club chants, captured once.
  List<String>? _frozenClubOrder;

  /// Frozen order: map of player ID to list of chant IDs, captured once.
  Map<String, List<String>>? _frozenPlayerOrder;

  /// Frozen player display order (players with chants), captured once.
  List<String>? _frozenPlayerListOrder;

  void _captureOrder(List<Chant> allChants, List<Player> allPlayers) {
    if (_frozenClubOrder != null) return; // already captured

    final clubChants = allChants.where((c) => c.playerId == null).toList();
    final playerChantMap = <String, List<Chant>>{};
    for (final c in allChants.where((c) => c.playerId != null)) {
      playerChantMap.putIfAbsent(c.playerId!, () => []).add(c);
    }

    _frozenClubOrder = rankChants(clubChants).map((c) => c.id).toList();

    final frozenPlayerOrder = <String, List<String>>{};
    for (final entry in playerChantMap.entries) {
      frozenPlayerOrder[entry.key] =
          rankChants(entry.value).map((c) => c.id).toList();
    }
    _frozenPlayerOrder = frozenPlayerOrder;

    _frozenPlayerListOrder = allPlayers
        .where((p) => playerChantMap.containsKey(p.id))
        .map((p) => p.id)
        .toList();
  }

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
      appBar: AppBar(title: Text(widget.team.name.toUpperCase())),
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
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'ADD A CHANT',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
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

              // Capture order once per visit; subsequent stream emissions
              // update card content but not position.
              _captureOrder(allChants, allPlayers);

              // Build a lookup for live chant data by ID.
              final chantById = <String, Chant>{
                for (final c in allChants) c.id: c,
              };
              final playerById = <String, Player>{
                for (final p in allPlayers) p.id: p,
              };

              // Filter frozen order to only IDs still present in the
              // live data (handles removals/hides mid-visit).
              final clubIds = _frozenClubOrder!
                  .where((id) => chantById.containsKey(id))
                  .toList();
              final playerListIds = _frozenPlayerListOrder!
                  .where((id) => playerById.containsKey(id))
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
                  if (clubIds.isNotEmpty) ...[
                    _SectionHeader(title: 'Club chants'),
                    ...clubIds.map((id) => ChantCard(
                          chant: chantById[id]!,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.chantDetail,
                            arguments: chantById[id]!,
                          ),
                        )),
                  ],

                  // Players with chants
                  if (playerListIds.isNotEmpty) ...[
                    const SizedBox(height: Spacing.lg),
                    _SectionHeader(title: 'Player chants'),
                    ...playerListIds.expand((playerId) {
                      final player = playerById[playerId]!;
                      final chantIds = (_frozenPlayerOrder![playerId] ?? [])
                          .where((id) => chantById.containsKey(id))
                          .toList();
                      return [
                        ListTile(
                          title:
                              Text(player.name, style: textTheme.titleSmall),
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
                        ...chantIds.map((id) => ChantCard(
                              chant: chantById[id]!,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.chantDetail,
                                arguments: chantById[id]!,
                              ),
                            )),
                      ];
                    }),
                  ],

                  if (allChants.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: Spacing.xl),
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
                                color: AppColors.textHeadline,
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
      child: SectionEyebrow(text: title),
    );
  }
}
