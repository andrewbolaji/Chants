import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/chant.dart';

class ChantRepository {
  final FirebaseFirestore _firestore;

  ChantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('chants');

  /// Base query: every chant query MUST include these filters.
  /// Firestore security rules reject queries that could return
  /// hidden or removed docs. This is the enforcement point.
  Query<Map<String, dynamic>> _visibleChants() {
    return _collection
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false);
  }

  /// All visible chants for a team, ordered by score (most popular first).
  /// Uses composite index: teamId + hidden + removed + score desc.
  Stream<List<Chant>> chantsForTeamStream({required String teamId}) {
    return _visibleChants()
        .where('teamId', isEqualTo: teamId)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Chant.fromFirestore).toList());
  }

  /// All visible chants for a player. Sorted client-side.
  Stream<List<Chant>> chantsForPlayerStream({required String playerId}) {
    return _visibleChants()
        .where('playerId', isEqualTo: playerId)
        .snapshots()
        .map((snap) {
      final chants = snap.docs.map(Chant.fromFirestore).toList();
      chants.sort((a, b) => b.score.compareTo(a.score));
      return chants;
    });
  }

  /// All visible chants for the discovery shuffle (Fix B).
  /// Fetches all visible chants with no orderBy and no limit.
  /// Client shuffles for a true cross-club mix.
  /// v2 trigger: paginate or add a random field when volume
  /// outgrows a single fetch.
  Future<List<Chant>> discoveryChants() async {
    final snap = await _visibleChants().get();
    final chants = snap.docs.map(Chant.fromFirestore).toList();
    chants.shuffle();
    return chants;
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

  /// Promotion candidates: community chants with score >= threshold.
  /// Uses composite index: status + hidden + removed + score desc.
  static const promotionThreshold = 10;

  Stream<List<Chant>> promotionCandidatesStream() {
    return _collection
        .where('status', isEqualTo: 'community')
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(Chant.fromFirestore)
            .where((c) => c.score >= promotionThreshold)
            .toList());
  }
}
