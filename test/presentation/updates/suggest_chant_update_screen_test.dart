import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:chants/presentation/updates/suggest_chant_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Chant _chant() {
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
    status: 'community',
    chantType: 'sincere',
    origin: ChantOrigin.originalIdea,
    createdBy: 'creator-1',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 29),
  );
}

Widget _app(ChantUpdateRepository repository) {
  return ProviderScope(
    overrides: [chantUpdateRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: ChantTheme.dark,
      home: SuggestChantUpdateScreen(chant: _chant()),
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
  testWidgets('submits a bounded correction and explains the safety boundary', (
    tester,
  ) async {
    _useTallSurface(tester);
    Map<String, Object?>? payload;
    final repository = ChantUpdateRepository(
      invoker: (_, data) async {
        payload = data;
        return null;
      },
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Use Report for abuse or unsafe content'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'What should change, and why'),
      'The second line needs the away wording.',
    );
    await tester.pump();
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pumpAndSettle();

    expect(payload, {
      'chantId': 'chant-1',
      'kind': 'correction',
      'category': 'lyrics',
      'message': 'The second line needs the away wording.',
      'evidence': null,
    });
    expect(find.text('Update received.'), findsOneWidget);
  });

  testWidgets('normalizes evidence and retains answers after failure', (
    tester,
  ) async {
    _useTallSurface(tester);
    var calls = 0;
    Map<String, Object?>? payload;
    final repository = ChantUpdateRepository(
      invoker: (_, data) async {
        calls += 1;
        payload = data;
        throw const ChantUpdateException(ChantUpdateFailure.rejected);
      },
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add proof it is being sung'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What the clip proves'),
      'The whole away end is singing the complete chant.',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'YouTube or X link'),
      'https://youtu.be/abcdefghijk?t=14',
    );
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pump();

    expect(calls, 1);
    expect(payload?['evidence'], {
      'provider': 'youtube',
      'url': 'https://www.youtube.com/watch?v=abcdefghijk',
    });
    expect(
      find.text('The whole away end is singing the complete chant.'),
      findsOneWidget,
    );
    expect(find.text('https://youtu.be/abcdefghijk?t=14'), findsOneWidget);
    expect(
      find.text(
        'Could not send this chant update. Your answers are still here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rejects a non-content evidence URL before calling server', (
    tester,
  ) async {
    _useTallSurface(tester);
    var calls = 0;
    final repository = ChantUpdateRepository(
      invoker: (_, _) async {
        calls += 1;
        return null;
      },
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add proof it is being sung'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What the clip proves'),
      'This page is not a specific video or social post.',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'YouTube or X link'),
      'https://www.youtube.com/',
    );
    await tester.tap(find.text('SEND FOR REVIEW'));
    await tester.pump();

    expect(calls, 0);
    expect(
      find.text('Use a link to a specific YouTube video or Short.'),
      findsOneWidget,
    );
  });
}
