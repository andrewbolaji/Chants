import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/team.dart';

class SavedSongbookFormatException implements Exception {
  final String message;

  const SavedSongbookFormatException(this.message);

  @override
  String toString() => 'SavedSongbookFormatException: $message';
}

class UnsupportedSavedSongbookVersion implements Exception {
  final int version;

  const UnsupportedSavedSongbookVersion(this.version);

  @override
  String toString() => 'UnsupportedSavedSongbookVersion: $version';
}

class SavedSongbookLimitException implements Exception {
  final String message;

  const SavedSongbookLimitException(this.message);

  @override
  String toString() => 'SavedSongbookLimitException: $message';
}

class SavedTeamIdentity {
  final String id;
  final String sportId;
  final String competitionId;
  final String name;

  const SavedTeamIdentity({
    required this.id,
    required this.sportId,
    required this.competitionId,
    required this.name,
  });

  factory SavedTeamIdentity.fromTeam(Team team) {
    return SavedTeamIdentity(
      id: team.id,
      sportId: team.sportId,
      competitionId: team.competitionId,
      name: team.name,
    );
  }

  factory SavedTeamIdentity.fromJson(Object? value) {
    final json = _objectMap(value, 'team');
    return SavedTeamIdentity(
      id: _requiredString(json, 'id'),
      sportId: _requiredString(json, 'sportId'),
      competitionId: _requiredString(json, 'competitionId'),
      name: _requiredString(json, 'name'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sportId': sportId,
    'competitionId': competitionId,
    'name': name,
  };
}

class SavedChantSnapshot {
  final String id;
  final String teamId;
  final String? playerId;
  final String subjectTag;
  final String title;
  final String lyrics;
  final String tuneName;
  final String? contextNotes;
  final String status;
  final ChantOrigin? origin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChantVariation> variations;

  SavedChantSnapshot({
    required this.id,
    required this.teamId,
    this.playerId,
    required this.subjectTag,
    required this.title,
    required this.lyrics,
    required this.tuneName,
    this.contextNotes,
    required this.status,
    this.origin,
    required this.createdAt,
    required this.updatedAt,
    Iterable<ChantVariation> variations = const [],
  }) : variations = List.unmodifiable(variations) {
    if (!Chant.validSubjectTags.contains(subjectTag)) {
      throw SavedSongbookFormatException(
        'Unsupported subject tag for chant $id.',
      );
    }
    if (!Chant.validStatuses.contains(status)) {
      throw SavedSongbookFormatException('Unsupported status for chant $id.');
    }
  }

  factory SavedChantSnapshot.fromChant(Chant chant) {
    return SavedChantSnapshot(
      id: chant.id,
      teamId: chant.teamId,
      playerId: chant.playerId,
      subjectTag: chant.subjectTag,
      title: chant.title,
      lyrics: chant.lyrics,
      tuneName: chant.tuneName,
      contextNotes: chant.contextNotes,
      status: chant.status,
      origin: chant.origin,
      createdAt: chant.createdAt.toUtc(),
      updatedAt: chant.updatedAt.toUtc(),
      variations: chant.variations,
    );
  }

  factory SavedChantSnapshot.fromJson(Object? value) {
    final json = _objectMap(value, 'chant');
    final rawOrigin = json['origin'];
    final origin = rawOrigin == null
        ? null
        : ChantOrigin.fromFirestoreValue(rawOrigin);
    if (rawOrigin != null && origin == null) {
      throw const SavedSongbookFormatException('Invalid chant origin.');
    }

    final rawVariations = json['variations'];
    if (rawVariations is! List) {
      throw const SavedSongbookFormatException(
        'Chant variations must be a list.',
      );
    }

    return SavedChantSnapshot(
      id: _requiredString(json, 'id'),
      teamId: _requiredString(json, 'teamId'),
      playerId: _optionalString(json, 'playerId'),
      subjectTag: _requiredString(json, 'subjectTag'),
      title: _requiredString(json, 'title'),
      lyrics: _requiredString(json, 'lyrics'),
      tuneName: _requiredString(json, 'tuneName'),
      contextNotes: _optionalString(json, 'contextNotes'),
      status: _requiredString(json, 'status'),
      origin: origin,
      createdAt: _utcDate(json, 'createdAt'),
      updatedAt: _utcDate(json, 'updatedAt'),
      variations: [for (final item in rawVariations) _variationFromJson(item)],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'playerId': playerId,
    'subjectTag': subjectTag,
    'title': title,
    'lyrics': lyrics,
    'tuneName': tuneName,
    'contextNotes': contextNotes,
    'status': status,
    'origin': origin?.firestoreValue,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'variations': [for (final variation in variations) variation.toJson()],
  };
}

class SavedClubSongbook {
  final SavedTeamIdentity team;
  final DateTime savedAt;
  final DateTime refreshedAt;
  final List<SavedChantSnapshot> chants;

  SavedClubSongbook({
    required this.team,
    required this.savedAt,
    required this.refreshedAt,
    required Iterable<SavedChantSnapshot> chants,
  }) : chants = List.unmodifiable(chants) {
    final ids = <String>{};
    for (final chant in this.chants) {
      if (chant.teamId != team.id || chant.status != 'canonical') {
        throw SavedSongbookFormatException(
          'Club ${team.id} contains an invalid chant snapshot.',
        );
      }
      if (!ids.add(chant.id)) {
        throw SavedSongbookFormatException(
          'Club ${team.id} contains duplicate chant ${chant.id}.',
        );
      }
    }
  }

  factory SavedClubSongbook.fromJson(Object? value) {
    final json = _objectMap(value, 'club snapshot');
    final rawChants = json['chants'];
    if (rawChants is! List) {
      throw const SavedSongbookFormatException(
        'Club snapshot chants must be a list.',
      );
    }
    return SavedClubSongbook(
      team: SavedTeamIdentity.fromJson(json['team']),
      savedAt: _utcDate(json, 'savedAt'),
      refreshedAt: _utcDate(json, 'refreshedAt'),
      chants: [for (final item in rawChants) SavedChantSnapshot.fromJson(item)],
    );
  }

  Map<String, dynamic> toJson() => {
    'team': team.toJson(),
    'savedAt': savedAt.toUtc().toIso8601String(),
    'refreshedAt': refreshedAt.toUtc().toIso8601String(),
    'chants': [for (final chant in chants) chant.toJson()],
  };

  SavedClubSongbook copyWith({
    SavedTeamIdentity? team,
    DateTime? savedAt,
    DateTime? refreshedAt,
    Iterable<SavedChantSnapshot>? chants,
  }) {
    return SavedClubSongbook(
      team: team ?? this.team,
      savedAt: savedAt ?? this.savedAt,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      chants: chants ?? this.chants,
    );
  }
}

class SavedIndividualChant {
  final SavedTeamIdentity team;
  final DateTime savedAt;
  final DateTime refreshedAt;
  final SavedChantSnapshot chant;

  SavedIndividualChant({
    required this.team,
    required this.savedAt,
    required this.refreshedAt,
    required this.chant,
  }) {
    if (chant.teamId != team.id) {
      throw SavedSongbookFormatException(
        'Individual chant ${chant.id} has a mismatched team.',
      );
    }
  }

  factory SavedIndividualChant.fromJson(Object? value) {
    final json = _objectMap(value, 'individual snapshot');
    return SavedIndividualChant(
      team: SavedTeamIdentity.fromJson(json['team']),
      savedAt: _utcDate(json, 'savedAt'),
      refreshedAt: _utcDate(json, 'refreshedAt'),
      chant: SavedChantSnapshot.fromJson(json['chant']),
    );
  }

  Map<String, dynamic> toJson() => {
    'team': team.toJson(),
    'savedAt': savedAt.toUtc().toIso8601String(),
    'refreshedAt': refreshedAt.toUtc().toIso8601String(),
    'chant': chant.toJson(),
  };

  SavedIndividualChant copyWith({
    SavedTeamIdentity? team,
    DateTime? savedAt,
    DateTime? refreshedAt,
    SavedChantSnapshot? chant,
  }) {
    return SavedIndividualChant(
      team: team ?? this.team,
      savedAt: savedAt ?? this.savedAt,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      chant: chant ?? this.chant,
    );
  }
}

class SavedSongbook {
  static const schemaVersion = 1;
  static const maxUniqueChants = 500;
  static const maxEncodedBytes = 2 * 1024 * 1024;

  final Map<String, SavedClubSongbook> clubSnapshots;
  final Map<String, SavedIndividualChant> individualSnapshots;

  SavedSongbook({
    Map<String, SavedClubSongbook> clubSnapshots = const {},
    Map<String, SavedIndividualChant> individualSnapshots = const {},
  }) : clubSnapshots = Map.unmodifiable(clubSnapshots),
       individualSnapshots = Map.unmodifiable(individualSnapshots) {
    for (final entry in this.clubSnapshots.entries) {
      if (entry.key != entry.value.team.id) {
        throw const SavedSongbookFormatException(
          'Club snapshot map key does not match its team ID.',
        );
      }
    }
    for (final entry in this.individualSnapshots.entries) {
      if (entry.key != entry.value.chant.id) {
        throw const SavedSongbookFormatException(
          'Individual snapshot map key does not match its chant ID.',
        );
      }
    }
    if (uniqueChantIds.length > maxUniqueChants) {
      throw const SavedSongbookLimitException(
        'Saved Songbook cannot exceed 500 unique chants.',
      );
    }
  }

  factory SavedSongbook.empty() => SavedSongbook();

  factory SavedSongbook.fromJson(Object? value) {
    final json = _objectMap(value, 'songbook');
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const SavedSongbookFormatException(
        'Saved Songbook schema version is missing.',
      );
    }
    if (version != schemaVersion) {
      throw UnsupportedSavedSongbookVersion(version);
    }

    final rawClubs = _objectMap(json['clubSnapshots'], 'club snapshots');
    final rawIndividuals = _objectMap(
      json['individualSnapshots'],
      'individual snapshots',
    );
    return SavedSongbook(
      clubSnapshots: {
        for (final entry in rawClubs.entries)
          entry.key: SavedClubSongbook.fromJson(entry.value),
      },
      individualSnapshots: {
        for (final entry in rawIndividuals.entries)
          entry.key: SavedIndividualChant.fromJson(entry.value),
      },
    );
  }

  Set<String> get uniqueChantIds => {
    ...individualSnapshots.keys,
    for (final club in clubSnapshots.values)
      for (final chant in club.chants) chant.id,
  };

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'clubSnapshots': {
      for (final entry in clubSnapshots.entries)
        entry.key: entry.value.toJson(),
    },
    'individualSnapshots': {
      for (final entry in individualSnapshots.entries)
        entry.key: entry.value.toJson(),
    },
  };

  SavedSongbook copyWith({
    Map<String, SavedClubSongbook>? clubSnapshots,
    Map<String, SavedIndividualChant>? individualSnapshots,
  }) {
    return SavedSongbook(
      clubSnapshots: clubSnapshots ?? this.clubSnapshots,
      individualSnapshots: individualSnapshots ?? this.individualSnapshots,
    );
  }
}

Map<String, dynamic> _objectMap(Object? value, String field) {
  if (value is! Map) {
    throw SavedSongbookFormatException('$field must be an object.');
  }
  try {
    return Map<String, dynamic>.from(value);
  } catch (_) {
    throw SavedSongbookFormatException('$field has a non-string key.');
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw SavedSongbookFormatException('$key must be a non-empty string.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw SavedSongbookFormatException('$key must be null or non-empty.');
  }
  return value;
}

DateTime _utcDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || !value.endsWith('Z')) {
    throw SavedSongbookFormatException('$key must be a UTC timestamp.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw SavedSongbookFormatException('$key is not a valid UTC timestamp.');
  }
  return parsed;
}

ChantVariation _variationFromJson(Object? value) {
  final json = _objectMap(value, 'variation');
  return ChantVariation(
    label: _requiredString(json, 'label'),
    lyric: _requiredString(json, 'lyric'),
    contextNote: _optionalString(json, 'contextNote'),
  );
}
