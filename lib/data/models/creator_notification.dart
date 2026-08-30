import 'package:cloud_firestore/cloud_firestore.dart';

enum CreatorNotificationType {
  creatorFollow,
  performanceMention,
  performanceReply,
  chantPromoted,
}

class CreatorNotification {
  static const schemaVersion = 1;

  final String id;
  final String ownerId;
  final String actorId;
  final String actorHandle;
  final String actorDisplayName;
  final CreatorNotificationType type;
  final String? performanceId;
  final String? commentId;
  final String? chantId;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  const CreatorNotification({
    required this.id,
    required this.ownerId,
    required this.actorId,
    required this.actorHandle,
    required this.actorDisplayName,
    required this.type,
    required this.performanceId,
    required this.commentId,
    this.chantId,
    required this.read,
    required this.createdAt,
    required this.readAt,
  });

  factory CreatorNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final json = document.data();
    if (json == null || json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported creator notification.');
    }
    final type = switch (json['type']) {
      'creator_follow' => CreatorNotificationType.creatorFollow,
      'performance_mention' => CreatorNotificationType.performanceMention,
      'performance_reply' => CreatorNotificationType.performanceReply,
      'chant_promoted' => CreatorNotificationType.chantPromoted,
      _ => throw const FormatException(
        'Unsupported creator notification type.',
      ),
    };
    return CreatorNotification(
      id: document.id,
      ownerId: json['ownerId'] as String,
      actorId: json['actorId'] as String,
      actorHandle: json['actorHandle'] as String,
      actorDisplayName: json['actorDisplayName'] as String,
      type: type,
      performanceId: json['performanceId'] as String?,
      commentId: json['commentId'] as String?,
      chantId: json['chantId'] as String?,
      read: json['read'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      readAt: (json['readAt'] as Timestamp?)?.toDate(),
    );
  }
}
