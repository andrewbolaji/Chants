import 'dart:async';

import 'package:chants/app/colors.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
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

class PlayerScreen extends ConsumerStatefulWidget {
  final Player player;
  final String? sportId;
  final String? competitionId;

  const PlayerScreen({
    super.key,
    required this.player,
    this.sportId,
    this.competitionId,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final StreamSubscription<ChantBrowseSnapshot> _chantSubscription;
  final StableChantOrder _songbookOrder = StableChantOrder();
  ChantBrowseSnapshot? _browseSnapshot;
  Object? _chantError;

  bool get _canStartChant =>
      ref.watch(authStateProvider).valueOrNull != null &&
      widget.sportId != null &&
      widget.competitionId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chantSubscription = ref
        .read(chantRepositoryProvider)
        .playerBrowseStream(playerId: widget.player.id)
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
  }

  @override
  void dispose() {
    _chantSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startChant() {
    Navigator.pushNamed(
      context,
      AppRouter.submitChant,
      arguments: {
        'teamId': widget.player.teamId,
        'sportId': widget.sportId,
        'competitionId': widget.competitionId,
        'playerId': widget.player.id,
      },
    );
  }

  void _openChant(Chant chant) {
    Navigator.pushNamed(
      context,
      AppRouter.chantDetail,
      arguments: ChantDetailRouteArguments(chant: chant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStartChant = _canStartChant;
    final browseSnapshot = _browseSnapshot;

    late final Widget body;
    if (browseSnapshot == null) {
      body = _chantError == null
          ? const Center(child: CircularProgressIndicator())
          : const ErrorState(
              message: 'Could not load chants. Pull down to try again.',
            );
    } else {
      final projection = projectChants(browseSnapshot.chants);
      final songbook = _songbookOrder.reconcile(
        rankBrowseTop(projection.songbook),
      );

      body = TabBarView(
        controller: _tabController,
        children: [
          _PlayerSongbookView(
            chants: songbook,
            playerName: widget.player.name,
            isFromCache: browseSnapshot.isFromCache,
            hasRecoverableError: _chantError != null,
            onOpenChantLab: () => _tabController.animateTo(1),
            onOpenChant: _openChant,
          ),
          ChantLabView(
            chants: projection.chantLab,
            isFromCache: browseSnapshot.isFromCache,
            hasRecoverableError: _chantError != null,
            canStartChant: canStartChant,
            emptyMessage:
                'Start the first chant idea for ${widget.player.name}.',
            signedOutEmptyMessage:
                'No ideas yet. Sign in to start a chant for ${widget.player.name}.',
            now: DateTime.now(),
            onChantTap: _openChant,
            onStartChant: canStartChant ? _startChant : null,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.player.name.toUpperCase()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SONGBOOK'),
            Tab(text: 'CHANT LAB'),
          ],
        ),
      ),
      floatingActionButton: canStartChant
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

class _PlayerSongbookView extends StatelessWidget {
  final List<Chant> chants;
  final String playerName;
  final bool isFromCache;
  final bool hasRecoverableError;
  final VoidCallback onOpenChantLab;
  final ValueChanged<Chant> onOpenChant;

  const _PlayerSongbookView({
    required this.chants,
    required this.playerName,
    required this.isFromCache,
    required this.hasRecoverableError,
    required this.onOpenChantLab,
    required this.onOpenChant,
  });

  @override
  Widget build(BuildContext context) {
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
          headline: 'NO SONGBOOK CHANT YET',
          message:
              'Nothing for $playerName has reached the Songbook yet. New ideas begin in Chant Lab.',
          icon: Icons.library_music_outlined,
          onAction: onOpenChantLab,
          actionLabel: 'EXPLORE CHANT LAB',
        ),
      );
    } else {
      items.addAll(
        chants.map(
          (chant) => ChantCard(
            key: ValueKey('songbook-${chant.id}'),
            chant: chant,
            onTap: () => onOpenChant(chant),
          ),
        ),
      );
    }

    return ListView.builder(
      key: const PageStorageKey('player-songbook-list'),
      padding: const EdgeInsets.only(bottom: Spacing.xxxl * 2),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}
