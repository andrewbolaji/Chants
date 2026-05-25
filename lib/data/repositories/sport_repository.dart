import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/sport.dart';

class SportRepository {
  final FirebaseFirestore _firestore;

  SportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('sports');

  Stream<List<Sport>> enabledSportsStream() {
    return _collection
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Sport.fromFirestore).toList());
  }

  Future<Sport?> getSport(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Sport.fromFirestore(doc);
  }
}
