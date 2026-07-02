import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String chantId;
  final String userId;
  final String displayName;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final int flagCount;
  final bool hidden;
  final bool removed;

  const Comment({
    required this.id,
    required this.chantId,
    required this.userId,
    required this.displayName,
    required this.body,
    required this.createdAt,
    this.likeCount = 0,
    this.flagCount = 0,
    this.hidden = false,
    this.removed = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json, {required String id}) {
    return Comment(
      id: id,
      chantId: json['chantId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      body: json['body'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      likeCount: json['likeCount'] as int? ?? 0,
      flagCount: json['flagCount'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
    );
  }

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Comment.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'chantId': chantId,
      'userId': userId,
      'displayName': displayName,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'flagCount': flagCount,
      'hidden': hidden,
      'removed': removed,
    };
  }
}
