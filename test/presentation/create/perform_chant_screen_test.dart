import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:chants/presentation/create/perform_chant_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  Object? creationFailure,
  Object? submissionFailure,
  void Function(PerformanceDraftTicket, SelectedPerformanceMedia, String)?
  onUpload,
}) {
  return PerformanceDraftRepository(
    invoker: (callable, payload) async {
      calls.add((callable, payload));
      if (callable == 'createPerformanceDraft') {
        if (creationFailure != null) throw creationFailure;
        return {
          'draftId': 'draft-1',
          'uploadPath': 'performance-staging/fan/draft-1/source',
        };
      }
      if (callable == 'submitPerformanceDraft' && submissionFailure != null) {
        throw submissionFailure;
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
  for (final reason in [
    'maintenance',
    'upload-in-progress',
    'upload-expired',
    'upload-needs-recovery',
  ]) {
    testWidgets(
      'upload permission recovery explains $reason without losing selection',
      (tester) async {
        final selector = _Selector()
          ..selected = const SelectedPerformanceMedia(
            filePath: '/tmp/take.mp4',
            fileName: 'take.mp4',
            contentType: 'video/mp4',
            sizeBytes: 1024,
            durationMs: 12500,
          );
        final failure = FirebaseFunctionsException(
          code: reason == 'maintenance' ? 'unavailable' : 'failed-precondition',
          message: 'Synthetic upload permission response.',
          details: {'reason': reason},
        );
        final calls = <(String, Map<String, Object>)>[];
        await tester.pumpWidget(
          _wrap(
            selector: selector,
            creator: _creator(),
            repository: _repository(
              calls: calls,
              creationFailure: reason == 'upload-expired' ? null : failure,
              submissionFailure: reason == 'upload-expired' ? failure : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('CHOOSE A VIDEO'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SEND FOR REVIEW'));
        await tester.pumpAndSettle();
        expect(find.text('take.mp4'), findsOneWidget);
        expect(find.text('IN THE REVIEW QUEUE'), findsNothing);
        expect(
          find.textContaining(switch (reason) {
            'maintenance' => 'temporarily paused',
            'upload-in-progress' => 'Another upload is in progress',
            'upload-needs-recovery' => 'Your upload permission needs attention',
            _ => 'Upload permission expired',
          }),
          findsOneWidget,
        );
        if (reason == 'upload-expired') {
          await tester.scrollUntilVisible(
            find.text('CANCEL UPLOAD'),
            160,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.text('CANCEL UPLOAD'));
          await tester.pumpAndSettle();
          expect(calls.last.$1, 'cancelPerformanceDraft');
          expect(find.text('UPLOAD CANCELLED'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('paused upload stays readable at narrow enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final selector = _Selector()
      ..selected = const SelectedPerformanceMedia(
        filePath: '/tmp/take.mp4',
        fileName: 'take.mp4',
        contentType: 'video/mp4',
        sizeBytes: 1024,
        durationMs: 12500,
      );
    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(
          calls: [],
          creationFailure: FirebaseFunctionsException(
            code: 'unavailable',
            message: 'Synthetic pause.',
            details: {'reason': 'maintenance'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tapVisible(String label) async {
      final target = find.text(label).hitTestable();
      for (
        var attempt = 0;
        target.evaluate().isEmpty && attempt < 20;
        attempt++
      ) {
        // Drag the ListView gutter, not the caption field's nested scrollable.
        await tester.dragFrom(const Offset(12, 720), const Offset(0, -140));
        await tester.pumpAndSettle();
      }
      expect(target, findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tapVisible('CHOOSE A VIDEO');
    await tapVisible('SEND FOR REVIEW');
    expect(
      find.textContaining('Uploads are temporarily paused'),
      findsOneWidget,
    );
    expect(find.text('IN THE REVIEW QUEUE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
