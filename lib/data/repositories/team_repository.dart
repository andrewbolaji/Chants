import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/team.dart';

class TeamRepository {
  final FirebaseFirestore _firestore;

  TeamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('teams');

  Stream<List<Team>> teamsForCompetitionStream({
    required String competitionId,
  }) {
    return _collection
        .where('competitionId', isEqualTo: competitionId)
        .snapshots()
        .map((snap) => snap.docs.map(Team.fromFirestore).toList());
  }

  Future<Team?> getTeam(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc);
  }
}
