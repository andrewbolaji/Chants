import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  static const validRoles = ['user', 'operator'];

  factory UserProfile.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return UserProfile(
      id: id,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory UserProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserProfile.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOperator => role == 'operator';

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
