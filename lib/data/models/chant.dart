import 'package:cloud_firestore/cloud_firestore.dart';

class ChantVariation {
  final String label;
  final String lyric;
  final String? contextNote;

  const ChantVariation({
    required this.label,
    required this.lyric,
    this.contextNote,
  });

  factory ChantVariation.fromJson(Map<String, dynamic> json) {
    return ChantVariation(
      label: json['label'] as String,
      lyric: json['lyric'] as String,
      contextNote: json['contextNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'lyric': lyric,
      'contextNote': contextNote,
    };
  }
}

class Chant {
  final String id;
  final String title;
  final String sportId;
  final String competitionId;
  final String teamId;
  final String? playerId;
  final String subjectTag;
  final String lyrics;
  final String tuneName;
  final String? contextNotes;
  final String? coverImageUrl;
  final String? mediaUrl;
  final String mediaType;
  final String status;
  final String realOrParody;
  final int upvotes;
  final int downvotes;
  final int score;
  final int commentCount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int flagCount;
  final bool hidden;
  final bool removed;
  final List<ChantVariation> variations;

  const Chant({
    required this.id,
    required this.title,
    required this.sportId,
    required this.competitionId,
    required this.teamId,
    this.playerId,
    required this.subjectTag,
    required this.lyrics,
    required this.tuneName,
    this.contextNotes,
    this.coverImageUrl,
    this.mediaUrl,
    required this.mediaType,
    required this.status,
    required this.realOrParody,
    this.upvotes = 0,
    this.downvotes = 0,
    this.score = 0,
    this.commentCount = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.flagCount = 0,
    this.hidden = false,
    this.removed = false,
    this.variations = const [],
  });

  static const validSubjectTags = ['player', 'coach', 'club', 'rival'];
  static const validMediaTypes = [
    'none',
    'audio',
    'tuneRecording',
    'lyricVideo',
    'screenRecording',
    'crowdClip',
  ];
  static const validStatuses = ['canonical', 'community'];
  static const validRealOrParody = ['real', 'parody'];

  factory Chant.fromJson(Map<String, dynamic> json, {required String id}) {
    return Chant(
      id: id,
      title: json['title'] as String,
      sportId: json['sportId'] as String,
      competitionId: json['competitionId'] as String,
      teamId: json['teamId'] as String,
      playerId: json['playerId'] as String?,
      subjectTag: json['subjectTag'] as String,
      lyrics: json['lyrics'] as String,
      tuneName: json['tuneName'] as String,
      contextNotes: json['contextNotes'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String,
      status: json['status'] as String,
      realOrParody: json['realOrParody'] as String,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      flagCount: json['flagCount'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      variations: (json['variations'] as List<dynamic>?)
              ?.map((v) => ChantVariation.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory Chant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Chant.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sportId': sportId,
      'competitionId': competitionId,
      'teamId': teamId,
      'playerId': playerId,
      'subjectTag': subjectTag,
      'lyrics': lyrics,
      'tuneName': tuneName,
      'contextNotes': contextNotes,
      'coverImageUrl': coverImageUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'status': status,
      'realOrParody': realOrParody,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'commentCount': commentCount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'flagCount': flagCount,
      'hidden': hidden,
      'removed': removed,
      'variations': variations.map((v) => v.toJson()).toList(),
    };
  }

  Chant copyWith({
    String? id,
    String? title,
    String? sportId,
    String? competitionId,
    String? teamId,
    String? playerId,
    String? subjectTag,
    String? lyrics,
    String? tuneName,
    String? contextNotes,
    String? coverImageUrl,
    String? mediaUrl,
    String? mediaType,
    String? status,
    String? realOrParody,
    int? upvotes,
    int? downvotes,
    int? score,
    int? commentCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? flagCount,
    bool? hidden,
    bool? removed,
    List<ChantVariation>? variations,
  }) {
    return Chant(
      id: id ?? this.id,
      title: title ?? this.title,
      sportId: sportId ?? this.sportId,
      competitionId: competitionId ?? this.competitionId,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      subjectTag: subjectTag ?? this.subjectTag,
      lyrics: lyrics ?? this.lyrics,
      tuneName: tuneName ?? this.tuneName,
      contextNotes: contextNotes ?? this.contextNotes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      realOrParody: realOrParody ?? this.realOrParody,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      score: score ?? this.score,
      commentCount: commentCount ?? this.commentCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flagCount: flagCount ?? this.flagCount,
      hidden: hidden ?? this.hidden,
      removed: removed ?? this.removed,
      variations: variations ?? this.variations,
    );
  }
}
