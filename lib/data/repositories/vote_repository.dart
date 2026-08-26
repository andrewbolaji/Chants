import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/vote.dart';

class VoteRepository {
  final FirebaseFirestore _firestore;

  VoteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('votes');

  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async {
    final docId = Vote.documentId(userId, chantId);
    final doc = await _collection.doc(docId).get();
    if (!doc.exists) return null;
    return Vote.fromFirestore(doc);
  }

  Future<void> castVote({
    required String userId,
    required String chantId,
    required int value,
  }) async {
    final docId = Vote.documentId(userId, chantId);
    final vote = Vote(
      id: docId,
      chantId: chantId,
      userId: userId,
      value: value,
      createdAt: DateTime.now(),
    );
    final reference = _collection.doc(docId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        transaction.update(reference, {'value': value});
      } else {
        transaction.set(reference, vote.toJson());
      }
    });
  }

  Future<void> removeVote({
    required String userId,
    required String chantId,
  }) async {
    final docId = Vote.documentId(userId, chantId);
    await _collection.doc(docId).delete();
  }
}
