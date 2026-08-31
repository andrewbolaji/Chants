import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/player.dart';

/// A prompt about this club's catalogue, not global or stadium-song absence.
/// Callers must first establish complete, current, server-confirmed snapshots.
List<Player> chantCallUpPlayers({
  required String teamId,
  required Iterable<Player> players,
  required Iterable<Chant> chants,
}) {
  final covered = {
    for (final chant in chants)
      if (chant.teamId == teamId && !chant.hidden && !chant.removed)
        chant.playerId,
  };
  final eligible = players
      .where(
        (player) =>
            player.teamId == teamId &&
            player.id.trim().isNotEmpty &&
            player.name.trim().isNotEmpty &&
            !covered.contains(player.id),
      )
      .toList();
  eligible.sort((a, b) {
    final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return name != 0 ? name : a.id.compareTo(b.id);
  });
  return eligible;
}
