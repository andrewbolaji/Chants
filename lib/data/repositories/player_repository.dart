import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/player.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore;

  PlayerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('players');

  Stream<List<Player>> playersForTeamStream({required String teamId}) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snap) => snap.docs.map(Player.fromFirestore).toList());
  }

  Future<Player?> getPlayer(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Player.fromFirestore(doc);
  }
}
