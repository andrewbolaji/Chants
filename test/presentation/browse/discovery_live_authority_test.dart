import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/router.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:chants/presentation/browse/discovery_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _ChantRepository extends Mock implements ChantRepository {
  final StreamController<Chant?> controller =
      StreamController<Chant?>.broadcast();

  @override
  Stream<Chant?> chantStream(String id) => controller.stream;
}

class _CommentRepository extends Mock implements CommentRepository {
  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return Stream.value(const []);
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async => null;
}

class _ShareGateway implements ChantShareGateway {
  int calls = 0;

  @override
  Future<void> share(
    ChantSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    calls++;
  }
}

final _chant = Chant(
  id: 'arsenal-north-bank',
  title: 'North Bank Song',
  sportId: 'football',
  competitionId: 'premier-league',
  teamId: 'arsenal',
  subjectTag: 'club',
  lyrics: 'Sing it loud',
  tuneName: 'Traditional',
  mediaType: 'none',
  status: 'canonical',
  chantType: 'sincere',
  createdBy: 'system',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

Widget _app({
  required _ChantRepository repository,
  required _ShareGateway gateway,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
      chantRepositoryProvider.overrideWithValue(repository),
      commentRepositoryProvider.overrideWithValue(_CommentRepository()),
      chantShareGatewayProvider.overrideWithValue(gateway),
      discoveryProvider.overrideWith((ref) async => [_chant]),
      allTeamsProvider.overrideWith(
        (ref) => Stream.value(const {'arsenal': 'Arsenal'}),
      ),
    ],
    child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const Scaffold(
        body: SingleChildScrollView(child: DiscoverySection()),
      ),
    ),
  );
}

void main() {
  testWidgets('permission denial removes a stale Discover card', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_app(repository: repository, gateway: gateway));
    await tester.pumpAndSettle();
    expect(find.text('NORTH BANK SONG'), findsOneWidget);
    expect(repository.controller.hasListener, isTrue);

    final permissionDenied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    expect(isChantPermissionDenied(permissionDenied), isTrue);
    repository.controller.addError(permissionDenied);
    await tester.pumpAndSettle();

    expect(find.text('NORTH BANK SONG'), findsNothing);
  });

  testWidgets('ordinary stream failure retains the last safe Discover card', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_app(repository: repository, gateway: gateway));
    await tester.pumpAndSettle();
    repository.controller.addError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.text('NORTH BANK SONG'), findsOneWidget);
  });

  testWidgets('Discover route snapshot cannot share after permission denial', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(_app(repository: repository, gateway: gateway));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NORTH BANK SONG'));
    await tester.pumpAndSettle();
    expect(find.byType(ChantDetailScreen), findsOneWidget);

    repository.controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await tester.pumpAndSettle();

    final shareButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
    );
    expect(shareButton.onPressed, isNull);
    expect(gateway.calls, 0);
  });
}
