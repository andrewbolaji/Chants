import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum ChantUpdateFailure {
  duplicate,
  rateLimited,
  deletionInProgress,
  chantUnavailable,
  stale,
  evidenceConflict,
  actionMismatch,
  alreadyClosed,
  rejected,
}

class ChantUpdateException implements Exception {
  final ChantUpdateFailure failure;

  const ChantUpdateException(this.failure);
}

typedef ChantUpdateCallable =
    Future<Object?> Function(String callableName, Map<String, Object?> payload);
typedef ChantUpdateLoader =
    Stream<List<ChantUpdateSuggestion>> Function(String? ownerId);

class ChantUpdateRepository {
  final FirebaseFirestore? _firestoreOverride;
  final ChantUpdateCallable _invoke;
  final ChantUpdateLoader? _loader;

  ChantUpdateRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    ChantUpdateCallable? invoker,
    this._loader,
  }) : _firestoreOverride = firestore,
       _invoke =
           invoker ??
           _firebaseInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static ChantUpdateCallable _firebaseInvoker(FirebaseFunctions functions) {
    return (callableName, payload) async {
      final result = await functions.httpsCallable(callableName).call(payload);
      return result.data;
    };
  }

  Future<void> submit({
    required String chantId,
    required ChantUpdateKind kind,
    required ChantUpdateCategory? category,
    required String message,
    required ChantEvidence? evidence,
  }) async {
    await _call('submitChantUpdateSuggestion', {
      'chantId': chantId,
      'kind': kind.name,
      'category': category?.name,
      'message': message,
      'evidence': evidence?.toJson(),
    });
  }

  Future<void> moderate({
    required String suggestionId,
    required String action,
    required ChantUpdateResolution? resolutionKind,
    required String? resolutionNote,
    required bool acknowledgeStale,
    bool acknowledgeEvidenceReplacement = false,
  }) async {
    await _call('moderateChantUpdateSuggestion', {
      'suggestionId': suggestionId,
      'action': action,
      'resolutionKind': resolutionKind?.name,
      'resolutionNote': resolutionNote,
      'acknowledgeStale': acknowledgeStale,
      'acknowledgeEvidenceReplacement': acknowledgeEvidenceReplacement,
    });
  }

  Stream<List<ChantUpdateSuggestion>> mySuggestions(String uid) {
    final loader = _loader;
    if (loader != null) return loader(uid);
    return _firestore
        .collection('chantUpdateSuggestions')
        .where('submittedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs
                .map(
                  (document) => ChantUpdateSuggestion.tryFromJson(
                    document.data(),
                    id: document.id,
                  ),
                )
                .whereType<ChantUpdateSuggestion>(),
          ),
        );
  }

  Stream<List<ChantUpdateSuggestion>> operatorQueue() {
    final loader = _loader;
    if (loader != null) return loader(null);
    return _firestore
        .collection('chantUpdateSuggestions')
        .where('status', whereIn: const ['received', 'planned'])
        .orderBy('createdAt')
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs
                .map(
                  (document) => ChantUpdateSuggestion.tryFromJson(
                    document.data(),
                    id: document.id,
                  ),
                )
                .whereType<ChantUpdateSuggestion>(),
          ),
        );
  }

  Future<void> _call(String callableName, Map<String, Object?> payload) async {
    try {
      await _invoke(callableName, payload);
    } on FirebaseFunctionsException catch (error) {
      final reason = error.details is Map
          ? (error.details as Map)['reason'] as String?
          : null;
      final failure = switch ((error.code, reason)) {
        ('failed-precondition', 'account-deletion-in-progress') =>
          ChantUpdateFailure.deletionInProgress,
        ('failed-precondition', 'chant-unavailable') =>
          ChantUpdateFailure.chantUnavailable,
        ('failed-precondition', 'stale-chant-version') =>
          ChantUpdateFailure.stale,
        ('failed-precondition', 'evidence-replacement-unconfirmed') =>
          ChantUpdateFailure.evidenceConflict,
        ('failed-precondition', 'review-action-mismatch') =>
          ChantUpdateFailure.actionMismatch,
        ('failed-precondition', 'request-already-closed') =>
          ChantUpdateFailure.alreadyClosed,
        ('already-exists', _) => ChantUpdateFailure.duplicate,
        ('resource-exhausted', _) => ChantUpdateFailure.rateLimited,
        _ => ChantUpdateFailure.rejected,
      };
      throw ChantUpdateException(failure);
    } on ChantUpdateException {
      rethrow;
    } catch (_) {
      throw const ChantUpdateException(ChantUpdateFailure.rejected);
    }
  }
}
