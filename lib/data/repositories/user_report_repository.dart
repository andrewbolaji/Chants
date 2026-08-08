import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/user_report.dart';

class UserReportRepository {
  final FirebaseFirestore _firestore;

  UserReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('userReports');

  /// Doc ID = {reporterId}_{reportedUserId} to enforce one report per
  /// reporter per reported user.
  Future<void> submitUserReport({
    required String reportedUserId,
    required String reportedBy,
    required String reason,
  }) async {
    final docId = '${reportedBy}_$reportedUserId';
    final report = UserReport(
      id: docId,
      reportedUserId: reportedUserId,
      reportedBy: reportedBy,
      reason: reason,
      createdAt: DateTime.now(),
      status: 'pending',
    );
    await _collection.doc(docId).set(report.toJson());
  }

  /// Check if the user already reported this account.
  Future<bool> hasReportedUser({
    required String userId,
    required String reportedUserId,
  }) async {
    final docId = '${userId}_$reportedUserId';
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
