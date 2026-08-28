import 'package:chants/data/models/performance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum PerformanceFeedFilter { rising, newest, terrace, following }

class PerformancePage {
  final List<Performance> performances;
  final Object? cursor;
  final bool hasMore;

  PerformancePage({
    required Iterable<Performance> performances,
    this.cursor,
    required this.hasMore,
  }) : performances = List.unmodifiable(performances);
}

typedef PerformancePageLoader =
    Future<PerformancePage> Function(
      PerformanceFeedFilter filter,
      Object? cursor,
    );
typedef FollowingPerformancePageLoader =
    Future<PerformancePage> Function(List<String> creatorIds, Object? cursor);
typedef PerformanceLoader = Future<Performance?> Function(String performanceId);

class PerformanceRepository {
  final FirebaseFirestore? _firestoreOverride;
  final PerformancePageLoader? _pageLoader;
  final FollowingPerformancePageLoader? _loadFollowingPage;
  final PerformanceLoader? _performanceLoader;
  final Future<Uri> Function(String performanceId)? _playbackResolver;
  final DateTime Function() _now;

  PerformanceRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    PerformancePageLoader? pageLoader,
    FollowingPerformancePageLoader? followingPageLoader,
    PerformanceLoader? performanceLoader,
    Future<Uri> Function(String performanceId)? playbackResolver,
    DateTime Function()? now,
  }) : _firestoreOverride = firestore,
       _pageLoader = pageLoader,
       _loadFollowingPage = followingPageLoader,
       // Keep the public injection name descriptive for tests and callers.
       // ignore: prefer_initializing_formals
       _performanceLoader = performanceLoader,
       _playbackResolver =
           playbackResolver ??
           (pageLoader == null
               ? _firebasePlaybackResolver(
                   functions ??
                       FirebaseFunctions.instanceFor(region: 'europe-west2'),
                 )
               : null),
       _now = now ?? DateTime.now;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static const pageSize = 10;

  static Future<Uri> Function(String performanceId) _firebasePlaybackResolver(
    FirebaseFunctions functions,
  ) {
    return (performanceId) async {
      final result = await functions
          .httpsCallable('resolvePerformancePlayback')
          .call({'performanceId': performanceId});
      final data = result.data;
      if (data is! Map || data['url'] is! String) {
        throw const FormatException('Playback destination is unavailable.');
      }
      final uri = Uri.tryParse(data['url'] as String);
      if (uri == null || uri.scheme != 'https') {
        throw const FormatException('Playback destination is unavailable.');
      }
      return uri;
    };
  }

  Future<Uri> resolvePlayback(String performanceId) async {
    final resolver = _playbackResolver;
    if (resolver == null) {
      throw StateError('No playback resolver is configured.');
    }
    return resolver(performanceId);
  }

  Future<Performance?> fetchVisibleById(String performanceId) async {
    if (performanceId.isEmpty) {
      throw ArgumentError.value(performanceId, 'performanceId');
    }
    final loader = _performanceLoader;
    if (loader != null) return loader(performanceId);
    final snapshot = await _firestore
        .collection('performances')
        .doc(performanceId)
        .get();
    if (!snapshot.exists) return null;
    final performance = Performance.fromFirestore(snapshot);
    return performance.isVisible ? performance : null;
  }

  Query<Map<String, dynamic>> _visibleQuery(PerformanceFeedFilter filter) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('performances')
        .where('schemaVersion', isEqualTo: Performance.schemaVersion)
        .where('publicationState', isEqualTo: 'approved')
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .where('sourceChantVisible', isEqualTo: true)
        .where('sourceCreatorVisible', isEqualTo: true);

    return switch (filter) {
      PerformanceFeedFilter.rising =>
        query
            .where(
              'rankingWeek',
              isEqualTo: performanceRankingWeek(_now().toUtc()),
            )
            .orderBy('weeklyUniqueSharerCount', descending: true)
            .orderBy('weeklyLikeCount', descending: true)
            .orderBy('weeklyQualifiedViewCount', descending: true)
            .orderBy('createdAt', descending: true),
      PerformanceFeedFilter.newest => query.orderBy(
        'createdAt',
        descending: true,
      ),
      PerformanceFeedFilter.terrace =>
        query
            .where('chantStatus', isEqualTo: 'canonical')
            .orderBy('createdAt', descending: true),
      PerformanceFeedFilter.following => throw StateError(
        'Following requires an explicit creator allowlist.',
      ),
    };
  }

  Future<PerformancePage> fetchPage({
    required PerformanceFeedFilter filter,
    Object? cursor,
  }) async {
    final loader = _pageLoader;
    if (loader != null) return loader(filter, cursor);

    var query = _visibleQuery(filter);
    if (cursor != null) {
      if (cursor is! DocumentSnapshot<Map<String, dynamic>>) {
        throw ArgumentError.value(cursor, 'cursor', 'Invalid page cursor.');
      }
      query = query.startAfterDocument(cursor);
    }
    final snapshot = await query.limit(pageSize).get();
    return PerformancePage(
      performances: snapshot.docs.map(Performance.fromFirestore),
      cursor: snapshot.docs.isEmpty ? cursor : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  Future<PerformancePage> fetchFollowingPage({
    required List<String> creatorIds,
    Object? cursor,
  }) async {
    if (creatorIds.isEmpty) {
      return PerformancePage(performances: const [], hasMore: false);
    }
    if (creatorIds.length > 30 || creatorIds.any((id) => id.isEmpty)) {
      throw ArgumentError.value(creatorIds, 'creatorIds');
    }
    final loader = _loadFollowingPage;
    if (loader != null) return loader(List.unmodifiable(creatorIds), cursor);

    Query<Map<String, dynamic>> query = _firestore
        .collection('performances')
        .where('schemaVersion', isEqualTo: Performance.schemaVersion)
        .where('publicationState', isEqualTo: 'approved')
        .where('hidden', isEqualTo: false)
        .where('removed', isEqualTo: false)
        .where('sourceChantVisible', isEqualTo: true)
        .where('sourceCreatorVisible', isEqualTo: true)
        .where('creatorId', whereIn: creatorIds)
        .orderBy('createdAt', descending: true);
    if (cursor != null) {
      if (cursor is! DocumentSnapshot<Map<String, dynamic>>) {
        throw ArgumentError.value(cursor, 'cursor', 'Invalid page cursor.');
      }
      query = query.startAfterDocument(cursor);
    }
    final snapshot = await query.limit(pageSize).get();
    return PerformancePage(
      performances: snapshot.docs.map(Performance.fromFirestore),
      cursor: snapshot.docs.isEmpty ? cursor : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }
}
