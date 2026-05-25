import 'package:cloud_firestore/cloud_firestore.dart';

class Competition {
  final String id;
  final String sportId;
  final String name;
  final bool enabled;

  const Competition({
    required this.id,
    required this.sportId,
    required this.name,
    required this.enabled,
  });

  factory Competition.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return Competition(
      id: id,
      sportId: json['sportId'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
    );
  }

  factory Competition.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return Competition.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'sportId': sportId,
      'name': name,
      'enabled': enabled,
    };
  }

  Competition copyWith({
    String? id,
    String? sportId,
    String? name,
    bool? enabled,
  }) {
    return Competition(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }
}
