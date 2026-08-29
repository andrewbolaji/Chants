import 'package:chants/data/models/creator_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

typedef CreatorNotificationLoader =
    Stream<List<CreatorNotification>> Function(String ownerId);
typedef CreatorNotificationReadAction =
    Future<void> Function(String notificationId);

class CreatorNotificationRepository {
  final FirebaseFirestore? _firestoreOverride;
  final CreatorNotificationLoader? notificationLoader;
  final CreatorNotificationReadAction? _readAction;

  CreatorNotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    this.notificationLoader,
    CreatorNotificationReadAction? readAction,
  }) : _firestoreOverride = firestore,
       _readAction =
           readAction ??
           (functions == null
               ? null
               : (notificationId) async {
                   await functions
                       .httpsCallable('markCreatorNotificationRead')
                       .call({'notificationId': notificationId});
                 });

  factory CreatorNotificationRepository.firebase({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    return CreatorNotificationRepository(
      firestore: firestore,
      functions:
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
    );
  }

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Stream<List<CreatorNotification>> notifications(String ownerId) {
    final loader = notificationLoader;
    if (loader != null) return loader(ownerId);
    return _firestore
        .collection('creatorNotifications')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(CreatorNotification.fromFirestore),
          ),
        );
  }

  Future<void> markRead(String notificationId) async {
    final action = _readAction;
    if (action == null) {
      throw StateError('No notification read action is configured.');
    }
    await action(notificationId);
  }
}
