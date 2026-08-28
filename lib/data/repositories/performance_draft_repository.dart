import 'dart:async';
import 'dart:io';

import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

typedef PerformanceDraftInvoker =
    Future<Map<String, dynamic>> Function(
      String callable,
      Map<String, Object> payload,
    );

class PerformanceUploadHandle {
  final Future<void> completion;
  final Stream<double> progress;
  final Future<bool> Function() cancel;

  const PerformanceUploadHandle({
    required this.completion,
    required this.progress,
    required this.cancel,
  });
}

typedef PerformanceUploader =
    PerformanceUploadHandle Function({
      required PerformanceDraftTicket ticket,
      required SelectedPerformanceMedia media,
      required String ownerId,
    });

typedef PerformanceDraftStreamLoader =
    Stream<List<PerformanceDraft>> Function(String ownerId);
typedef PerformanceReviewQueueLoader =
    Stream<List<PerformanceDraft>> Function();

class PerformanceDraftRepository {
  final FirebaseFirestore? _firestoreOverride;
  final PerformanceDraftInvoker _invoke;
  final PerformanceUploader _upload;
  final PerformanceDraftStreamLoader? ownerDraftsLoader;
  final PerformanceReviewQueueLoader? reviewQueueLoader;

  PerformanceDraftRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    PerformanceDraftInvoker? invoker,
    PerformanceUploader? uploader,
    this.ownerDraftsLoader,
    this.reviewQueueLoader,
  }) : _firestoreOverride = firestore,
       _invoke =
           invoker ??
           _firebaseInvoker(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           ),
       _upload =
           uploader ?? _firebaseUploader(storage ?? FirebaseStorage.instance);

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static PerformanceDraftInvoker _firebaseInvoker(FirebaseFunctions functions) {
    return (callable, payload) async {
      final result = await functions.httpsCallable(callable).call(payload);
      if (result.data is! Map) {
        throw const FormatException('Invalid performance response.');
      }
      return Map<String, dynamic>.from(result.data as Map);
    };
  }

  static PerformanceUploader _firebaseUploader(FirebaseStorage storage) {
    return ({
      required PerformanceDraftTicket ticket,
      required SelectedPerformanceMedia media,
      required String ownerId,
    }) {
      final task = storage
          .ref(ticket.uploadPath)
          .putFile(
            File(media.filePath),
            SettableMetadata(
              contentType: media.contentType,
              customMetadata: {
                'ownerId': ownerId,
                'draftId': ticket.draftId,
                'schemaVersion': '1',
              },
            ),
          );
      final progress = task.snapshotEvents.map((snapshot) {
        if (snapshot.totalBytes <= 0) return 0.0;
        return snapshot.bytesTransferred / snapshot.totalBytes;
      }).distinct();
      return PerformanceUploadHandle(
        completion: task.then<void>((_) {}),
        progress: progress,
        cancel: task.cancel,
      );
    };
  }

  Stream<List<PerformanceDraft>> draftsForOwner(String ownerId) {
    final loader = ownerDraftsLoader;
    if (loader != null) return loader(ownerId);
    return _firestore
        .collection('performanceDrafts')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(PerformanceDraft.fromFirestore),
          ),
        );
  }

  Stream<List<PerformanceDraft>> pendingReviewQueue() {
    final loader = reviewQueueLoader;
    if (loader != null) return loader();
    return _firestore
        .collection('performanceDrafts')
        .where('state', isEqualTo: 'pending_review')
        .orderBy('submittedAt')
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(PerformanceDraft.fromFirestore),
          ),
        );
  }

  Future<PerformanceDraftTicket> createDraft({
    required String chantId,
    required String caption,
    required SelectedPerformanceMedia media,
  }) async {
    final result = await _invoke('createPerformanceDraft', {
      'chantId': chantId,
      'caption': caption,
      'contentType': media.contentType,
      'sizeBytes': media.sizeBytes,
      'durationMs': media.durationMs,
    });
    final draftId = result['draftId'];
    final uploadPath = result['uploadPath'];
    if (draftId is! String || uploadPath is! String) {
      throw const FormatException('Invalid performance draft ticket.');
    }
    return PerformanceDraftTicket(draftId: draftId, uploadPath: uploadPath);
  }

  PerformanceUploadHandle upload({
    required PerformanceDraftTicket ticket,
    required SelectedPerformanceMedia media,
    required String ownerId,
  }) {
    return _upload(ticket: ticket, media: media, ownerId: ownerId);
  }

  Future<void> submit(String draftId) async {
    await _invoke('submitPerformanceDraft', {'draftId': draftId});
  }

  Future<void> cancel(String draftId) async {
    await _invoke('cancelPerformanceDraft', {'draftId': draftId});
  }

  Future<void> moderate({
    required String draftId,
    required bool approve,
    String reason = '',
  }) async {
    await _invoke('moderatePerformance', {
      'draftId': draftId,
      'action': approve ? 'approve' : 'reject',
      'reason': reason,
    });
  }

  Future<Uri> resolveDraftPlayback(String draftId) async {
    final result = await _invoke('resolvePerformanceDraftPlayback', {
      'draftId': draftId,
    });
    final value = result['url'];
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('Performance preview is unavailable.');
    }
    return uri;
  }
}
