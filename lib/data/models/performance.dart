import 'package:cloud_firestore/cloud_firestore.dart';

enum PerformancePublicationState {
  approved('approved');

  final String firestoreValue;

  const PerformancePublicationState(this.firestoreValue);

  static PerformancePublicationState? fromFirestoreValue(Object? value) {
    for (final state in values) {
      if (state.firestoreValue == value) return state;
    }
    return null;
  }
}

class Performance {
  static const schemaVersion = 1;

  final String id;
  final String chantId;
  final String chantTitle;
  final String teamId;
  final String teamName;
  final String? playerName;
  final String chantStatus;
  final String creatorId;
  final String creatorHandle;
  final String creatorDisplayName;
  final String caption;
  final String mediaPath;
  final int durationMs;
  final PerformancePublicationState publicationState;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int uniqueSharerCount;
  final int weeklyUniqueSharerCount;
  final int weeklyLikeCount;
  final int weeklyQualifiedViewCount;
  final String rankingWeek;
  final bool hidden;
  final bool removed;
  final bool sourceChantVisible;
  final bool sourceCreatorVisible;
  final DateTime createdAt;
  final DateTime approvedAt;
  final DateTime updatedAt;

  const Performance({
    required this.id,
    required this.chantId,
    required this.chantTitle,
    required this.teamId,
    required this.teamName,
    this.playerName,
    required this.chantStatus,
    required this.creatorId,
    required this.creatorHandle,
    required this.creatorDisplayName,
    required this.caption,
    required this.mediaPath,
    required this.durationMs,
    required this.publicationState,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.uniqueSharerCount = 0,
    this.weeklyUniqueSharerCount = 0,
    this.weeklyLikeCount = 0,
    this.weeklyQualifiedViewCount = 0,
    required this.rankingWeek,
    this.hidden = false,
    this.removed = false,
    this.sourceChantVisible = true,
    this.sourceCreatorVisible = true,
    required this.createdAt,
    required this.approvedAt,
    required this.updatedAt,
  });

  bool get isTerraceProven => chantStatus == 'canonical';

  bool get isVisible =>
      publicationState == PerformancePublicationState.approved &&
      !hidden &&
      !removed &&
      sourceChantVisible &&
      sourceCreatorVisible;

  factory Performance.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported performance schema.');
    }
    final state = PerformancePublicationState.fromFirestoreValue(
      json['publicationState'],
    );
    if (state == null) {
      throw const FormatException('Unsupported performance state.');
    }
    return Performance(
      id: id,
      chantId: json['chantId'] as String,
      chantTitle: json['chantTitle'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      playerName: json['playerName'] as String?,
      chantStatus: json['chantStatus'] as String,
      creatorId: json['creatorId'] as String,
      creatorHandle: json['creatorHandle'] as String,
      creatorDisplayName: json['creatorDisplayName'] as String,
      caption: json['caption'] as String,
      mediaPath: json['mediaPath'] as String,
      durationMs: json['durationMs'] as int,
      publicationState: state,
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      uniqueSharerCount: json['uniqueSharerCount'] as int? ?? 0,
      weeklyUniqueSharerCount: json['weeklyUniqueSharerCount'] as int? ?? 0,
      weeklyLikeCount: json['weeklyLikeCount'] as int? ?? 0,
      weeklyQualifiedViewCount: json['weeklyQualifiedViewCount'] as int? ?? 0,
      rankingWeek: json['rankingWeek'] as String,
      hidden: json['hidden'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      sourceChantVisible: json['sourceChantVisible'] as bool,
      sourceCreatorVisible: json['sourceCreatorVisible'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      approvedAt: (json['approvedAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Performance.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw const FormatException('Performance is missing.');
    return Performance.fromJson(data, id: document.id);
  }

  Performance copyWith({
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? uniqueSharerCount,
    int? weeklyUniqueSharerCount,
    int? weeklyLikeCount,
    int? weeklyQualifiedViewCount,
    String? rankingWeek,
  }) {
    return Performance(
      id: id,
      chantId: chantId,
      chantTitle: chantTitle,
      teamId: teamId,
      teamName: teamName,
      playerName: playerName,
      chantStatus: chantStatus,
      creatorId: creatorId,
      creatorHandle: creatorHandle,
      creatorDisplayName: creatorDisplayName,
      caption: caption,
      mediaPath: mediaPath,
      durationMs: durationMs,
      publicationState: publicationState,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      uniqueSharerCount: uniqueSharerCount ?? this.uniqueSharerCount,
      weeklyUniqueSharerCount:
          weeklyUniqueSharerCount ?? this.weeklyUniqueSharerCount,
      weeklyLikeCount: weeklyLikeCount ?? this.weeklyLikeCount,
      weeklyQualifiedViewCount:
          weeklyQualifiedViewCount ?? this.weeklyQualifiedViewCount,
      rankingWeek: rankingWeek ?? this.rankingWeek,
      hidden: hidden,
      removed: removed,
      sourceChantVisible: sourceChantVisible,
      sourceCreatorVisible: sourceCreatorVisible,
      createdAt: createdAt,
      approvedAt: approvedAt,
      updatedAt: updatedAt,
    );
  }
}

String performanceRankingWeek(DateTime value) {
  final utc = value.toUtc();
  final monday = DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
  ).subtract(Duration(days: utc.weekday - DateTime.monday));
  return '${monday.year.toString().padLeft(4, '0')}-'
      '${monday.month.toString().padLeft(2, '0')}-'
      '${monday.day.toString().padLeft(2, '0')}';
}
