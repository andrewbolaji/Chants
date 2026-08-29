import 'package:chants/data/models/performance.dart';
import 'package:chants/data/repositories/performance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Performance _performance(String id) {
  final now = DateTime.utc(2026, 8, 27);
  return Performance(
    id: id,
    chantId: 'chant-$id',
    chantTitle: 'A chant',
    teamId: 'arsenal',
    teamName: 'Arsenal',
    chantStatus: 'community',
    creatorId: 'creator-1',
    creatorHandle: 'northbankleo',
    creatorDisplayName: 'North Bank Leo',
    caption: '',
    mediaPath: 'performance-media/$id/source',
    durationMs: 12000,
    publicationState: PerformancePublicationState.approved,
    rankingWeek: '2026-08-24',
    createdAt: now,
    approvedAt: now,
    updatedAt: now,
  );
}

void main() {
  test('passes the selected filter and cursor to the page boundary', () async {
    final calls = <(PerformanceFeedFilter, Object?)>[];
    final repository = PerformanceRepository(
      pageLoader: (filter, cursor) async {
        calls.add((filter, cursor));
        return PerformancePage(
          performances: [_performance('one')],
          cursor: 'next',
          hasMore: true,
        );
      },
    );

    final page = await repository.fetchPage(
      filter: PerformanceFeedFilter.terrace,
      cursor: 'cursor-1',
    );

    expect(calls, [(PerformanceFeedFilter.terrace, 'cursor-1')]);
    expect(page.performances.single.id, 'one');
    expect(page.cursor, 'next');
    expect(page.hasMore, isTrue);
  });

  test('page results are immutable', () async {
    final source = [_performance('one')];
    final page = PerformancePage(performances: source, hasMore: false);
    source.add(_performance('two'));

    expect(page.performances, hasLength(1));
    expect(
      () => page.performances.add(_performance('three')),
      throwsUnsupportedError,
    );
  });

  test(
    'playback resolver returns only the injected current destination',
    () async {
      final calls = <String>[];
      final repository = PerformanceRepository(
        pageLoader: (_, _) async =>
            PerformancePage(performances: const [], hasMore: false),
        playbackResolver: (performanceId) async {
          calls.add(performanceId);
          return Uri.https('signed.example.test', '/media');
        },
      );

      final destination = await repository.resolvePlayback('performance-1');

      expect(calls, ['performance-1']);
      expect(destination.host, 'signed.example.test');
    },
  );

  test(
    'loads a single current performance for activity destinations',
    () async {
      final calls = <String>[];
      final repository = PerformanceRepository(
        pageLoader: (_, _) async =>
            PerformancePage(performances: const [], hasMore: false),
        performanceLoader: (performanceId) async {
          calls.add(performanceId);
          return _performance(performanceId);
        },
      );

      final performance = await repository.fetchVisibleById('performance-1');

      expect(calls, ['performance-1']);
      expect(performance?.id, 'performance-1');
      await expectLater(repository.fetchVisibleById(''), throwsArgumentError);
    },
  );
}
