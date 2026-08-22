import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/presentation/shared/evidence_link_action.dart';

const evidence = ChantEvidence(
  provider: EvidenceProvider.youtube,
  url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
);

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('names the external destination and launches canonical URL', (
    tester,
  ) async {
    Uri? launched;
    await tester.pumpWidget(
      wrap(
        EvidenceLinkAction(
          evidence: evidence,
          launcher: (uri) async {
            launched = uri;
            return true;
          },
        ),
      ),
    );

    expect(find.text('Watch on YouTube'), findsOneWidget);
    expect(find.text('Opens outside Chants.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-evidence-link')));
    await tester.pump();
    expect(launched.toString(), evidence.url);
  });

  testWidgets('failed external launch stays put and explains retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        EvidenceLinkAction(evidence: evidence, launcher: (_) async => false),
      ),
    );

    await tester.tap(find.byKey(const Key('open-evidence-link')));
    await tester.pump();
    expect(
      find.text('Could not open that link. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(EvidenceLinkAction), findsOneWidget);
  });

  testWidgets('malformed legacy evidence does not become tappable', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        EvidenceLinkAction(
          evidence: const ChantEvidence(
            provider: EvidenceProvider.youtube,
            url: 'https://youtube.com.example.test/watch?v=dQw4w9WgXcQ',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('open-evidence-link')), findsNothing);
  });
}
