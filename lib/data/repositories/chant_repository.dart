import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/chant.dart';

class ChantRepository {
  final FirebaseFirestore _firestore;

  ChantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('chants');

  /// Returns visible chants for a team, ordered by score descending.
  /// Per DECISIONS note: queries MUST include hidden == false and
  /// removed == false filters, or Firestore security rules will reject.
  Stream<List<Chant>> chantsForTeamStream({required String teamId}) {
    return _collection
        .where('teamId', isEqualTo: teamId)
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Chant.fromFirestore).toList());
  }

  Future<Chant?> getChant(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Chant.fromFirestore(doc);
  }

  Future<DocumentReference> createChant(Chant chant) async {
    return _collection.add(chant.toJson());
  }

  Future<void> updateChantContent({
    required String chantId,
    required Map<String, dynamic> fields,
  }) async {
    await _collection.doc(chantId).update(fields);
  }
}
