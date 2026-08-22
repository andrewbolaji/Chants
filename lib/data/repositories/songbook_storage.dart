import 'dart:convert';
import 'dart:io';

import 'package:chants/data/models/saved_songbook.dart';
import 'package:path_provider/path_provider.dart';

abstract class SongbookStorage {
  Future<String?> read(String uid);

  Future<void> writeAtomically(String uid, String contents);

  Future<void> delete(String uid);

  Future<bool> stageForAccountDeletion(String uid);

  Future<void> restoreAfterAccountDeletionFailure(String uid);

  Future<void> finishAccountDeletion(String uid);

  Future<void> cleanupDeletionTombstones();
}

class FileSongbookStorage implements SongbookStorage {
  final Future<Directory> Function() _supportDirectory;

  FileSongbookStorage({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  Future<Directory> _directory() async {
    final support = await _supportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}matchday_songbook',
    );
    await directory.create(recursive: true);
    return directory;
  }

  String _safeUid(String uid) {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid', 'Cannot be empty.');
    return base64Url.encode(utf8.encode(uid)).replaceAll('=', '');
  }

  Future<File> _activeFile(String uid) async {
    final directory = await _directory();
    return File(
      '${directory.path}${Platform.pathSeparator}${_safeUid(uid)}.json',
    );
  }

  Future<File> _temporaryFile(String uid) async {
    final active = await _activeFile(uid);
    return File('${active.path}.tmp');
  }

  Future<File> _tombstoneFile(String uid) async {
    final active = await _activeFile(uid);
    return File('${active.path}.deleting');
  }

  @override
  Future<String?> read(String uid) async {
    final file = await _activeFile(uid);
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length > SavedSongbook.maxEncodedBytes) {
      throw const SavedSongbookLimitException(
        'Saved Songbook file exceeds 2 MiB.',
      );
    }
    try {
      return utf8.decode(await file.readAsBytes());
    } on FormatException {
      throw const SavedSongbookFormatException(
        'Saved Songbook file is not valid UTF-8.',
      );
    }
  }

  @override
  Future<void> writeAtomically(String uid, String contents) async {
    if (utf8.encode(contents).length > SavedSongbook.maxEncodedBytes) {
      throw const SavedSongbookLimitException(
        'Saved Songbook file exceeds 2 MiB.',
      );
    }

    final active = await _activeFile(uid);
    final temporary = await _temporaryFile(uid);
    if (await temporary.exists()) await temporary.delete();
    try {
      await temporary.writeAsString(contents, flush: true);
      await temporary.rename(active.path);
    } catch (_) {
      if (await temporary.exists()) {
        try {
          await temporary.delete();
        } catch (_) {
          // A leftover temporary file is ignored by readers and overwritten
          // by the next write attempt.
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String uid) async {
    final file = await _activeFile(uid);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> stageForAccountDeletion(String uid) async {
    final active = await _activeFile(uid);
    if (!await active.exists()) return false;
    final tombstone = await _tombstoneFile(uid);
    if (await tombstone.exists()) await tombstone.delete();
    await active.rename(tombstone.path);
    return true;
  }

  @override
  Future<void> restoreAfterAccountDeletionFailure(String uid) async {
    final tombstone = await _tombstoneFile(uid);
    if (!await tombstone.exists()) return;
    final active = await _activeFile(uid);
    if (await active.exists()) {
      throw StateError('Cannot restore over an active Saved Songbook file.');
    }
    await tombstone.rename(active.path);
  }

  @override
  Future<void> finishAccountDeletion(String uid) async {
    final tombstone = await _tombstoneFile(uid);
    if (await tombstone.exists()) await tombstone.delete();
  }

  @override
  Future<void> cleanupDeletionTombstones() async {
    final directory = await _directory();
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.json.deleting')) {
        try {
          await entity.delete();
        } catch (_) {
          // An unreadable tombstone is never considered an active snapshot.
          // Cleanup is retried when a later repository instance starts.
        }
      }
    }
  }
}
