import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reports');

  Future<DocumentReference> submitReport({
    required String chantId,
    required String reportedBy,
    required String reason,
  }) async {
    final report = Report(
      id: '',
      chantId: chantId,
      reportedBy: reportedBy,
      reason: reason,
      createdAt: DateTime.now(),
      status: 'pending',
    );
    return _collection.add(report.toJson());
  }
}
