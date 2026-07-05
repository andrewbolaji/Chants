import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';

class PlayerScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final chantsStream = ref
        .watch(chantRepositoryProvider)
        .chantsForPlayerStream(playerId: player.id);
    final isSignedIn = ref.watch(authStateProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(title: Text(player.name.toUpperCase())),
      floatingActionButton:
          isSignedIn && sportId != null && competitionId != null
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRouter.submitChant,
                    arguments: {
                      'teamId': player.teamId,
                      'sportId': sportId,
                      'competitionId': competitionId,
                      'playerId': player.id,
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
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorState(
              message: 'Could not load chants. Pull down to try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chants = snapshot.data!;
          if (chants.isEmpty) {
            return EmptyState(
              message: 'No chants for ${player.name} yet.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: Spacing.sm,
              bottom: Spacing.xxxl * 2,
            ),
            itemCount: chants.length,
            itemBuilder: (context, index) {
              return ChantCard(
                chant: chants[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.chantDetail,
                  arguments: chants[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
