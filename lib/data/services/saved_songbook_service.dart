import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/saved_songbook_repository.dart';
import 'package:chants/data/repositories/team_repository.dart';
import 'package:chants/data/services/chant_browse.dart';

class SavedChantNotVisibleException implements Exception {
  final String chantId;

  const SavedChantNotVisibleException(this.chantId);

  @override
  String toString() => 'SavedChantNotVisibleException: $chantId';
}

class SavedTeamUnavailableException implements Exception {
  final String teamId;

  const SavedTeamUnavailableException(this.teamId);

  @override
  String toString() => 'SavedTeamUnavailableException: $teamId';
}

class SavedSongbookMutationResult {
  final SavedSongbook songbook;
  final int chantCount;
  final bool removed;

  const SavedSongbookMutationResult({
    required this.songbook,
    required this.chantCount,
    this.removed = false,
  });
}

class SavedSongbookOverview {
  final List<SavedClubSongbook> clubs;
  final List<SavedIndividualChant> individualChants;

  const SavedSongbookOverview({
    required this.clubs,
    required this.individualChants,
  });
}

SavedSongbookOverview projectSavedSongbook(SavedSongbook songbook) {
  final clubs = songbook.clubSnapshots.values.toList()
    ..sort((a, b) {
      final byName = a.team.name.toLowerCase().compareTo(
        b.team.name.toLowerCase(),
      );
      return byName != 0 ? byName : a.team.id.compareTo(b.team.id);
    });
  final clubOwnedIds = {
    for (final club in clubs)
      for (final chant in club.chants) chant.id,
  };
  final individualChants =
      songbook.individualSnapshots.values
          .where((entry) => !clubOwnedIds.contains(entry.chant.id))
          .toList()
        ..sort((a, b) {
          final byRefresh = b.refreshedAt.compareTo(a.refreshedAt);
          return byRefresh != 0 ? byRefresh : a.chant.id.compareTo(b.chant.id);
        });
  return SavedSongbookOverview(
    clubs: List.unmodifiable(clubs),
    individualChants: List.unmodifiable(individualChants),
  );
}

class SavedSongbookService {
  final SavedSongbookRepository _savedRepository;
  final ChantRepository _chantRepository;
  final TeamRepository _teamRepository;
  final DateTime Function() _now;

  SavedSongbookService({
    required SavedSongbookRepository savedRepository,
    required ChantRepository chantRepository,
    required TeamRepository teamRepository,
    DateTime Function()? now,
  }) : _savedRepository = savedRepository,
       _chantRepository = chantRepository,
       _teamRepository = teamRepository,
       _now = now ?? DateTime.now;

  Future<SavedSongbookMutationResult> saveClubFromFreshBrowse({
    required String uid,
    required Team team,
    required Iterable<Chant> songbookChants,
  }) async {
    final ranked = rankBrowseTop(songbookChants).toList();
    if (ranked.isEmpty) {
      throw ArgumentError('An empty club Songbook cannot be saved initially.');
    }
    final songbook = await _savedRepository.saveClub(
      uid: uid,
      team: team,
      chants: ranked,
      refreshedAt: _now().toUtc(),
    );
    return SavedSongbookMutationResult(
      songbook: songbook,
      chantCount: ranked.length,
    );
  }

  Future<SavedSongbookMutationResult> refreshClub({
    required String uid,
    required String teamId,
  }) async {
    final current = await _savedRepository.load(uid);
    final existing = current.clubSnapshots[teamId];
    if (existing == null) {
      throw ArgumentError('The club is not saved on this device.');
    }
    final visible = await _chantRepository.visibleChantsForTeamFromServer(
      teamId: teamId,
    );
    Team? refreshedTeam;
    try {
      refreshedTeam = await _teamRepository.getTeamFromServer(teamId);
    } catch (_) {
      // Chant visibility is the required refresh boundary. A team metadata
      // failure keeps the last complete public identity.
    }
    final team =
        refreshedTeam ??
        Team(
          id: existing.team.id,
          sportId: existing.team.sportId,
          competitionId: existing.team.competitionId,
          name: existing.team.name,
        );
    final ranked = rankBrowseTop(
      visible.where((chant) => chant.status == 'canonical'),
    );
    final songbook = await _savedRepository.saveClub(
      uid: uid,
      team: team,
      chants: ranked,
      refreshedAt: _now().toUtc(),
    );
    return SavedSongbookMutationResult(
      songbook: songbook,
      chantCount: ranked.length,
    );
  }

  Future<SavedSongbookMutationResult> saveIndividual({
    required String uid,
    required String chantId,
    required String teamId,
    Team? knownTeam,
  }) async {
    final visible = await _chantRepository.visibleChantsForTeamFromServer(
      teamId: teamId,
    );
    final chant = _findById(visible, chantId);
    if (chant == null) throw SavedChantNotVisibleException(chantId);
    final team = knownTeam ?? await _teamRepository.getTeamFromServer(teamId);
    if (team == null) throw SavedTeamUnavailableException(teamId);
    final songbook = await _savedRepository.saveIndividual(
      uid: uid,
      team: team,
      chant: chant,
      refreshedAt: _now().toUtc(),
    );
    return SavedSongbookMutationResult(songbook: songbook, chantCount: 1);
  }

  Future<SavedSongbookMutationResult> refreshIndividual({
    required String uid,
    required String chantId,
  }) async {
    final current = await _savedRepository.load(uid);
    final existing = current.individualSnapshots[chantId];
    if (existing == null) {
      throw ArgumentError('The chant is not saved individually.');
    }
    final visible = await _chantRepository.visibleChantsForTeamFromServer(
      teamId: existing.team.id,
    );
    final chant = _findById(visible, chantId);
    Team? refreshedTeam;
    if (chant != null) {
      try {
        refreshedTeam = await _teamRepository.getTeamFromServer(
          existing.team.id,
        );
      } catch (_) {
        // Keep the prior team identity when only metadata refresh fails.
      }
    }
    final songbook = await _savedRepository.reconcileChant(
      uid: uid,
      chantId: chantId,
      visibleChant: chant,
      refreshedTeam: refreshedTeam,
      refreshedAt: _now().toUtc(),
    );
    return SavedSongbookMutationResult(
      songbook: songbook,
      chantCount: chant == null ? 0 : 1,
      removed: chant == null,
    );
  }

  Chant? _findById(Iterable<Chant> chants, String id) {
    for (final chant in chants) {
      if (chant.id == id) return chant;
    }
    return null;
  }
}
