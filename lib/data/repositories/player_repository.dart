import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/player.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore;

  PlayerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('players');

  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return teamBrowseStream(teamId: teamId).map((snapshot) => snapshot.players);
  }

  /// The full listed squad, retaining the metadata needed for absence claims.
  Stream<PlayerBrowseSnapshot> teamBrowseStream({required String teamId}) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => PlayerBrowseSnapshot(
            players: snap.docs.map(Player.fromFirestore),
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
          ),
        );
  }

  Future<Player?> getPlayer(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Player.fromFirestore(doc);
  }
}

class PlayerBrowseSnapshot {
  final List<Player> players;
  final bool isFromCache;
  final bool hasPendingWrites;

  PlayerBrowseSnapshot({
    required Iterable<Player> players,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  }) : players = List.unmodifiable(players);
}
