import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/competition.dart';

class CompetitionRepository {
  final FirebaseFirestore _firestore;

  CompetitionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('competitions');

  Stream<List<Competition>> enabledCompetitionsStream({
    required String sportId,
  }) {
    return _collection
        .where('sportId', isEqualTo: sportId)
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Competition.fromFirestore).toList());
  }

  Future<Competition?> getCompetition(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Competition.fromFirestore(doc);
  }
}
