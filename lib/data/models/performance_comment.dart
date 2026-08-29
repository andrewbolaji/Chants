import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceComment {
  static const schemaVersion = 2;
  static const supportedSchemaVersions = [1, 2];

  final String id;
  final String performanceId;
  final String performanceCreatorId;
  final String userId;
  final String creatorHandle;
  final String creatorDisplayName;
  final String body;
  final String? parentCommentId;
  final String rootCommentId;
  final int depth;
  final List<String> mentionedHandles;
  final bool hidden;
  final bool removed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PerformanceComment({
    required this.id,
    required this.performanceId,
    required this.performanceCreatorId,
    required this.userId,
    required this.creatorHandle,
    required this.creatorDisplayName,
    required this.body,
    this.parentCommentId,
    String? rootCommentId,
    this.depth = 0,
    this.mentionedHandles = const [],
    required this.hidden,
    required this.removed,
    required this.createdAt,
    required this.updatedAt,
  }) : rootCommentId = rootCommentId ?? id;

  bool get isVisible => !hidden && !removed;
  bool get isReply => parentCommentId != null;
  int get displayDepth => depth.clamp(0, 2);

  factory PerformanceComment.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final version = json['schemaVersion'];
    if (!supportedSchemaVersions.contains(version)) {
      throw const FormatException('Unsupported performance comment schema.');
    }
    final parentCommentId = version == 2
        ? json['parentCommentId'] as String?
        : null;
    return PerformanceComment(
      id: id,
      performanceId: json['performanceId'] as String,
      performanceCreatorId: json['performanceCreatorId'] as String,
      userId: json['userId'] as String,
      creatorHandle: json['creatorHandle'] as String,
      creatorDisplayName: json['creatorDisplayName'] as String,
      body: json['body'] as String,
      parentCommentId: parentCommentId,
      rootCommentId: version == 2 ? json['rootCommentId'] as String : id,
      depth: version == 2 ? json['depth'] as int : 0,
      mentionedHandles: version == 2
          ? List<String>.unmodifiable(
              (json['mentionedHandles'] as List).whereType<String>(),
            )
          : const [],
      hidden: json['hidden'] as bool,
      removed: json['removed'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory PerformanceComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const FormatException('Performance comment is missing.');
    }
    return PerformanceComment.fromJson(data, id: document.id);
  }
}
