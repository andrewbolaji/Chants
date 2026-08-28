import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:chants/presentation/create/perform_chant_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan';
}

class _Selector extends PerformanceMediaSelector {
  SelectedPerformanceMedia? selected;
  PerformanceMediaSelectionException? failure;

  @override
  Future<SelectedPerformanceMedia?> recoverInterruptedSelection() async => null;

  @override
  Future<SelectedPerformanceMedia?> record() => _select();

  @override
  Future<SelectedPerformanceMedia?> chooseFromLibrary() => _select();

  Future<SelectedPerformanceMedia?> _select() async {
    final error = failure;
    if (error != null) throw error;
    return selected;
  }
}

final _chant = Chant(
  id: 'chant-1',
  title: 'Super Saka',
  sportId: 'football',
  competitionId: 'premier-league',
  teamId: 'arsenal',
  playerId: 'saka',
  subjectTag: 'player',
  lyrics: 'Super Saka every week',
  tuneName: 'Traditional tune',
  mediaType: 'none',
  status: 'community',
  chantType: 'sincere',
  origin: ChantOrigin.originalIdea,
  createdBy: 'fan',
  createdAt: DateTime.utc(2026, 8, 28),
  updatedAt: DateTime.utc(2026, 8, 28),
);

CreatorProfile _creator() {
  final now = DateTime.utc(2026, 8, 28);
  return CreatorProfile(
    id: 'fan',
    handle: 'northbankleo',
    displayName: 'North Bank Leo',
    bio: '',
    followerCount: 0,
    followingCount: 0,
    performanceCount: 0,
    likeCount: 0,
    shareCount: 0,
    hidden: false,
    removed: false,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap({
  required _Selector selector,
  required PerformanceDraftRepository repository,
  CreatorProfile? creator,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_User())),
      creatorProfileProvider(
        'fan',
      ).overrideWith((ref) => Stream.value(creator)),
      performanceMediaSelectorProvider.overrideWithValue(selector),
      performanceDraftRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: PerformChantScreen(chant: _chant),
    ),
  );
}

PerformanceDraftRepository _repository({
  required List<(String, Map<String, Object>)> calls,
  void Function(PerformanceDraftTicket, SelectedPerformanceMedia, String)?
  onUpload,
}) {
  return PerformanceDraftRepository(
    invoker: (callable, payload) async {
      calls.add((callable, payload));
      if (callable == 'createPerformanceDraft') {
        return {
          'draftId': 'draft-1',
          'uploadPath': 'performance-staging/fan/draft-1/source',
        };
      }
      return const {};
    },
    uploader: ({required ticket, required media, required ownerId}) {
      onUpload?.call(ticket, media, ownerId);
      return PerformanceUploadHandle(
        completion: Future.value(),
        progress: Stream.value(1),
        cancel: () async => true,
      );
    },
    ownerDraftsLoader: (_) => Stream.value(const []),
    reviewQueueLoader: () => Stream.value(const []),
  );
}

void main() {
  testWidgets('library selection uploads once and ends in private review', (
    tester,
  ) async {
    final selector = _Selector()
      ..selected = const SelectedPerformanceMedia(
        filePath: '/tmp/take.mp4',
        fileName: 'take.mp4',
        contentType: 'video/mp4',
        sizeBytes: 1024,
        durationMs: 12500,
      );
    final calls = <(String, Map<String, Object>)>[];
    String? uploadOwner;
    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(
          calls: calls,
          onUpload: (_, _, ownerId) => uploadOwner = ownerId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POSTING AS @northbankleo'), findsOneWidget);
    await tester.tap(find.text('CHOOSE A VIDEO'));
    await tester.pumpAndSettle();
    expect(find.text('take.mp4'), findsOneWidget);
    expect(find.textContaining('12.5 seconds'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Caption (optional)'),
      'First take.',
    );
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pumpAndSettle();

    expect(find.text('IN THE REVIEW QUEUE'), findsOneWidget);
    expect(uploadOwner, 'fan');
    expect(calls.map((call) => call.$1), [
      'createPerformanceDraft',
      'submitPerformanceDraft',
    ]);
    expect(calls.first.$2['chantId'], 'chant-1');
  });

  testWidgets('selection explains a video over 30 seconds', (tester) async {
    final selector = _Selector()
      ..failure = const PerformanceMediaSelectionException(
        PerformanceMediaSelectionFailure.tooLong,
      );
    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(calls: []),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('RECORD A TAKE'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a video that is 30 seconds or shorter.'),
      findsOneWidget,
    );
  });

  testWidgets('public creator identity is required before upload', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        selector: _Selector(),
        repository: _repository(calls: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('CREATE YOUR PUBLIC CREATOR PROFILE FIRST'),
      findsOneWidget,
    );
    expect(find.text('SEND FOR REVIEW'), findsNothing);
  });
}
