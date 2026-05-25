import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String sportId;
  final String competitionId;
  final String name;
  final String? crestImageUrl;

  const Team({
    required this.id,
    required this.sportId,
    required this.competitionId,
    required this.name,
    this.crestImageUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json, {required String id}) {
    return Team(
      id: id,
      sportId: json['sportId'] as String,
      competitionId: json['competitionId'] as String,
      name: json['name'] as String,
      crestImageUrl: json['crestImageUrl'] as String?,
    );
  }

  factory Team.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Team.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'sportId': sportId,
      'competitionId': competitionId,
      'name': name,
      'crestImageUrl': crestImageUrl,
    };
  }

  Team copyWith({
    String? id,
    String? sportId,
    String? competitionId,
    String? name,
    String? crestImageUrl,
  }) {
    return Team(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      competitionId: competitionId ?? this.competitionId,
      name: name ?? this.name,
      crestImageUrl: crestImageUrl ?? this.crestImageUrl,
    );
  }
}
