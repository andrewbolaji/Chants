import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/services/chant_browse.dart';
import 'package:chants/presentation/browse/browse_supporting_notice.dart';
import 'package:chants/presentation/browse/chant_lab_view.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamScreen extends ConsumerStatefulWidget {
  final Team team;
  final DateTime? risingEvaluationTime;

  const TeamScreen({super.key, required this.team, this.risingEvaluationTime});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final StreamSubscription<ChantBrowseSnapshot> _chantSubscription;
  late final StreamSubscription<List<Player>> _playerSubscription;
  final StableChantOrder _songbookOrder = StableChantOrder();
  ChantBrowseSnapshot? _browseSnapshot;
  Object? _chantError;
  List<Player>? _players;
  Object? _playerError;
  bool _showFullSquad = false;
  bool _savingMatchdayCopy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chantSubscription = ref
        .read(chantRepositoryProvider)
        .teamBrowseStream(teamId: widget.team.id)
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() {
              _browseSnapshot = snapshot;
              _chantError = null;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) return;
            setState(() => _chantError = error);
          },
        );
    _playerSubscription = ref
        .read(playerRepositoryProvider)
        .playersForTeamStream(teamId: widget.team.id)
        .listen(
          (players) {
            if (!mounted) return;
            setState(() {
              _players = List.unmodifiable(players);
              _playerError = null;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!mounted) return;
            setState(() => _playerError = error);
          },
        );
  }

  @override
  void dispose() {
    _chantSubscription.cancel();
    _playerSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startChant() {
    Navigator.pushNamed(
      context,
      AppRouter.submitChant,
      arguments: {
        'teamId': widget.team.id,
        'sportId': widget.team.sportId,
        'competitionId': widget.team.competitionId,
        'playerId': null,
      },
    );
  }

  void _openChant(Chant chant) {
    Navigator.pushNamed(
      context,
      AppRouter.chantDetail,
      arguments: ChantDetailRouteArguments(chant: chant, team: widget.team),
    );
  }

  void _openPlayer(Player player) {
    Navigator.pushNamed(
      context,
      AppRouter.player,
      arguments: {
        'player': player,
        'sportId': widget.team.sportId,
        'competitionId': widget.team.competitionId,
      },
    );
  }

  Future<void> _saveForMatchday({
    required String uid,
    required List<Chant> chants,
    required bool isRefresh,
  }) async {
    if (_savingMatchdayCopy) return;
    setState(() => _savingMatchdayCopy = true);
    try {
      final result = await ref
          .read(savedSongbookServiceProvider)
          .saveClubFromFreshBrowse(
            uid: uid,
            team: widget.team,
            songbookChants: chants,
          );
      ref.invalidate(savedSongbookProvider(uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRefresh
                ? 'Saved copy refreshed with ${result.chantCount} chants.'
                : '${result.chantCount} chants saved for matchday.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRefresh
                ? 'Could not refresh. Your saved copy is still available.'
                : 'Could not save a fresh copy. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingMatchdayCopy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isSignedIn = user != null;
    final savedSongbook = user == null
        ? null
        : ref.watch(savedSongbookProvider(user.uid)).valueOrNull;
    final browseSnapshot = _browseSnapshot;

    late final Widget body;
    if (browseSnapshot == null) {
      body = _chantError == null
          ? const Center(child: CircularProgressIndicator())
          : const ErrorState(
              message: 'Could not load chants. Go back and try again.',
            );
    } else {
      final projection = projectChants(browseSnapshot.chants);
      final songbook = _songbookOrder.reconcile(
        rankBrowseTop(projection.songbook),
      );
      final players = _players ?? const <Player>[];
      final savedClub = savedSongbook?.clubSnapshots[widget.team.id];
      final canSaveForMatchday =
          user != null &&
          !_savingMatchdayCopy &&
          !browseSnapshot.isFromCache &&
          _chantError == null &&
          songbook.isNotEmpty;
      final playerNames = {
        for (final player in players) player.id: player.name,
      };

      body = TabBarView(
        controller: _tabController,
        children: [
          _TeamSongbookView(
            chants: songbook,
            players: players,
            playerLoading: _players == null && _playerError == null,
            playerHasError: _playerError != null,
            isFromCache: browseSnapshot.isFromCache,
            hasRecoverableError: _chantError != null,
            showMatchdaySave: user != null,
            savedRefreshedAt: savedClub?.refreshedAt,
            savingMatchdayCopy: _savingMatchdayCopy,
            canSaveForMatchday: canSaveForMatchday,
            onSaveForMatchday: canSaveForMatchday
                ? () => _saveForMatchday(
                    uid: user.uid,
                    chants: songbook,
                    isRefresh: savedClub != null,
                  )
                : null,
            showFullSquad: _showFullSquad,
            onToggleFullSquad: () =>
                setState(() => _showFullSquad = !_showFullSquad),
            onOpenChantLab: () => _tabController.animateTo(1),
            onOpenChant: _openChant,
            onOpenPlayer: _openPlayer,
          ),
          ChantLabView(
            chants: projection.chantLab,
            playerNames: playerNames,
            isFromCache: browseSnapshot.isFromCache,
            hasRecoverableError: _chantError != null,
            canStartChant: isSignedIn,
            emptyMessage:
                'Be the first fan to start an idea for ${widget.team.name}.',
            signedOutEmptyMessage:
                'No ideas yet. Sign in to start the first chant for ${widget.team.name}.',
            now: widget.risingEvaluationTime ?? DateTime.now(),
            onChantTap: _openChant,
            onStartChant: _startChant,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name.toUpperCase()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SONGBOOK'),
            Tab(text: 'CHANT LAB'),
          ],
        ),
      ),
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: _startChant,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'START A CHANT',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            )
          : null,
      body: body,
    );
  }
}

class _TeamSongbookView extends StatelessWidget {
  final List<Chant> chants;
  final List<Player> players;
  final bool playerLoading;
  final bool playerHasError;
  final bool isFromCache;
  final bool hasRecoverableError;
  final bool showMatchdaySave;
  final DateTime? savedRefreshedAt;
  final bool savingMatchdayCopy;
  final bool canSaveForMatchday;
  final VoidCallback? onSaveForMatchday;
  final bool showFullSquad;
  final VoidCallback onToggleFullSquad;
  final VoidCallback onOpenChantLab;
  final ValueChanged<Chant> onOpenChant;
  final ValueChanged<Player> onOpenPlayer;

  const _TeamSongbookView({
    required this.chants,
    required this.players,
    required this.playerLoading,
    required this.playerHasError,
    required this.isFromCache,
    required this.hasRecoverableError,
    required this.showMatchdaySave,
    required this.savedRefreshedAt,
    required this.savingMatchdayCopy,
    required this.canSaveForMatchday,
    required this.onSaveForMatchday,
    required this.showFullSquad,
    required this.onToggleFullSquad,
    required this.onOpenChantLab,
    required this.onOpenChant,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final playerById = {for (final player in players) player.id: player};
    final clubChants = chants.where((chant) => chant.playerId == null).toList();
    final playerChants = chants
        .where((chant) => chant.playerId != null)
        .toList();
    final chantsByPlayer = <String, List<Chant>>{};
    for (final chant in playerChants) {
      chantsByPlayer.putIfAbsent(chant.playerId!, () => []).add(chant);
    }

    final orderedKnownPlayerIds = [
      for (final player in players)
        if (chantsByPlayer.containsKey(player.id)) player.id,
    ];
    final unresolvedPlayerIds = <String>{
      for (final chant in playerChants)
        if (!playerById.containsKey(chant.playerId) &&
            !orderedKnownPlayerIds.contains(chant.playerId))
          chant.playerId!,
    };

    final items = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.xs,
        ),
        child: SectionEyebrow(text: 'Terrace Proven', gold: true),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Text(
          'Sourced or operator-reviewed chants live in the Songbook.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ),
      if (showMatchdaySave)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.lg,
            Spacing.sm,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_outlined,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'TAKE THIS SONGBOOK TO THE GROUND',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  savedRefreshedAt == null
                      ? 'Save the current Terrace Proven set on this device.'
                      : 'Last refreshed ${_matchdayDate(savedRefreshedAt!)}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!canSaveForMatchday && !savingMatchdayCopy) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    isFromCache
                        ? 'Connect for a fresh copy before saving.'
                        : hasRecoverableError
                        ? 'Fresh chants are unavailable right now.'
                        : chants.isEmpty
                        ? 'There are no Terrace Proven chants to save yet.'
                        : 'Preparing the latest copy.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSaveForMatchday,
                    icon: savingMatchdayCopy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            savedRefreshedAt == null
                                ? Icons.download_outlined
                                : Icons.refresh,
                          ),
                    label: Text(
                      savedRefreshedAt == null
                          ? 'SAVE FOR MATCHDAY'
                          : 'REFRESH SAVED COPY',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (isFromCache)
        const BrowseSupportingNotice(
          label: 'DEVICE CACHE',
          message: 'These chants are from this device while Chants reconnects.',
          icon: Icons.offline_pin_outlined,
        ),
      if (hasRecoverableError)
        const BrowseSupportingNotice(
          label: 'LAST LOADED CHANTS',
          message:
              'Fresh updates are unavailable. You can still open these chants.',
          icon: Icons.sync_problem_outlined,
        ),
    ];

    if (chants.isEmpty) {
      items.add(
        EmptyState(
          headline: 'SONGBOOK IS QUIET',
          message:
              'No Terrace Proven chants yet. Chant Lab is where new ideas begin.',
          icon: Icons.library_music_outlined,
          onAction: onOpenChantLab,
          actionLabel: 'EXPLORE CHANT LAB',
        ),
      );
    } else {
      if (clubChants.isNotEmpty) {
        items.add(const _SectionHeader(title: 'Club chants'));
        items.addAll(
          clubChants.map(
            (chant) => ChantCard(
              key: ValueKey('songbook-${chant.id}'),
              chant: chant,
              onTap: () => onOpenChant(chant),
            ),
          ),
        );
      }

      if (playerChants.isNotEmpty) {
        items.add(const SizedBox(height: Spacing.lg));
        items.add(const _SectionHeader(title: 'Player chants'));
        for (final playerId in orderedKnownPlayerIds) {
          final player = playerById[playerId]!;
          items.add(
            ListTile(
              title: Text(
                player.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textFaint,
              ),
              onTap: () => onOpenPlayer(player),
            ),
          );
          items.addAll(
            chantsByPlayer[playerId]!.map(
              (chant) => ChantCard(
                key: ValueKey('songbook-${chant.id}'),
                chant: chant,
                onTap: () => onOpenChant(chant),
              ),
            ),
          );
        }
        for (final playerId in unresolvedPlayerIds) {
          items.addAll(
            chantsByPlayer[playerId]!.map(
              (chant) => ChantCard(
                key: ValueKey('songbook-${chant.id}'),
                chant: chant,
                onTap: () => onOpenChant(chant),
              ),
            ),
          );
        }
      }
    }

    if (playerLoading) {
      items.add(
        const BrowseSupportingNotice(
          label: 'SQUAD LOADING',
          message: 'Player names and the full squad will appear shortly.',
          icon: Icons.groups_outlined,
        ),
      );
    } else if (playerHasError) {
      items.add(
        const BrowseSupportingNotice(
          label: 'SQUAD UNAVAILABLE',
          message: 'Chants are still here, but player details could not load.',
          icon: Icons.groups_outlined,
        ),
      );
    } else if (players.isNotEmpty) {
      items.add(const SizedBox(height: Spacing.lg));
      items.add(const Divider(indent: Spacing.lg, endIndent: Spacing.lg));
      items.add(
        InkWell(
          onTap: onToggleFullSquad,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              children: [
                Text(
                  'Full squad (${players.length})',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                Icon(
                  showFullSquad ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
      if (showFullSquad) {
        items.addAll(
          players.map(
            (player) => ListTile(
              title: Text(
                player.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textHeadline),
              ),
              dense: true,
              onTap: () => onOpenPlayer(player),
            ),
          ),
        );
      }
    }

    return ListView.builder(
      key: const PageStorageKey('team-songbook-list'),
      padding: const EdgeInsets.only(bottom: Spacing.xxxl * 2),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

String _matchdayDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
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
