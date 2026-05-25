import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String teamId;
  final String name;

  const Player({
    required this.id,
    required this.teamId,
    required this.name,
  });

  factory Player.fromJson(Map<String, dynamic> json, {required String id}) {
    return Player(
      id: id,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
    );
  }

  factory Player.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Player.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'name': name,
    };
  }

  Player copyWith({
    String? id,
    String? teamId,
    String? name,
  }) {
    return Player(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
    );
  }
}
