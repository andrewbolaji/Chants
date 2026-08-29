import 'package:cloud_firestore/cloud_firestore.dart';

enum PerformanceDraftState {
  awaitingUpload('awaiting_upload'),
  cleanupPending('cleanup_pending'),
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  final String firestoreValue;

  const PerformanceDraftState(this.firestoreValue);

  static PerformanceDraftState? fromFirestore(Object? value) {
    for (final state in values) {
      if (state.firestoreValue == value) return state;
    }
    return null;
  }
}

class PerformanceDraft {
  final String id;
  final String ownerId;
  final String chantId;
  final String chantTitle;
  final String teamName;
  final String? playerName;
  final String caption;
  final int durationMs;
  final PerformanceDraftState state;
  final String? moderationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PerformanceDraft({
    required this.id,
    required this.ownerId,
    required this.chantId,
    required this.chantTitle,
    required this.teamName,
    this.playerName,
    required this.caption,
    required this.durationMs,
    required this.state,
    this.moderationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PerformanceDraft.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final json = document.data();
    if (json == null || json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported performance draft.');
    }
    final state = PerformanceDraftState.fromFirestore(json['state']);
    if (state == null) {
      throw const FormatException('Unsupported performance draft state.');
    }
    return PerformanceDraft(
      id: document.id,
      ownerId: json['ownerId'] as String,
      chantId: json['chantId'] as String,
      chantTitle: json['chantTitle'] as String,
      teamName: json['teamName'] as String,
      playerName: json['playerName'] as String?,
      caption: json['caption'] as String,
      durationMs: json['claimedDurationMs'] as int,
      state: state,
      moderationReason: json['moderationReason'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }
}

class PerformanceDraftTicket {
  final String draftId;
  final String uploadPath;

  const PerformanceDraftTicket({
    required this.draftId,
    required this.uploadPath,
  });
}
