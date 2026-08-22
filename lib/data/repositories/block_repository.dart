import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/blocked_user.dart';

class BlockRepository {
  final FirebaseFirestore _firestore;

  BlockRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _firestore.collection('blocks');

  Stream<List<BlockedUser>> blockedUsersStream(String blockerId) {
    return _blocks.where('blockerId', isEqualTo: blockerId).snapshots().map((
      snapshot,
    ) {
      final users = snapshot.docs.map(BlockedUser.fromFirestore).toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String blockedDisplayName,
  }) async {
    final id = BlockedUser.documentId(blockerId, blockedUserId);
    await _blocks.doc(id).set({
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'blockedDisplayName': blockedDisplayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final id = BlockedUser.documentId(blockerId, blockedUserId);
    await _blocks.doc(id).delete();
  }
}
