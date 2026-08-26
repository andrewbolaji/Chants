import 'dart:async';

import 'package:chants/data/repositories/songbook_storage.dart';

class MemorySongbookStorage implements SongbookStorage {
  final Map<String, String> active = {};
  final Map<String, String> preparedTombstones = {};
  final Map<String, String> unknownTombstones = {};
  final Map<String, String> acceptedTombstones = {};
  bool failRead = false;
  bool failWrite = false;
  bool failStage = false;
  bool failStart = false;
  bool failAccept = false;
  bool failFinish = false;

  @override
  Future<String?> read(String uid) async {
    if (failRead) throw StateError('read failed');
    return active[uid];
  }

  @override
  Future<void> writeAtomically(String uid, String contents) async {
    if (failWrite) throw StateError('write failed');
    if (unknownTombstones.containsKey(uid)) {
      throw StateError('deletion outcome unknown');
    }
    active[uid] = contents;
  }

  @override
  Future<void> delete(String uid) async {
    active.remove(uid);
  }

  @override
  Future<bool> stageForAccountDeletion(String uid) async {
    if (failStage) throw StateError('stage failed');
    if (preparedTombstones.containsKey(uid) ||
        unknownTombstones.containsKey(uid) ||
        acceptedTombstones.containsKey(uid)) {
      return true;
    }
    final contents = active.remove(uid);
    if (contents == null) return false;
    preparedTombstones[uid] = contents;
    return true;
  }

  @override
  Future<void> markAccountDeletionRequestStarted(String uid) async {
    if (failStart) throw StateError('start failed');
    if (unknownTombstones.containsKey(uid) ||
        acceptedTombstones.containsKey(uid)) {
      return;
    }
    final contents = preparedTombstones.remove(uid);
    if (contents != null) unknownTombstones[uid] = contents;
  }

  @override
  Future<void> markAccountDeletionAccepted(String uid) async {
    if (failAccept) throw StateError('accept failed');
    if (acceptedTombstones.containsKey(uid)) return;
    final contents =
        unknownTombstones.remove(uid) ?? preparedTombstones.remove(uid);
    if (contents != null) acceptedTombstones[uid] = contents;
  }

  @override
  Future<void> finishAccountDeletion(String uid) async {
    if (failFinish) throw StateError('finish failed');
    acceptedTombstones.remove(uid);
  }

  @override
  Future<void> recoverAccountDeletionArtifacts(String uid) async {
    acceptedTombstones.remove(uid);
    final prepared = preparedTombstones.remove(uid);
    if (prepared != null && !active.containsKey(uid)) active[uid] = prepared;
  }
}

class DeferredFirstWriteSongbookStorage extends MemorySongbookStorage {
  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  int writes = 0;

  @override
  Future<void> writeAtomically(String uid, String contents) async {
    writes += 1;
    if (writes == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    await super.writeAtomically(uid, contents);
  }
}
