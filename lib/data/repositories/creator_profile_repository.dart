import 'package:chants/data/models/creator_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum CreatorProfileFailure { handleUnavailable, invalid, unavailable }

class CreatorProfileException implements Exception {
  final CreatorProfileFailure failure;

  const CreatorProfileException(this.failure);
}

typedef CreatorProfileInvoker =
    Future<void> Function(Map<String, Object> payload);

class CreatorProfileRepository {
  final FirebaseFirestore? _firestoreOverride;
  final CreatorProfileInvoker _invoke;

  CreatorProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    CreatorProfileInvoker? invoker,
  }) : _firestoreOverride = firestore,
       _invoke =
           invoker ??
           _firebaseInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static CreatorProfileInvoker _firebaseInvoker(FirebaseFunctions functions) {
    return (payload) async {
      await functions.httpsCallable('updateCreatorProfile').call(payload);
    };
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('creatorProfiles');

  Stream<CreatorProfile?> profileStream(String userId) {
    return _collection.doc(userId).snapshots().map((document) {
      if (!document.exists) return null;
      return CreatorProfile.fromFirestore(document);
    });
  }

  Future<CreatorProfile?> getProfile(String userId) async {
    final document = await _collection.doc(userId).get();
    if (!document.exists) return null;
    return CreatorProfile.fromFirestore(document);
  }

  Future<void> updateIdentity({
    required String displayName,
    required String handle,
    required String bio,
  }) async {
    try {
      await _invoke({'displayName': displayName, 'handle': handle, 'bio': bio});
    } on FirebaseFunctionsException catch (error) {
      final failure = switch (error.code) {
        'already-exists' => CreatorProfileFailure.handleUnavailable,
        'invalid-argument' => CreatorProfileFailure.invalid,
        _ => CreatorProfileFailure.unavailable,
      };
      throw CreatorProfileException(failure);
    } on CreatorProfileException {
      rethrow;
    } catch (_) {
      throw const CreatorProfileException(CreatorProfileFailure.unavailable);
    }
  }
}
