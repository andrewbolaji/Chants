import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final String blockedDisplayName;
  final DateTime createdAt;

  const BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.blockedDisplayName,
    required this.createdAt,
  });

  static String documentId(String blockerId, String blockedUserId) {
    return '${blockerId}_$blockedUserId';
  }

  factory BlockedUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final createdAt = data['createdAt'];
    return BlockedUser(
      id: doc.id,
      blockerId: data['blockerId'] as String,
      blockedUserId: data['blockedUserId'] as String,
      blockedDisplayName: data['blockedDisplayName'] as String,
      createdAt:
          createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
