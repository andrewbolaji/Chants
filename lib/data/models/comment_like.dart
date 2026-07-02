import 'package:cloud_firestore/cloud_firestore.dart';

class CommentLike {
  final String id;
  final String commentId;
  final String userId;
  final int value; // Always 1. Exists so the CF can recompute from ground truth.
  final DateTime createdAt;

  /// Set by the Cloud Function after recomputing likeCount. The client reads
  /// this on cold load to know whether the comment's likeCount already
  /// includes this like (appliedValue == 1) or not (appliedValue absent).
  /// Never written by the client.
  final int? appliedValue;

  const CommentLike({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.value,
    required this.createdAt,
    this.appliedValue,
  });

  factory CommentLike.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return CommentLike(
      id: id,
      commentId: json['commentId'] as String,
      userId: json['userId'] as String,
      value: json['value'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      appliedValue: json['appliedValue'] as int?,
    );
  }

  factory CommentLike.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CommentLike.fromJson(doc.data()!, id: doc.id);
  }

  /// Client-side toJson omits appliedValue (CF-only field).
  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userId': userId,
      'value': value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Deterministic doc ID: {userId}_{commentId}.
  /// Enforces one like per user per comment at the document level.
  static String documentId(String userId, String commentId) {
    return '${userId}_$commentId';
  }
}
