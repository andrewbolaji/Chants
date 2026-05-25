import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/error_state.dart';

class PlayerScreen extends ConsumerWidget {
  final Player player;
  const PlayerScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chantsStream = ref
        .watch(chantRepositoryProvider)
        .chantsForPlayerStream(playerId: player.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
      ),
      body: StreamBuilder<List<Chant>>(
        stream: chantsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
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
            padding: const EdgeInsets.all(8),
            itemCount: chants.length,
            itemBuilder: (context, index) {
              final chant = chants[index];
              return ChantCard(
                chant: chant,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.chantDetail,
                  arguments: chant,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
