import 'package:chants/data/models/player.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/player_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../services/chant_call_ups_test.dart' show chantFor;

class _Metadata extends Mock implements SnapshotMetadata {
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
  _Metadata(this.isFromCache, this.hasPendingWrites);
}

// Narrow SDK doubles exercise the real repository adapters without a live app.
// ignore: subtype_of_sealed_class
class _Document extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> value;
  _Document(this.id, this.value);
  @override
  Map<String, dynamic> data() => value;
}

class _Snapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final SnapshotMetadata metadata;
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  _Snapshot(this.metadata, this.docs);
}

// ignore: subtype_of_sealed_class, must_be_immutable
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {
  final List<QuerySnapshot<Map<String, dynamic>>> values;
  final filters = <(Object, Object?)>[];
  final orders = <(Object, bool)>[];
  final metadataFlags = <bool>[];
  _Collection(this.values);
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    filters.add((field, isEqualTo));
    return this;
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    orders.add((field, descending));
    return this;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    metadataFlags.add(includeMetadataChanges);
    return Stream.fromIterable(values);
  }
}

class _Firestore extends Mock implements FirebaseFirestore {
  final _Collection source;
  final paths = <String>[];
  _Firestore(this.source);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    paths.add(path);
    return source;
  }
}

void main() {
  test(
    'squad metadata survives cache, pending and server events with one query',
    () async {
      final player = Player(
        id: 'player',
        teamId: 'test-club',
        name: 'Test Player',
      );
      final source = _Collection([
        for (final flags in [(true, false), (false, true), (false, false)])
          _Snapshot(_Metadata(flags.$1, flags.$2), [
            _Document(player.id, player.toJson()),
          ]),
      ]);
      final firestore = _Firestore(source);
      final repository = PlayerRepository(firestore: firestore);
      final snapshots = await repository
          .teamBrowseStream(teamId: 'test-club')
          .toList();
      expect(snapshots.map((s) => (s.isFromCache, s.hasPendingWrites)), [
        (true, false),
        (false, true),
        (false, false),
      ]);
      expect(snapshots.last.players.single.id, 'player');
      expect(() => snapshots.last.players.clear(), throwsUnsupportedError);
      expect(source.filters, [('teamId', 'test-club')]);
      expect(source.metadataFlags, [true]);
      expect(firestore.paths, ['players']);
      final legacy = await repository
          .playersForTeamStream(teamId: 'test-club')
          .last;
      expect(legacy.single.name, 'Test Player');
    },
  );

  test(
    'team and player chant adapters preserve metadata and visibility query',
    () async {
      for (final byPlayer in [false, true]) {
        final chant = chantFor('player');
        final source = _Collection([
          for (final flags in [(true, false), (false, true), (false, false)])
            _Snapshot(_Metadata(flags.$1, flags.$2), [
              _Document(chant.id, chant.toJson()),
            ]),
        ]);
        final repository = ChantRepository(firestore: _Firestore(source));
        final snapshots =
            await (byPlayer
                    ? repository.playerBrowseStream(playerId: 'player')
                    : repository.teamBrowseStream(teamId: 'test-club'))
                .toList();
        expect(snapshots.map((s) => (s.isFromCache, s.hasPendingWrites)), [
          (true, false),
          (false, true),
          (false, false),
        ]);
        expect(snapshots.last.chants.single.id, chant.id);
        expect(source.filters, [
          ('hidden', false),
          ('removed', false),
          byPlayer ? ('playerId', 'player') : ('teamId', 'test-club'),
        ]);
        expect(source.orders, byPlayer ? [] : [('score', true)]);
        expect(source.metadataFlags, [true]);
      }
    },
  );
}
