import 'package:cloud_firestore/cloud_firestore.dart';

class Sport {
  final String id;
  final String name;
  final bool enabled;

  const Sport({
    required this.id,
    required this.name,
    required this.enabled,
  });

  factory Sport.fromJson(Map<String, dynamic> json, {required String id}) {
    return Sport(
      id: id,
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
    );
  }

  factory Sport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Sport.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enabled': enabled,
    };
  }

  Sport copyWith({
    String? id,
    String? name,
    bool? enabled,
  }) {
    return Sport(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }
}
