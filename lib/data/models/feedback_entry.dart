import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  final String id;
  final String userId;
  final String category;
  final String message;
  final bool followUpOk;
  final bool resolved;
  final DateTime createdAt;

  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    required this.followUpOk,
    this.resolved = false,
    required this.createdAt,
  });

  static const validCategories = ['suggestion', 'bug', 'question', 'other'];
  static const maxMessageLength = 1000;

  factory FeedbackEntry.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return FeedbackEntry(
      id: id,
      userId: json['userId'] as String,
      category: json['category'] as String,
      message: json['message'] as String,
      followUpOk: json['followUpOk'] as bool,
      resolved: json['resolved'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory FeedbackEntry.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return FeedbackEntry.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category,
      'message': message,
      'followUpOk': followUpOk,
      'resolved': resolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
