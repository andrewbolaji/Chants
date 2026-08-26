import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _comments =>
      _firestore.collection('comments');

  CollectionReference<Map<String, dynamic>> get _commentLikes =>
      _firestore.collection('commentLikes');

  CollectionReference<Map<String, dynamic>> get _commentReports =>
      _firestore.collection('commentReports');

  /// Stream of visible comments for a chant (hidden == false, removed == false).
  /// The security rules enforce visibility; the query must match.
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return _comments
        .where('chantId', isEqualTo: chantId)
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map(Comment.fromFirestore).toList());
  }

  /// Post a new comment.
  Future<void> createComment(Comment comment) async {
    await _comments.add(comment.toJson());
  }

  /// Soft-delete the author's own comment (sets removed: true).
  /// Fully invisible to the author too, because the visible-comments query
  /// excludes removed == true.
  Future<void> softDeleteComment({required String commentId}) async {
    await _comments.doc(commentId).update({'removed': true});
  }

  /// Like a comment. The transaction creates the client shape once, then
  /// updates only value so the Cloud Function's appliedValue is preserved.
  Future<void> likeComment({
    required String userId,
    required String commentId,
  }) async {
    final docId = CommentLike.documentId(userId, commentId);
    final like = CommentLike(
      id: docId,
      commentId: commentId,
      userId: userId,
      value: 1,
      createdAt: DateTime.now(),
    );
    final reference = _commentLikes.doc(docId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        transaction.update(reference, {'value': 1});
      } else {
        transaction.set(reference, like.toJson());
      }
    });
  }

  /// Unlike a comment (delete the like doc).
  Future<void> unlikeComment({
    required String userId,
    required String commentId,
  }) async {
    final docId = CommentLike.documentId(userId, commentId);
    await _commentLikes.doc(docId).delete();
  }

  /// Get the user's like for a specific comment, including appliedValue.
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async {
    final docId = CommentLike.documentId(userId, commentId);
    final doc = await _commentLikes.doc(docId).get();
    if (!doc.exists) return null;
    return CommentLike.fromFirestore(doc);
  }

  /// Stream a single comment doc for live likeCount updates.
  Stream<Comment?> commentStream(String commentId) {
    return _comments
        .doc(commentId)
        .snapshots()
        .map((doc) => doc.exists ? Comment.fromFirestore(doc) : null);
  }

  /// Submit a report on a comment. Doc ID = userId_commentId.
  Future<void> submitCommentReport({
    required String commentId,
    required String reportedBy,
    required String reason,
  }) async {
    final docId = '${reportedBy}_$commentId';
    await _commentReports.doc(docId).set({
      'commentId': commentId,
      'reportedBy': reportedBy,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Check if user already reported this comment.
  Future<bool> hasReportedComment({
    required String userId,
    required String commentId,
  }) async {
    final docId = '${userId}_$commentId';
    final doc = await _commentReports.doc(docId).get();
    return doc.exists;
  }
}
