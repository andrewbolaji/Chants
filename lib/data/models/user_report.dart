import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport {
  final String id;
  final String reportedUserId;
  final String reportedBy;
  final String reason;
  final DateTime createdAt;
  final String status;

  const UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reportedBy,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  static const validStatuses = ['pending', 'reviewed', 'dismissed'];

  factory UserReport.fromJson(Map<String, dynamic> json, {required String id}) {
    return UserReport(
      id: id,
      reportedUserId: json['reportedUserId'] as String,
      reportedBy: json['reportedBy'] as String,
      reason: json['reason'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] as String,
    );
  }

  factory UserReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserReport.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'reportedUserId': reportedUserId,
      'reportedBy': reportedBy,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
