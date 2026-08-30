import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:chants/presentation/moderation/chant_update_moderation_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _ChantRepository extends ChantRepository {
  final StreamController<LiveChantSnapshot> _controller;

  _ChantRepository(LiveChantSnapshot source)
    : _controller = StreamController<LiveChantSnapshot>()..add(source),
      super(firestore: _Firestore());

  @override
  Stream<LiveChantSnapshot> chantStream(String id) => _controller.stream;
}

const _proposal = ChantEvidence(
  provider: EvidenceProvider.youtube,
  url: 'https://www.youtube.com/watch?v=abcdefghijk',
);

const _currentEvidence = ChantEvidence(
  provider: EvidenceProvider.x,
  url: 'https://x.com/terrace/status/1234567890',
);

ChantUpdateSuggestion _suggestion({
  ChantUpdateKind kind = ChantUpdateKind.correction,
  ChantUpdateCategory? category = ChantUpdateCategory.lyrics,
  ChantEvidence? evidence,
}) {
  final now = DateTime.utc(2026, 8, 29, 18);
  return ChantUpdateSuggestion(
    id: 'suggestion-1',
    chantId: 'chant-1',
    chantTitleSnapshot: 'North Bank Song',
    submittedBy: 'supporter',
    kind: kind,
    category: category,
    message: kind == ChantUpdateKind.evidence
        ? 'The whole away end is singing this version.'
        : 'The second line needs the away wording.',
    evidence: evidence,
    chantUpdatedAt: now,
    status: ChantUpdateStatus.received,
    resolutionKind: null,
    resolutionNote: null,
    createdAt: now,
    updatedAt: now,
    resolvedAt: null,
  );
}

Chant _chant({
  String status = 'canonical',
  String createdBy = 'system',
  ChantEvidence? evidence,
  DateTime? updatedAt,
}) {
  return Chant(
    id: 'chant-1',
    title: 'North Bank Song',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: 'Sing it loud',
    tuneName: 'Traditional',
    mediaType: 'none',
    status: status,
    chantType: 'sincere',
    origin: ChantOrigin.originalIdea,
    evidence: evidence,
    createdBy: createdBy,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 8, 29, 18),
  );
}

Widget _app({
  required ChantUpdateSuggestion suggestion,
  required LiveChantSnapshot source,
  required ChantUpdateCallable invoker,
}) {
  final chantRepository = _ChantRepository(source);
  final updateRepository = ChantUpdateRepository(
    loader: (_) => Stream.value([suggestion]),
    invoker: invoker,
  );
  return ProviderScope(
    overrides: [
      chantRepositoryProvider.overrideWithValue(chantRepository),
      chantUpdateRepositoryProvider.overrideWithValue(updateRepository),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: const Scaffold(body: ChantUpdateModerationTab()),
    ),
  );
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('closes an authoritatively unavailable chant as Not changed', (
    tester,
  ) async {
    _useTallSurface(tester);
    Map<String, Object?>? payload;
    await tester.pumpWidget(
      _app(
        suggestion: _suggestion(),
        source: const LiveChantSnapshot(chant: null, isFromCache: false),
        invoker: (_, data) async {
          payload = data;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Only Not changed can close'), findsOneWidget);
    final close = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'NOT CHANGED'),
    );
    expect(close.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(TextButton, 'NOT CHANGED'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason shown to the submitter'),
      'The source chant is no longer available.',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'CLOSE'));
    await tester.pumpAndSettle();

    expect(payload?['action'], 'notChanged');
    expect(payload?['acknowledgeEvidenceReplacement'], isFalse);
  });

  testWidgets('shows both proof links and confirms explicit replacement', (
    tester,
  ) async {
    _useTallSurface(tester);
    Map<String, Object?>? payload;
    await tester.pumpWidget(
      _app(
        suggestion: _suggestion(
          kind: ChantUpdateKind.evidence,
          category: null,
          evidence: _proposal,
        ),
        source: LiveChantSnapshot(
          chant: _chant(evidence: _currentEvidence),
          isFromCache: false,
        ),
        invoker: (_, data) async {
          payload = data;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CURRENT PROOF'), findsOneWidget);
    expect(find.text('PROPOSED PROOF'), findsOneWidget);
    expect(find.textContaining('Current version 2026-08-29'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'REPLACE EVIDENCE').last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Replace current proof?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'REPLACE EVIDENCE').last,
    );
    await tester.pumpAndSettle();

    expect(payload?['action'], 'acceptEvidence');
    expect(payload?['acknowledgeEvidenceReplacement'], isTrue);
  });

  testWidgets('requires stale acknowledgement before marking updated', (
    tester,
  ) async {
    _useTallSurface(tester);
    Map<String, Object?>? payload;
    await tester.pumpWidget(
      _app(
        suggestion: _suggestion(),
        source: LiveChantSnapshot(
          chant: _chant(updatedAt: DateTime.utc(2026, 8, 30)),
          isFromCache: false,
        ),
        invoker: (_, data) async {
          payload = data;
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'MARK UPDATED'));
    await tester.pumpAndSettle();
    var confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'MARK UPDATED'),
    );
    expect(confirm.onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'MARK UPDATED'),
    );
    expect(confirm.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'MARK UPDATED'));
    await tester.pumpAndSettle();

    expect(payload?['action'], 'updated');
    expect(payload?['acknowledgeStale'], isTrue);
  });

  testWidgets('distinguishes system attachment from user-chant promotion', (
    tester,
  ) async {
    _useTallSurface(tester);
    final suggestion = _suggestion(
      kind: ChantUpdateKind.evidence,
      category: null,
      evidence: _proposal,
    );
    await tester.pumpWidget(
      _app(
        suggestion: suggestion,
        source: LiveChantSnapshot(
          chant: _chant(status: 'community', createdBy: 'system'),
          isFromCache: false,
        ),
        invoker: (_, _) async => null,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'ACCEPT EVIDENCE'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(
        suggestion: suggestion,
        source: LiveChantSnapshot(
          chant: _chant(status: 'community', createdBy: 'creator-1'),
          isFromCache: false,
        ),
        invoker: (_, _) async => null,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'ACCEPT & PROMOTE'),
      findsOneWidget,
    );
  });
}
