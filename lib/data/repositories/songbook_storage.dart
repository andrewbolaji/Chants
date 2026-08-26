import 'dart:convert';
import 'dart:io';

import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/services/sha256.dart';
import 'package:path_provider/path_provider.dart';

String songbookStorageKeyForUid(String uid) {
  if (uid.isEmpty) throw ArgumentError.value(uid, 'uid', 'Cannot be empty.');
  return sha256Hex(utf8.encode(uid));
}

enum SongbookAccountDeletionState { none, prepared, unknown, accepted }

abstract class SongbookStorage {
  Future<String?> read(String uid);

  Future<void> writeAtomically(String uid, String contents);

  Future<void> delete(String uid);

  Future<bool> stageForAccountDeletion(String uid);

  Future<void> markAccountDeletionRequestStarted(String uid);

  Future<void> markAccountDeletionAccepted(String uid);

  Future<void> finishAccountDeletion(String uid);

  Future<void> recoverAccountDeletionArtifacts(String uid);

  Future<SongbookAccountDeletionState> accountDeletionState(String uid);
}

class _UidFiles {
  final File active;
  final File temporary;
  final File prepared;
  final File unknown;
  final File accepted;

  const _UidFiles({
    required this.active,
    required this.temporary,
    required this.prepared,
    required this.unknown,
    required this.accepted,
  });
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

  String _legacyStorageKey(String uid) {
    return base64Url.encode(utf8.encode(uid)).replaceAll('=', '');
  }

  File _file(Directory directory, String key, String suffix) {
    return File('${directory.path}${Platform.pathSeparator}$key.json$suffix');
  }

  Future<_UidFiles> _uidFiles(String uid) async {
    final directory = await _directory();
    final key = songbookStorageKeyForUid(uid);
    final files = _UidFiles(
      active: _file(directory, key, ''),
      temporary: _file(directory, key, '.tmp'),
      prepared: _file(directory, key, '.deleting.prepared'),
      unknown: _file(directory, key, '.deleting.unknown'),
      accepted: _file(directory, key, '.deleting.accepted'),
    );
    await _migrateLegacyUidFiles(directory, uid, files);
    return files;
  }

  Future<void> _migrateLegacyUidFiles(
    Directory directory,
    String uid,
    _UidFiles target,
  ) async {
    final legacyKey = _legacyStorageKey(uid);
    final migrations = <(File, File)>[
      (_file(directory, legacyKey, ''), target.active),
      (_file(directory, legacyKey, '.tmp'), target.temporary),
      // The old tombstone did not record whether the callable committed.
      // Preserve it as unknown instead of restoring or deleting it.
      (_file(directory, legacyKey, '.deleting'), target.unknown),
      (_file(directory, legacyKey, '.deleting.prepared'), target.prepared),
      (_file(directory, legacyKey, '.deleting.unknown'), target.unknown),
      (_file(directory, legacyKey, '.deleting.accepted'), target.accepted),
    ];
    for (final migration in migrations) {
      final source = migration.$1;
      final destination = migration.$2;
      if (!await source.exists() || await destination.exists()) continue;
      await source.rename(destination.path);
    }
  }

  @override
  Future<String?> read(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.unknown.exists() || await files.accepted.exists()) {
      return null;
    }
    final file = files.active;
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

    final files = await _uidFiles(uid);
    if (await files.unknown.exists() ||
        await files.accepted.exists() ||
        await files.prepared.exists()) {
      throw StateError('Saved Songbook is locked during account deletion.');
    }
    if (await files.temporary.exists()) await files.temporary.delete();
    try {
      await files.temporary.writeAsString(contents, flush: true);
      await files.temporary.rename(files.active.path);
    } catch (_) {
      if (await files.temporary.exists()) {
        try {
          await files.temporary.delete();
        } catch (_) {
          // A leftover temporary file is ignored and overwritten later.
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String uid) async {
    final file = (await _uidFiles(uid)).active;
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> stageForAccountDeletion(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.unknown.exists() ||
        await files.prepared.exists() ||
        await files.accepted.exists()) {
      return true;
    }
    if (!await files.active.exists()) return false;
    await files.active.rename(files.prepared.path);
    return true;
  }

  @override
  Future<void> markAccountDeletionRequestStarted(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.unknown.exists() || await files.accepted.exists()) return;
    if (await files.prepared.exists()) {
      await files.prepared.rename(files.unknown.path);
    }
  }

  @override
  Future<void> markAccountDeletionAccepted(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.accepted.exists()) return;
    if (await files.unknown.exists()) {
      await files.unknown.rename(files.accepted.path);
    } else if (await files.prepared.exists()) {
      await files.prepared.rename(files.accepted.path);
    }
  }

  @override
  Future<void> finishAccountDeletion(String uid) async {
    final files = await _uidFiles(uid);
    await _finishAcceptedDeletion(files);
  }

  Future<void> _finishAcceptedDeletion(_UidFiles files) async {
    if (!await files.accepted.exists()) return;
    for (final file in [
      files.active,
      files.temporary,
      files.prepared,
      files.unknown,
    ]) {
      if (await file.exists()) await file.delete();
    }
    // Keep the accepted marker until every potentially readable artifact is
    // gone. A partial failure therefore remains locked and retryable.
    await files.accepted.delete();
  }

  @override
  Future<void> recoverAccountDeletionArtifacts(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.accepted.exists()) {
      try {
        await _finishAcceptedDeletion(files);
      } catch (_) {
        // Accepted data remains unreadable and cleanup retries next time.
      }
      return;
    }
    if (!await files.unknown.exists() &&
        await files.prepared.exists() &&
        !await files.active.exists()) {
      await files.prepared.rename(files.active.path);
    }
    // Unknown means the server may already own destructive completion. It is
    // intentionally neither restored nor deleted without another acceptance.
  }

  @override
  Future<SongbookAccountDeletionState> accountDeletionState(String uid) async {
    final files = await _uidFiles(uid);
    if (await files.accepted.exists()) {
      return SongbookAccountDeletionState.accepted;
    }
    if (await files.unknown.exists()) {
      return SongbookAccountDeletionState.unknown;
    }
    if (await files.prepared.exists()) {
      return SongbookAccountDeletionState.prepared;
    }
    return SongbookAccountDeletionState.none;
  }
}
