import 'dart:math';

import 'package:chants/data/models/performance_comment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

typedef PerformanceLikeAction =
    Future<void> Function(String performanceId, bool liked);
typedef QualifiedViewAction = Future<void> Function(String performanceId);
typedef PerformanceShareAction = Future<bool> Function(String performanceId);
typedef PerformanceLikeLoader =
    Future<bool> Function(String userId, String performanceId);
typedef PerformanceCommentLoader =
    Stream<List<PerformanceComment>> Function(String performanceId);
typedef PerformanceThreadLoader =
    Stream<List<PerformanceComment>> Function(
      String performanceId,
      String rootCommentId,
    );
typedef PerformanceCommentAction =
    Future<String> Function(
      String performanceId,
      String body,
      String clientActionId,
      String? parentCommentId,
    );
typedef PerformanceCommentDeleteAction =
    Future<void> Function(String commentId);

class PerformanceInteractionRepository {
  final FirebaseFirestore? _firestoreOverride;
  final PerformanceLikeAction? _likeAction;
  final QualifiedViewAction? _viewAction;
  final PerformanceShareAction? _shareAction;
  final PerformanceLikeLoader? likeLoader;
  final PerformanceCommentLoader? commentLoader;
  final PerformanceThreadLoader? threadLoader;
  final PerformanceCommentAction? _commentAction;
  final PerformanceCommentDeleteAction? _commentDeleteAction;

  PerformanceInteractionRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    PerformanceLikeAction? likeAction,
    QualifiedViewAction? viewAction,
    PerformanceShareAction? shareAction,
    this.likeLoader,
    this.commentLoader,
    this.threadLoader,
    PerformanceCommentAction? commentAction,
    PerformanceCommentDeleteAction? commentDeleteAction,
  }) : _firestoreOverride = firestore,
       _likeAction =
           likeAction ??
           (functions == null
               ? null
               : (performanceId, liked) async {
                   await functions.httpsCallable('setPerformanceLike').call({
                     'performanceId': performanceId,
                     'liked': liked,
                   });
                 }),
       _viewAction =
           viewAction ??
           (functions == null
               ? null
               : (performanceId) async {
                   await functions
                       .httpsCallable('recordQualifiedPerformanceView')
                       .call({'performanceId': performanceId});
                 }),
       _shareAction =
           shareAction ??
           (functions == null
               ? null
               : (performanceId) async {
                   final result = await functions
                       .httpsCallable('recordPerformanceShare')
                       .call({'performanceId': performanceId});
                   final data = result.data;
                   return data is Map && data['counted'] == true;
                 }),
       _commentAction =
           commentAction ??
           (functions == null
               ? null
               : (performanceId, body, clientActionId, parentCommentId) async {
                   final result = await functions
                       .httpsCallable('createPerformanceComment')
                       .call({
                         'performanceId': performanceId,
                         'body': body,
                         'clientActionId': clientActionId,
                         'parentCommentId': parentCommentId,
                       });
                   final data = result.data;
                   if (data is! Map || data['commentId'] is! String) {
                     throw const FormatException(
                       'Comment confirmation is unavailable.',
                     );
                   }
                   return data['commentId'] as String;
                 }),
       _commentDeleteAction =
           commentDeleteAction ??
           (functions == null
               ? null
               : (commentId) async {
                   await functions
                       .httpsCallable('deletePerformanceComment')
                       .call({'commentId': commentId});
                 });

  factory PerformanceInteractionRepository.firebase({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    return PerformanceInteractionRepository(
      firestore: firestore,
      functions:
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
    );
  }

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static String newClientActionId() {
    final random = Random.secure().nextInt(0x7fffffff);
    return '${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  Future<bool> isLiked({
    required String userId,
    required String performanceId,
  }) async {
    final loader = likeLoader;
    if (loader != null) return loader(userId, performanceId);
    final document = await _firestore
        .collection('performanceLikes')
        .doc('${userId}_$performanceId')
        .get();
    return document.exists;
  }

  Future<void> setLiked({
    required String performanceId,
    required bool liked,
  }) async {
    final action = _likeAction;
    if (action == null) {
      throw StateError('No performance like action is configured.');
    }
    await action(performanceId, liked);
  }

  Future<void> recordQualifiedView(String performanceId) async {
    final action = _viewAction;
    if (action == null) {
      throw StateError('No qualified-view action is configured.');
    }
    await action(performanceId);
  }

  Future<bool> recordShare(String performanceId) async {
    final action = _shareAction;
    if (action == null) {
      throw StateError('No performance share action is configured.');
    }
    return action(performanceId);
  }

  Stream<List<PerformanceComment>> commentsForPerformance(
    String performanceId,
  ) {
    final loader = commentLoader;
    if (loader != null) return loader(performanceId);
    return _firestore
        .collection('performanceComments')
        .where(
          'schemaVersion',
          whereIn: PerformanceComment.supportedSchemaVersions,
        )
        .where('performanceId', isEqualTo: performanceId)
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(PerformanceComment.fromFirestore),
          ),
        );
  }

  Stream<List<PerformanceComment>> commentsForThread({
    required String performanceId,
    required String rootCommentId,
  }) {
    final loader = threadLoader;
    if (loader != null) return loader(performanceId, rootCommentId);
    return _firestore
        .collection('performanceComments')
        .where('schemaVersion', isEqualTo: PerformanceComment.schemaVersion)
        .where('performanceId', isEqualTo: performanceId)
        .where('rootCommentId', isEqualTo: rootCommentId)
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .orderBy('createdAt')
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(PerformanceComment.fromFirestore),
          ),
        );
  }

  Future<String> createComment({
    required String performanceId,
    required String body,
    required String clientActionId,
    String? parentCommentId,
  }) async {
    final action = _commentAction;
    if (action == null) {
      throw StateError('No performance comment action is configured.');
    }
    return action(performanceId, body, clientActionId, parentCommentId);
  }

  Future<void> deleteComment(String commentId) async {
    final action = _commentDeleteAction;
    if (action == null) {
      throw StateError('No performance comment delete action is configured.');
    }
    await action(commentId);
  }
}
