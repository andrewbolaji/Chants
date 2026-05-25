import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/feedback_entry.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('feedback');

  Future<DocumentReference> submitFeedback({
    required String userId,
    required String category,
    required String message,
    required bool followUpOk,
  }) async {
    final entry = FeedbackEntry(
      id: '',
      userId: userId,
      category: category,
      message: message,
      followUpOk: followUpOk,
      createdAt: DateTime.now(),
    );
    return _collection.add(entry.toJson());
  }
}
