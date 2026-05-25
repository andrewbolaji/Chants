import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('profiles');

  Future<void> createProfile({
    required String userId,
    required String displayName,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      displayName: displayName,
      role: 'user',
      createdAt: now,
      updatedAt: now,
    );
    await _collection.doc(userId).set(profile.toJson());
  }

  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Stream<UserProfile?> profileStream(String userId) {
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    await _collection.doc(userId).update({
      'displayName': displayName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
