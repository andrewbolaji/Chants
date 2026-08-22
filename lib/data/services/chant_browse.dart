import 'package:chants/data/models/chant.dart';

enum ChantLabSort { top, newChants }

class ChantBrowseProjection {
  final List<Chant> songbook;
  final List<Chant> chantLab;
  final Set<String> unsupportedStatuses;

  const ChantBrowseProjection({
    required this.songbook,
    required this.chantLab,
    required this.unsupportedStatuses,
  });
}

/// Splits already-visible chants by their stored trust status.
///
/// Unknown statuses fail closed so a future state cannot accidentally inherit
/// either Terrace Proven or community presentation.
ChantBrowseProjection projectChants(Iterable<Chant> chants) {
  final songbook = <Chant>[];
  final chantLab = <Chant>[];
  final unsupportedStatuses = <String>{};

  for (final chant in chants) {
    switch (chant.status) {
      case 'canonical':
        songbook.add(chant);
      case 'community':
        chantLab.add(chant);
      default:
        unsupportedStatuses.add(chant.status);
    }
  }

  return ChantBrowseProjection(
    songbook: List.unmodifiable(songbook),
    chantLab: List.unmodifiable(chantLab),
    unsupportedStatuses: Set.unmodifiable(unsupportedStatuses),
  );
}

/// Score-descending total order used by Songbook and Chant Lab Top.
List<Chant> rankBrowseTop(Iterable<Chant> chants) {
  final sorted = List<Chant>.of(chants);
  sorted.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;

    final createdAt = a.createdAt.compareTo(b.createdAt);
    if (createdAt != 0) return createdAt;

    return a.id.compareTo(b.id);
  });
  return sorted;
}

/// Creation-descending total order used by Chant Lab New.
List<Chant> rankBrowseNew(Iterable<Chant> chants) {
  final sorted = List<Chant>.of(chants);
  sorted.sort((a, b) {
    final createdAt = b.createdAt.compareTo(a.createdAt);
    if (createdAt != 0) return createdAt;

    return a.id.compareTo(b.id);
  });
  return sorted;
}

bool isRisingChant(Chant chant, {required DateTime now}) {
  if (chant.status != 'community' || chant.score < 3) return false;
  if (chant.createdAt.isAfter(now)) return false;

  final oldestRisingDate = now.subtract(const Duration(days: 7));
  return !chant.createdAt.isBefore(oldestRisingDate);
}

/// Preserves survivor positions across live score changes for one route visit.
/// Removed IDs leave immediately and newly eligible IDs append in their current
/// deterministic rank order.
class StableChantOrder {
  final List<String> _orderedIds = [];
  bool _initialized = false;

  List<Chant> reconcile(Iterable<Chant> rankedChants) {
    final ranked = List<Chant>.of(rankedChants);
    final chantById = {for (final chant in ranked) chant.id: chant};

    if (!_initialized) {
      _orderedIds.addAll(ranked.map((chant) => chant.id));
      _initialized = true;
    } else {
      _orderedIds.removeWhere((id) => !chantById.containsKey(id));
      final existingIds = _orderedIds.toSet();
      for (final chant in ranked) {
        if (existingIds.add(chant.id)) _orderedIds.add(chant.id);
      }
    }

    return [for (final id in _orderedIds) chantById[id]!];
  }

  void reset() {
    _orderedIds.clear();
    _initialized = false;
  }
}
