import 'dart:async';
import 'dart:convert';

import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/songbook_storage.dart';

class SavedSongbookAccountDeletionException implements Exception {
  final Object primaryError;
  final Object cleanupError;

  const SavedSongbookAccountDeletionException({
    required this.primaryError,
    required this.cleanupError,
  });

  @override
  String toString() {
    return 'Account deletion failed and the local Songbook could not be '
        'restored: $primaryError; cleanup: $cleanupError';
  }
}

class SavedSongbookAccessException implements Exception {
  final String uid;

  const SavedSongbookAccessException(this.uid);

  @override
  String toString() => 'SavedSongbookAccessException: $uid';
}

class SavedSongbookRepository {
  final SongbookStorage _storage;
  final bool Function(String uid) _canAccess;
  Future<void> _mutationTail = Future.value();
  Future<void>? _initialization;

  SavedSongbookRepository({
    SongbookStorage? storage,
    bool Function(String uid)? canAccess,
  }) : _storage = storage ?? FileSongbookStorage(),
       _canAccess = canAccess ?? ((_) => true);

  void _requireAccess(String uid) {
    if (!_canAccess(uid)) throw SavedSongbookAccessException(uid);
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _storage.cleanupDeletionTombstones();
  }

  Future<SavedSongbook> load(String uid) async {
    _requireAccess(uid);
    await _ensureInitialized();
    return _read(uid);
  }

  Future<SavedSongbook> _read(String uid) async {
    final contents = await _storage.read(uid);
    if (contents == null) return SavedSongbook.empty();
    try {
      return SavedSongbook.fromJson(jsonDecode(contents));
    } on UnsupportedSavedSongbookVersion {
      rethrow;
    } on SavedSongbookLimitException {
      rethrow;
    } on SavedSongbookFormatException {
      rethrow;
    } on FormatException {
      throw const SavedSongbookFormatException(
        'Saved Songbook file is not valid JSON.',
      );
    } catch (_) {
      throw const SavedSongbookFormatException(
        'Saved Songbook file has an invalid shape.',
      );
    }
  }

  String _encode(SavedSongbook songbook) {
    final encoded = jsonEncode(songbook.toJson());
    if (utf8.encode(encoded).length > SavedSongbook.maxEncodedBytes) {
      throw const SavedSongbookLimitException(
        'Saved Songbook file exceeds 2 MiB.',
      );
    }
    return encoded;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<SavedSongbook> _update(
    String uid,
    SavedSongbook Function(SavedSongbook current) transform,
  ) {
    return _enqueue(() async {
      _requireAccess(uid);
      await _ensureInitialized();
      final current = await _read(uid);
      final next = transform(current);
      await _storage.writeAtomically(uid, _encode(next));
      return next;
    });
  }

  Future<SavedSongbook> saveClub({
    required String uid,
    required Team team,
    required Iterable<Chant> chants,
    required DateTime refreshedAt,
  }) {
    final chantList = List<Chant>.unmodifiable(chants);
    if (chantList.any(
      (chant) => chant.teamId != team.id || chant.status != 'canonical',
    )) {
      throw ArgumentError(
        'A club snapshot can contain only canonical chants for that team.',
      );
    }
    final timestamp = refreshedAt.toUtc();
    final identity = SavedTeamIdentity.fromTeam(team);
    final snapshots = [
      for (final chant in chantList) SavedChantSnapshot.fromChant(chant),
    ];
    return _update(uid, (current) {
      final clubs = Map<String, SavedClubSongbook>.from(current.clubSnapshots);
      final existing = clubs[team.id];
      clubs[team.id] = SavedClubSongbook(
        team: identity,
        savedAt: existing?.savedAt ?? timestamp,
        refreshedAt: timestamp,
        chants: snapshots,
      );
      return current.copyWith(clubSnapshots: clubs);
    });
  }

  Future<SavedSongbook> saveIndividual({
    required String uid,
    required Team team,
    required Chant chant,
    required DateTime refreshedAt,
  }) {
    if (chant.teamId != team.id) {
      throw ArgumentError('The chant and team IDs must match.');
    }
    final timestamp = refreshedAt.toUtc();
    final identity = SavedTeamIdentity.fromTeam(team);
    final snapshot = SavedChantSnapshot.fromChant(chant);
    return _update(uid, (current) {
      final individuals = Map<String, SavedIndividualChant>.from(
        current.individualSnapshots,
      );
      final existing = individuals[chant.id];
      individuals[chant.id] = SavedIndividualChant(
        team: identity,
        savedAt: existing?.savedAt ?? timestamp,
        refreshedAt: timestamp,
        chant: snapshot,
      );
      return current.copyWith(individualSnapshots: individuals);
    });
  }

  Future<SavedSongbook> reconcileChant({
    required String uid,
    required String chantId,
    required Chant? visibleChant,
    required Team? refreshedTeam,
    required DateTime refreshedAt,
  }) {
    if (visibleChant != null && visibleChant.id != chantId) {
      throw ArgumentError('The visible chant ID must match the target ID.');
    }
    return _update(uid, (current) {
      final clubs = Map<String, SavedClubSongbook>.from(current.clubSnapshots);
      final individuals = Map<String, SavedIndividualChant>.from(
        current.individualSnapshots,
      );
      final savedSnapshot = visibleChant == null
          ? null
          : SavedChantSnapshot.fromChant(visibleChant);

      for (final entry in clubs.entries.toList()) {
        final index = entry.value.chants.indexWhere(
          (chant) => chant.id == chantId,
        );
        if (index == -1) continue;
        final updated = entry.value.chants.toList();
        if (savedSnapshot == null || savedSnapshot.status != 'canonical') {
          updated.removeAt(index);
        } else {
          updated[index] = savedSnapshot;
        }
        clubs[entry.key] = entry.value.copyWith(chants: updated);
      }

      final existingIndividual = individuals[chantId];
      if (savedSnapshot == null) {
        individuals.remove(chantId);
      } else if (existingIndividual != null) {
        final team = refreshedTeam == null
            ? existingIndividual.team
            : SavedTeamIdentity.fromTeam(refreshedTeam);
        individuals[chantId] = existingIndividual.copyWith(
          team: team,
          refreshedAt: refreshedAt.toUtc(),
          chant: savedSnapshot,
        );
      }

      return current.copyWith(
        clubSnapshots: clubs,
        individualSnapshots: individuals,
      );
    });
  }

  Future<SavedSongbook> removeClub({
    required String uid,
    required String teamId,
  }) {
    return _update(uid, (current) {
      final clubs = Map<String, SavedClubSongbook>.from(current.clubSnapshots)
        ..remove(teamId);
      return current.copyWith(clubSnapshots: clubs);
    });
  }

  Future<SavedSongbook> removeIndividual({
    required String uid,
    required String chantId,
  }) {
    return _update(uid, (current) {
      final individuals = Map<String, SavedIndividualChant>.from(
        current.individualSnapshots,
      )..remove(chantId);
      return current.copyWith(individualSnapshots: individuals);
    });
  }

  Future<void> resetLocalCopy(String uid) {
    return _enqueue(() async {
      _requireAccess(uid);
      await _ensureInitialized();
      await _storage.delete(uid);
    });
  }

  Future<void> runAccountDeletion({
    required String uid,
    required Future<void> Function() deleteRemoteAccount,
  }) {
    return _enqueue(() async {
      _requireAccess(uid);
      await _ensureInitialized();
      final staged = await _storage.stageForAccountDeletion(uid);
      try {
        await deleteRemoteAccount();
      } catch (primaryError, primaryStack) {
        if (staged) {
          try {
            await _storage.restoreAfterAccountDeletionFailure(uid);
          } catch (cleanupError) {
            Error.throwWithStackTrace(
              SavedSongbookAccountDeletionException(
                primaryError: primaryError,
                cleanupError: cleanupError,
              ),
              primaryStack,
            );
          }
        }
        Error.throwWithStackTrace(primaryError, primaryStack);
      }
      if (staged) await _storage.finishAccountDeletion(uid);
    });
  }
}
