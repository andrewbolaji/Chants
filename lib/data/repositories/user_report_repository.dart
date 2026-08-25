import 'package:cloud_firestore/cloud_firestore.dart';

class UserReportRepository {
  final FirebaseFirestore _firestore;

  UserReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('userReports');

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
