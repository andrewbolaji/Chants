import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

typedef CreatorFollowAction =
    Future<bool> Function(String targetCreatorId, bool following);
typedef CreatorFollowStateLoader =
    Future<bool> Function(String followerId, String followedId);
typedef FollowedCreatorLoader =
    Future<List<String>> Function(String followerId);

class CreatorFollowRepository {
  final FirebaseFirestore? _firestoreOverride;
  final CreatorFollowAction? _followAction;
  final CreatorFollowStateLoader? followStateLoader;
  final FollowedCreatorLoader? followedCreatorLoader;

  CreatorFollowRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    CreatorFollowAction? followAction,
    this.followStateLoader,
    this.followedCreatorLoader,
  }) : _firestoreOverride = firestore,
       _followAction =
           followAction ??
           (functions == null
               ? null
               : (targetCreatorId, following) async {
                   final result = await functions
                       .httpsCallable('setCreatorFollow')
                       .call({
                         'targetCreatorId': targetCreatorId,
                         'following': following,
                       });
                   final data = result.data;
                   return data is Map && data['changed'] == true;
                 });

  factory CreatorFollowRepository.firebase({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    return CreatorFollowRepository(
      firestore: firestore,
      functions:
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
    );
  }

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static String documentId(String followerId, String followedId) {
    return '${followerId}_$followedId';
  }

  Future<bool> isFollowing({
    required String followerId,
    required String followedId,
  }) async {
    final loader = followStateLoader;
    if (loader != null) return loader(followerId, followedId);
    final snapshot = await _firestore
        .collection('creatorFollows')
        .doc(documentId(followerId, followedId))
        .get();
    return snapshot.exists;
  }

  Future<List<String>> followedCreatorIds(String followerId) async {
    final loader = followedCreatorLoader;
    if (loader != null) return List.unmodifiable(await loader(followerId));
    final snapshot = await _firestore
        .collection('creatorFollows')
        .where('followerId', isEqualTo: followerId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    return List.unmodifiable(
      snapshot.docs
          .map((document) => document.data()['followedId'])
          .whereType<String>(),
    );
  }

  Future<bool> setFollowing({
    required String targetCreatorId,
    required bool following,
  }) async {
    final action = _followAction;
    if (action == null) {
      throw StateError('No creator follow action is configured.');
    }
    return action(targetCreatorId, following);
  }
}
