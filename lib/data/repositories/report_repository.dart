import 'package:cloud_firestore/cloud_firestore.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reports');

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
