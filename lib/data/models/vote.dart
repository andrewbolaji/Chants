import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  final String id;
  final String chantId;
  final String userId;
  final int value;
  final DateTime createdAt;

  const Vote({
    required this.id,
    required this.chantId,
    required this.userId,
    required this.value,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json, {required String id}) {
    return Vote(
      id: id,
      chantId: json['chantId'] as String,
      userId: json['userId'] as String,
      value: json['value'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Vote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Vote.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'chantId': chantId,
      'userId': userId,
      'value': value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Generates the document ID for a vote: {userId}_{chantId}.
  /// This enforces one vote per user per chant at the document level.
  static String documentId(String userId, String chantId) {
    return '${userId}_$chantId';
  }
}
