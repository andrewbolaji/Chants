import 'dart:async';

import 'package:chants/data/repositories/songbook_storage.dart';

class MemorySongbookStorage implements SongbookStorage {
  final Map<String, String> active = {};
  final Map<String, String> tombstones = {};
  bool failRead = false;
  bool failWrite = false;
  bool failStage = false;
  bool failRestore = false;
  bool failFinish = false;

  @override
  Future<String?> read(String uid) async {
    if (failRead) throw StateError('read failed');
    return active[uid];
  }

  @override
  Future<void> writeAtomically(String uid, String contents) async {
    if (failWrite) throw StateError('write failed');
    active[uid] = contents;
  }

  @override
  Future<void> delete(String uid) async {
    active.remove(uid);
  }

  @override
  Future<bool> stageForAccountDeletion(String uid) async {
    if (failStage) throw StateError('stage failed');
    final contents = active.remove(uid);
    if (contents == null) return false;
    tombstones[uid] = contents;
    return true;
  }

  @override
  Future<void> restoreAfterAccountDeletionFailure(String uid) async {
    if (failRestore) throw StateError('restore failed');
    final contents = tombstones.remove(uid);
    if (contents != null) active[uid] = contents;
  }

  @override
  Future<void> finishAccountDeletion(String uid) async {
    if (failFinish) throw StateError('finish failed');
    tombstones.remove(uid);
  }

  @override
  Future<void> cleanupDeletionTombstones() async {
    tombstones.clear();
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
