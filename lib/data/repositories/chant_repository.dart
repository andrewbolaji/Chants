import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_ranking.dart';

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

  /// Visible team browse data plus Firestore cache provenance.
  /// Uses composite index: teamId + hidden + removed + score desc.
  Stream<ChantBrowseSnapshot> teamBrowseStream({required String teamId}) {
    return _visibleChants()
        .where('teamId', isEqualTo: teamId)
        .orderBy('score', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => ChantBrowseSnapshot(
            chants: rankChants(snap.docs.map(Chant.fromFirestore).toList()),
            isFromCache: snap.metadata.isFromCache,
          ),
        );
  }

  /// Compatibility stream for callers that do not need cache provenance.
  Stream<List<Chant>> chantsForTeamStream({required String teamId}) {
    return teamBrowseStream(teamId: teamId).map((snapshot) => snapshot.chants);
  }

  /// One-shot visible team set used only by the advisory duplicate nudge.
  /// Subject filtering stays client-side so this reuses the existing query
  /// shape and does not add another composite index.
  Future<List<Chant>> visibleChantsForTeamOnce({required String teamId}) async {
    final snap = await _visibleChants()
        .where('teamId', isEqualTo: teamId)
        .orderBy('score', descending: true)
        .get();
    return snap.docs.map(Chant.fromFirestore).toList();
  }

  /// Visible player browse data plus Firestore cache provenance.
  Stream<ChantBrowseSnapshot> playerBrowseStream({required String playerId}) {
    return _visibleChants()
        .where('playerId', isEqualTo: playerId)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => ChantBrowseSnapshot(
            chants: rankChants(snap.docs.map(Chant.fromFirestore).toList()),
            isFromCache: snap.metadata.isFromCache,
          ),
        );
  }

  /// Compatibility stream for callers that do not need cache provenance.
  Stream<List<Chant>> chantsForPlayerStream({required String playerId}) {
    return playerBrowseStream(
      playerId: playerId,
    ).map((snapshot) => snapshot.chants);
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

  /// Live single-doc stream for the chant detail screen.
  /// Emits the current chant and re-emits on any field change (score,
  /// hidden, etc.), so VoteControls.didUpdateWidget can reconcile.
  Stream<Chant?> chantStream(String id) {
    return _collection
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Chant.fromFirestore(doc) : null);
  }

  Future<void> createChant(Chant chant) async {
    await _collection.add(chant.toJson());
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
        .map(
          (snap) => snap.docs
              .map(Chant.fromFirestore)
              .where((c) => c.score >= promotionThreshold)
              .toList(),
        );
  }
}

class ChantBrowseSnapshot {
  final List<Chant> chants;
  final bool isFromCache;

  ChantBrowseSnapshot({
    required Iterable<Chant> chants,
    this.isFromCache = false,
  }) : chants = List.unmodifiable(chants);
}
