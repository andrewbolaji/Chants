import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant_update_suggestion.dart';
import 'package:chants/data/repositories/chant_update_repository.dart';
import 'package:chants/presentation/updates/my_chant_updates_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'supporter';
}

ChantUpdateSuggestion _suggestion(ChantUpdateStatus status, {String? note}) {
  final now = DateTime.utc(2026, 8, 29);
  return ChantUpdateSuggestion(
    id: status.name,
    chantId: 'chant-${status.name}',
    chantTitleSnapshot: 'Song ${status.name}',
    submittedBy: 'supporter',
    kind: ChantUpdateKind.correction,
    category: ChantUpdateCategory.lyrics,
    message: 'The second line needs the away wording.',
    evidence: null,
    chantUpdatedAt: now,
    status: status,
    resolutionKind: null,
    resolutionNote: note,
    createdAt: now,
    updatedAt: now,
    resolvedAt:
        status == ChantUpdateStatus.updated ||
            status == ChantUpdateStatus.notChanged
        ? now
        : null,
  );
}

void main() {
  testWidgets('shows every private status and an optional review note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ChantUpdateRepository(
      loader: (_) => Stream.value([
        _suggestion(ChantUpdateStatus.received),
        _suggestion(ChantUpdateStatus.planned),
        _suggestion(ChantUpdateStatus.updated, note: 'Added to the Songbook.'),
        _suggestion(
          ChantUpdateStatus.notChanged,
          note: 'The existing wording is current.',
        ),
      ]),
      invoker: (_, _) async => null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_User())),
          chantUpdateRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: ChantTheme.dark,
          home: const MyChantUpdatesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['RECEIVED', 'PLANNED', 'UPDATED', 'NOT CHANGED']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Added to the Songbook.'), findsOneWidget);
    expect(find.text('The existing wording is current.'), findsOneWidget);
  });
}
