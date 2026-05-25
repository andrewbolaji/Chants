import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reports');

  /// Doc ID = {userId}_{chantId} to enforce one report per user per chant.
  Future<void> submitReport({
    required String chantId,
    required String reportedBy,
    required String reason,
  }) async {
    final docId = '${reportedBy}_$chantId';
    final report = Report(
      id: docId,
      chantId: chantId,
      reportedBy: reportedBy,
      reason: reason,
      createdAt: DateTime.now(),
      status: 'pending',
    );
    await _collection.doc(docId).set(report.toJson());
  }

  /// Check if the user already reported this chant.
  Future<bool> hasReported({
    required String userId,
    required String chantId,
  }) async {
    final docId = '${userId}_$chantId';
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
