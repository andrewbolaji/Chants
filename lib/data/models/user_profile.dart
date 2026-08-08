import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String role;
  final bool banned;
  final bool ageConfirmed17Plus;
  final String? acceptedPolicyVersion;
  final DateTime? acceptedPolicyAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.banned = false,
    this.ageConfirmed17Plus = false,
    this.acceptedPolicyVersion,
    this.acceptedPolicyAt,
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
      banned: json['banned'] as bool? ?? false,
      ageConfirmed17Plus: json['ageConfirmed17Plus'] as bool? ?? false,
      acceptedPolicyVersion: json['acceptedPolicyVersion'] as String?,
      acceptedPolicyAt:
          (json['acceptedPolicyAt'] as Timestamp?)?.toDate(),
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
      'banned': banned,
      'ageConfirmed17Plus': ageConfirmed17Plus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOperator => role == 'operator';

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? role,
    bool? banned,
    bool? ageConfirmed17Plus,
    String? acceptedPolicyVersion,
    DateTime? acceptedPolicyAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      banned: banned ?? this.banned,
      ageConfirmed17Plus: ageConfirmed17Plus ?? this.ageConfirmed17Plus,
      acceptedPolicyVersion:
          acceptedPolicyVersion ?? this.acceptedPolicyVersion,
      acceptedPolicyAt: acceptedPolicyAt ?? this.acceptedPolicyAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
