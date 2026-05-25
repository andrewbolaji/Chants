import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogEntry {
  final String id;
  final String actorId;
  final String action;
  final String targetType;
  final String targetId;
  final String detail;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.detail,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json,
      {required String id}) {
    return AuditLogEntry(
      id: id,
      actorId: json['actorId'] as String,
      action: json['action'] as String,
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as String,
      detail: json['detail'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory AuditLogEntry.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return AuditLogEntry.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'actorId': actorId,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'detail': detail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
