import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String chantId;
  final String reportedBy;
  final String reason;
  final DateTime createdAt;
  final String status;

  const Report({
    required this.id,
    required this.chantId,
    required this.reportedBy,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  static const validStatuses = ['pending', 'reviewed', 'dismissed'];

  factory Report.fromJson(Map<String, dynamic> json, {required String id}) {
    return Report(
      id: id,
      chantId: json['chantId'] as String,
      reportedBy: json['reportedBy'] as String,
      reason: json['reason'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] as String,
    );
  }

  factory Report.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Report.fromJson(doc.data()!, id: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'chantId': chantId,
      'reportedBy': reportedBy,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
