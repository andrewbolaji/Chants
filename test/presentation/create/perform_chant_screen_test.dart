import 'dart:async';

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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'fan';
}

class _Selector extends PerformanceMediaSelector {
  SelectedPerformanceMedia? selected;
  PerformanceMediaSelectionException? failure;
  Object? platformFailure;

  @override
  Future<SelectedPerformanceMedia?> recoverInterruptedSelection() async => null;

  @override
  Future<SelectedPerformanceMedia?> record() => _select();

  @override
  Future<SelectedPerformanceMedia?> chooseFromLibrary() => _select();

  Future<SelectedPerformanceMedia?> _select() async {
    final platformError = platformFailure;
    if (platformError != null) throw platformError;
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
  Chant? chant,
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
      debugShowCheckedModeBanner: false,
      theme: ChantTheme.dark,
      home: PerformChantScreen(chant: chant ?? _chant),
    ),
  );
}

Future<void> _loadFonts() async {
  final fonts = {
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

PerformanceDraftRepository _repository({
  required List<(String, Map<String, Object>)> calls,
  Object? creationFailure,
  Object? submissionFailure,
  Future<void>? creationBarrier,
  Future<void>? uploadCompletion,
  Stream<double>? uploadProgress,
  Future<bool> Function()? onCancel,
  Future<void>? submissionBarrier,
  Future<void>? cancellationBarrier,
  Object? cancellationFailure,
  void Function(PerformanceDraftTicket, SelectedPerformanceMedia, String)?
  onUpload,
}) {
  return PerformanceDraftRepository(
    invoker: (callable, payload) async {
      calls.add((callable, payload));
      if (callable == 'createPerformanceDraft') {
        if (creationBarrier != null) await creationBarrier;
        if (creationFailure != null) throw creationFailure;
        return {
          'draftId': 'draft-1',
          'uploadPath': 'performance-staging/fan/draft-1/source',
        };
      }
      if (callable == 'submitPerformanceDraft') {
        if (submissionBarrier != null) await submissionBarrier;
        if (submissionFailure != null) throw submissionFailure;
      }
      if (callable == 'cancelPerformanceDraft') {
        if (cancellationBarrier != null) await cancellationBarrier;
        if (cancellationFailure != null) throw cancellationFailure;
      }
      return const {};
    },
    uploader: ({required ticket, required media, required ownerId}) {
      onUpload?.call(ticket, media, ownerId);
      return PerformanceUploadHandle(
        completion: uploadCompletion ?? Future.value(),
        progress: uploadProgress ?? Stream.value(1),
        cancel: onCancel ?? () async => true,
      );
    },
    ownerDraftsLoader: (_) => Stream.value(const []),
    reviewQueueLoader: () => Stream.value(const []),
  );
}

void main() {
  testWidgets(
    'active upload blocks navigation and gives progress plus deliberate cancel',
    (tester) async {
      installTolerantGoldenComparator(
        testFile: Uri.base.resolve(
          'test/presentation/create/perform_chant_screen_test.dart',
        ),
      );
      await _loadFonts();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selector = _Selector()
        ..selected = const SelectedPerformanceMedia(
          filePath: '/tmp/take.mp4',
          fileName: 'take.mp4',
          contentType: 'video/mp4',
          sizeBytes: 1024,
          durationMs: 12500,
        );
      final calls = <(String, Map<String, Object>)>[];
      final uploadCompletion = Completer<void>();
      final progress = StreamController<double>();
      final cancellation = Completer<void>();
      var cancelled = false;
      addTearDown(progress.close);

      await tester.pumpWidget(
        _wrap(
          selector: selector,
          creator: _creator(),
          repository: _repository(
            calls: calls,
            uploadCompletion: uploadCompletion.future,
            uploadProgress: progress.stream,
            onCancel: () async {
              cancelled = true;
              final cancellationError = FirebaseException(
                plugin: 'firebase_storage',
                code: 'canceled',
              );
              progress.addError(cancellationError);
              if (!uploadCompletion.isCompleted) {
                uploadCompletion.completeError(cancellationError);
              }
              await cancellation.future;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHOOSE A VIDEO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND FOR REVIEW'));
      await tester.pump();

      expect(find.byKey(const Key('performance-upload-panel')), findsOneWidget);
      expect(find.text('UPLOADING YOUR TAKE'), findsOneWidget);
      expect(find.textContaining('Keep Chants open'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(
        tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
        isFalse,
      );
      expect(
        tester.getSemantics(
          find.widgetWithText(OutlinedButton, 'CANCEL UPLOAD'),
        ),
        matchesSemantics(
          label: 'CANCEL UPLOAD',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      progress.add(0.42);
      await tester.pump();
      expect(find.text('UPLOADING 42%'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          platformGoldenPath('goldens/perform_chant_upload.png'),
        ),
      );

      await tester.tap(find.text('CANCEL UPLOAD'));
      await tester.pump();
      expect(find.text('CANCELLING UPLOAD'), findsOneWidget);
      expect(find.text('CONFIRMING CANCELLATION'), findsOneWidget);
      expect(
        find.textContaining('safely close this private draft'),
        findsOneWidget,
      );
      expect(find.text('CANCEL UPLOAD'), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      cancellation.complete();
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      expect(calls.last.$1, 'cancelPerformanceDraft');
      expect(find.text('UPLOAD CANCELLED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel wins a race with transfer completion', (tester) async {
    final selector = _Selector()
      ..selected = const SelectedPerformanceMedia(
        filePath: '/tmp/take.mp4',
        fileName: 'take.mp4',
        contentType: 'video/mp4',
        sizeBytes: 1024,
        durationMs: 12500,
      );
    final calls = <(String, Map<String, Object>)>[];
    final uploadCompletion = Completer<void>();
    final cancelRelease = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(
          calls: calls,
          uploadCompletion: uploadCompletion.future,
          uploadProgress: const Stream.empty(),
          onCancel: () async {
            uploadCompletion.complete();
            await cancelRelease.future;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHOOSE A VIDEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pump();
    await tester.tap(find.text('CANCEL UPLOAD'));
    await tester.pump();

    expect(find.text('CANCELLING UPLOAD'), findsOneWidget);
    expect(calls.where((call) => call.$1 == 'submitPerformanceDraft'), isEmpty);

    cancelRelease.complete();
    await tester.pumpAndSettle();

    expect(find.text('UPLOAD CANCELLED'), findsOneWidget);
    expect(calls.where((call) => call.$1 == 'submitPerformanceDraft'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('callable cancellation failure restores recovery actions', (
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
    final uploadCompletion = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(
          calls: [],
          uploadCompletion: uploadCompletion.future,
          uploadProgress: const Stream.empty(),
          onCancel: () async {
            uploadCompletion.completeError(
              FirebaseException(plugin: 'firebase_storage', code: 'canceled'),
            );
            return true;
          },
          cancellationFailure: FirebaseFunctionsException(
            code: 'unavailable',
            message: 'Synthetic cancellation failure.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHOOSE A VIDEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pump();
    await tester.tap(find.text('CANCEL UPLOAD'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cancellation could not be confirmed. Try again.'),
      findsOneWidget,
    );
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(find.text('CANCEL UPLOAD'), findsOneWidget);
    expect(find.byKey(const Key('performance-upload-panel')), findsNothing);
    expect(find.text('UPLOAD CANCELLED'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel during draft admission waits for the ticket and skips upload',
    (tester) async {
      final selector = _Selector()
        ..selected = const SelectedPerformanceMedia(
          filePath: '/tmp/take.mp4',
          fileName: 'take.mp4',
          contentType: 'video/mp4',
          sizeBytes: 1024,
          durationMs: 12500,
        );
      final creation = Completer<void>();
      final calls = <(String, Map<String, Object>)>[];
      var uploads = 0;

      await tester.pumpWidget(
        _wrap(
          selector: selector,
          creator: _creator(),
          repository: _repository(
            calls: calls,
            creationBarrier: creation.future,
            onUpload: (_, _, _) => uploads++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHOOSE A VIDEO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND FOR REVIEW'));
      await tester.pump();
      await tester.tap(find.text('CANCEL UPLOAD'));
      await tester.pump();

      expect(find.text('CANCELLING UPLOAD'), findsOneWidget);
      expect(find.text('UPLOAD CANCELLED'), findsNothing);

      creation.complete();
      await tester.pumpAndSettle();

      expect(uploads, 0);
      expect(calls.map((call) => call.$1), [
        'createPerformanceDraft',
        'cancelPerformanceDraft',
      ]);
      expect(find.text('UPLOAD CANCELLED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed draft admission resolves a pending cancellation with a next action',
    (tester) async {
      final selector = _Selector()
        ..selected = const SelectedPerformanceMedia(
          filePath: '/tmp/take.mp4',
          fileName: 'take.mp4',
          contentType: 'video/mp4',
          sizeBytes: 1024,
          durationMs: 12500,
        );
      final creation = Completer<void>();
      var uploads = 0;

      await tester.pumpWidget(
        _wrap(
          selector: selector,
          creator: _creator(),
          repository: _repository(
            calls: [],
            creationBarrier: creation.future,
            creationFailure: Exception('Synthetic admission failure.'),
            onUpload: (_, _, _) => uploads++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHOOSE A VIDEO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND FOR REVIEW'));
      await tester.pump();
      await tester.tap(find.text('CANCEL UPLOAD'));
      await tester.pump();

      expect(find.text('CANCELLING UPLOAD'), findsOneWidget);
      creation.complete();
      await tester.pumpAndSettle();

      expect(uploads, 0);
      expect(find.text('UPLOAD CANCELLED'), findsNothing);
      expect(
        find.textContaining(
          'Cancellation could not be confirmed because upload setup did not finish',
        ),
        findsOneWidget,
      );
      expect(find.text('SEND FOR REVIEW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed upload gives immediate blocking feedback while cancellation settles',
    (tester) async {
      final selector = _Selector()
        ..selected = const SelectedPerformanceMedia(
          filePath: '/tmp/take.mp4',
          fileName: 'take.mp4',
          contentType: 'video/mp4',
          sizeBytes: 1024,
          durationMs: 12500,
        );
      final cancellation = Completer<void>();
      final upload = Completer<void>();
      final calls = <(String, Map<String, Object>)>[];

      await tester.pumpWidget(
        _wrap(
          selector: selector,
          creator: _creator(),
          repository: _repository(
            calls: calls,
            uploadCompletion: upload.future,
            cancellationBarrier: cancellation.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHOOSE A VIDEO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND FOR REVIEW'));
      await tester.pump();
      upload.completeError(
        FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
      );
      await tester.pumpAndSettle();

      final cancel = find.text('CANCEL UPLOAD').hitTestable();
      for (
        var attempt = 0;
        cancel.evaluate().isEmpty && attempt < 6;
        attempt++
      ) {
        await tester.dragFrom(const Offset(12, 520), const Offset(0, -120));
        await tester.pumpAndSettle();
      }
      expect(cancel, findsOneWidget);
      await tester.tap(cancel);
      await tester.pump();

      expect(find.text('CANCELLING UPLOAD'), findsOneWidget);
      expect(find.text('CONFIRMING CANCELLATION'), findsOneWidget);
      expect(find.text('CANCEL UPLOAD'), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(
        calls.where((call) => call.$1 == 'cancelPerformanceDraft'),
        hasLength(1),
      );

      cancellation.complete();
      await tester.pumpAndSettle();
      expect(find.text('UPLOAD CANCELLED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('upload panel names the private review handoff phase', (
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
    final submission = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        selector: selector,
        creator: _creator(),
        repository: _repository(
          calls: [],
          submissionBarrier: submission.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHOOSE A VIDEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pump();

    expect(find.text('ADDING TO REVIEW QUEUE'), findsOneWidget);
    expect(find.text('UPLOAD COMPLETE · FINAL CHECK'), findsOneWidget);
    expect(find.textContaining('private review queue'), findsOneWidget);
    expect(find.text('CANCEL UPLOAD'), findsNothing);

    submission.complete();
    await tester.pumpAndSettle();
    expect(find.text('IN THE REVIEW QUEUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
          final cancel = find.text('CANCEL UPLOAD').hitTestable();
          for (
            var attempt = 0;
            cancel.evaluate().isEmpty && attempt < 6;
            attempt++
          ) {
            // Drag the page gutter so a nested text-field scrollable cannot
            // absorb the recovery gesture on a compact test viewport.
            await tester.dragFrom(const Offset(12, 520), const Offset(0, -120));
            await tester.pumpAndSettle();
          }
          expect(cancel, findsOneWidget);
          await tester.tap(cancel);
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

    expect(find.text('POSTING AS'), findsOneWidget);
    expect(find.text('@northbankleo'), findsOneWidget);
    await tester.tap(find.text('CHOOSE A VIDEO'));
    await tester.pumpAndSettle();
    expect(find.text('take.mp4'), findsOneWidget);
    expect(find.textContaining('12.5 seconds'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('performance-caption')),
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

  for (final permissionCase in [
    (
      button: 'RECORD A TAKE',
      code: 'camera_access_denied',
      copy: 'Open Settings and allow camera access for Chants, then try again.',
    ),
    (
      button: 'CHOOSE A VIDEO',
      code: 'photo_access_denied',
      copy:
          'Open Settings and allow photo and video access for Chants, then try again.',
    ),
  ]) {
    testWidgets(
      '${permissionCase.button} denial gives a Settings next action',
      (tester) async {
        final selector = _Selector()
          ..platformFailure = PlatformException(code: permissionCase.code);
        await tester.pumpWidget(
          _wrap(
            selector: selector,
            creator: _creator(),
            repository: _repository(calls: []),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(permissionCase.button));
        await tester.pumpAndSettle();

        expect(find.text(permissionCase.copy), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

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

  testWidgets('creator posting identity is visually distinct', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/create/perform_chant_screen_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        selector: _Selector(),
        creator: _creator(),
        repository: _repository(calls: []),
        chant: _chant.copyWith(status: 'canonical'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POSTING AS'), findsOneWidget);
    expect(find.text('@northbankleo'), findsOneWidget);
    final handleSize = tester.getSize(
      find.byKey(const Key('performance-posting-handle')),
    );
    final chipSize = tester.getSize(
      find.byKey(const Key('performance-posting-handle-chip')),
    );
    expect(chipSize.width, lessThan(handleSize.width + 24));
    expect(chipSize.height, lessThanOrEqualTo(34));
    expect(find.textContaining('Verified as sung at matches'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(platformGoldenPath('goldens/perform_chant_entry.png')),
    );
  });
}
