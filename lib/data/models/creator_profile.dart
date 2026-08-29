import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorProfile {
  final String id;
  final String handle;
  final String displayName;
  final String bio;
  final int followerCount;
  final int followingCount;
  final int performanceCount;
  final int likeCount;
  final int shareCount;
  final bool hidden;
  final bool removed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreatorProfile({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.bio,
    required this.followerCount,
    required this.followingCount,
    required this.performanceCount,
    required this.likeCount,
    required this.shareCount,
    required this.hidden,
    required this.removed,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublic => !hidden && !removed;

  factory CreatorProfile.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return CreatorProfile(
      id: id,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String? ?? '',
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      performanceCount: json['performanceCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory CreatorProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return CreatorProfile.fromJson(document.data()!, id: document.id);
  }
}
