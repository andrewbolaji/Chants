import 'dart:async';

import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/models/saved_songbook.dart';
import 'package:chants/data/models/team.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/models/vote.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _ChantRepository extends Mock implements ChantRepository {
  final StreamController<LiveChantSnapshot> controller =
      StreamController<LiveChantSnapshot>.broadcast();
  Chant? current;
  bool emitCurrentOnListen = true;

  @override
  Stream<LiveChantSnapshot> chantStream(String id) =>
      Stream<LiveChantSnapshot>.multi((events) {
        if (emitCurrentOnListen && current != null) {
          events.add(LiveChantSnapshot(chant: current, isFromCache: false));
        }
        final subscription = controller.stream.listen(
          (snapshot) {
            current = snapshot.chant;
            events.add(snapshot);
          },
          onError: events.addError,
          onDone: events.close,
        );
        events.onCancel = subscription.cancel;
      });

  void emit(Chant? chant, {bool isFromCache = false}) {
    controller.add(LiveChantSnapshot(chant: chant, isFromCache: isFromCache));
  }
}

class _User extends Mock implements User {
  @override
  String get uid => 'viewer-1';
}

class _CommentRepository extends Mock implements CommentRepository {
  final List<Comment> comments;

  _CommentRepository([this.comments = const []]);

  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return Stream.value(comments);
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async => null;
}

class _VoteRepository extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

class _ProfileRepository extends Mock implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) => Stream.value(null);
}

class _ShareGateway implements ChantShareGateway {
  final List<ChantSharePayload> payloads = [];
  final List<Rect> origins = [];
  Completer<void>? pending;
  Object? error;

  @override
  Future<void> share(
    ChantSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    payloads.add(payload);
    origins.add(sharePositionOrigin);
    if (error != null) throw error!;
    await (pending?.future ?? Future<void>.value());
  }
}

const _team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

Chant _chant({
  String title = 'North Bank Song',
  String lyrics = 'Sing it loud\nSing it proud',
  bool hidden = false,
  bool removed = false,
}) {
  return Chant(
    id: 'arsenal-north-bank-song',
    title: title,
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: lyrics,
    tuneName: 'Traditional',
    mediaType: 'none',
    status: 'canonical',
    chantType: 'sincere',
    createdBy: 'system',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    hidden: hidden,
    removed: removed,
  );
}

Widget _app({
  required Chant chant,
  required _ChantRepository repository,
  required ChantShareGateway gateway,
  double textScale = 1,
  List<Comment> comments = const [],
  User? user,
}) {
  repository.current = chant;
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
      chantRepositoryProvider.overrideWithValue(repository),
      commentRepositoryProvider.overrideWithValue(_CommentRepository(comments)),
      voteRepositoryProvider.overrideWithValue(_VoteRepository()),
      profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
      chantShareGatewayProvider.overrideWithValue(gateway),
      blockedUserIdsProvider.overrideWith(
        (ref, uid) => Stream.value(const <String>{}),
      ),
      userProfileProvider.overrideWith((ref, uid) => Stream.value(null)),
      savedSongbookProvider.overrideWith(
        (ref, uid) async => SavedSongbook.empty(),
      ),
    ],
    child: MaterialApp(
      theme: ChantTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ChantDetailScreen(chant: chant, team: _team),
    ),
  );
}

void main() {
  testWidgets('share action exposes accessible copy and useful payload', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(chant: _chant(), repository: repository, gateway: gateway),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Share this chant'), findsOneWidget);
    expect(find.bySemanticsLabel('Share this chant'), findsOneWidget);

    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pump();

    expect(gateway.payloads, hasLength(1));
    expect(gateway.payloads.single.text, contains('North Bank Song'));
    expect(gateway.payloads.single.text, contains('Arsenal'));
    expect(gateway.payloads.single.text, contains('Sing it loud'));
    expect(gateway.payloads.single.text, isNot(contains('https://')));
    expect(gateway.origins.single.width, greaterThan(0));
    expect(gateway.origins.single.height, greaterThan(0));
    semantics.dispose();
  });

  testWidgets('one native share remains outstanding at a time', (tester) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway()..pending = Completer<void>();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(
      _app(chant: _chant(), repository: repository, gateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pump();
    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pump();

    expect(gateway.payloads, hasLength(1));

    gateway.pending!.complete();
    await tester.pumpAndSettle();
    gateway.pending = null;
    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pumpAndSettle();

    expect(gateway.payloads, hasLength(2));
  });

  testWidgets('share uses the current chant emitted by the detail stream', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(
      _app(chant: _chant(), repository: repository, gateway: gateway),
    );
    await tester.pumpAndSettle();

    repository.emit(
      _chant(title: 'Updated terrace song', lyrics: 'The current words'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pumpAndSettle();

    expect(gateway.payloads.single.text, contains('Updated terrace song'));
    expect(gateway.payloads.single.text, contains('The current words'));
    expect(gateway.payloads.single.text, isNot(contains('North Bank Song')));
  });

  testWidgets('platform failure leaves detail readable and explains retry', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway()..error = StateError('platform failed');
    addTearDown(repository.controller.close);

    await tester.pumpWidget(
      _app(chant: _chant(), repository: repository, gateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share this chant'));
    await tester.pump();

    expect(find.text('NORTH BANK SONG'), findsOneWidget);
    expect(find.text('Could not open sharing. Try again.'), findsOneWidget);
  });

  testWidgets('hidden and removed current chants cannot start sharing', (
    tester,
  ) async {
    for (final chant in [_chant(hidden: true), _chant(removed: true)]) {
      final repository = _ChantRepository();
      final gateway = _ShareGateway();

      await tester.pumpWidget(
        _app(chant: chant, repository: repository, gateway: gateway),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
      );
      expect(button.onPressed, isNull);
      expect(gateway.payloads, isEmpty);

      await repository.controller.close();
    }
  });

  testWidgets(
    'stale route is readable but cannot share without current visible authority',
    (tester) async {
      final repository = _ChantRepository()..emitCurrentOnListen = false;
      final gateway = _ShareGateway();
      addTearDown(repository.controller.close);

      await tester.pumpWidget(
        _app(chant: _chant(), repository: repository, gateway: gateway),
      );
      await tester.pump();

      expect(find.text('NORTH BANK SONG'), findsOneWidget);
      var shareButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
      );
      expect(shareButton.onPressed, isNull);

      repository.emit(_chant());
      await tester.pump();
      shareButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
      );
      expect(shareButton.onPressed, isNotNull);

      repository.controller.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pump();
      shareButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
      );
      expect(shareButton.onPressed, isNull);
      expect(gateway.payloads, isEmpty);
    },
  );

  testWidgets('all live-target actions wait for current authority', (
    tester,
  ) async {
    final repository = _ChantRepository()..emitCurrentOnListen = false;
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(
      _app(
        chant: _chant(),
        repository: repository,
        gateway: gateway,
        user: _User(),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.bookmark_border),
    );
    final shareButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
    );
    final reportButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.flag_outlined).first,
    );
    final upvoteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_drop_up),
    );
    final downvoteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_drop_down),
    );

    expect(saveButton.onPressed, isNull);
    expect(shareButton.onPressed, isNull);
    expect(reportButton.onPressed, isNull);
    expect(upvoteButton.onPressed, isNull);
    expect(downvoteButton.onPressed, isNull);
    expect(
      find.text('Live updates are required to join the comments.'),
      findsOneWidget,
    );
    expect(gateway.payloads, isEmpty);
  });

  testWidgets('cached detail stays readable with every action disabled', (
    tester,
  ) async {
    final repository = _ChantRepository()..emitCurrentOnListen = false;
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);

    await tester.pumpWidget(
      _app(
        chant: _chant(),
        repository: repository,
        gateway: gateway,
        user: _User(),
      ),
    );
    await tester.pumpAndSettle();
    repository.emit(_chant(), isFromCache: true);
    await tester.pump();

    expect(find.text('NORTH BANK SONG'), findsOneWidget);
    for (final icon in <IconData>[
      Icons.bookmark_border,
      Icons.ios_share_outlined,
      Icons.flag_outlined,
      Icons.arrow_drop_up,
      Icons.arrow_drop_down,
    ]) {
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icon).first,
      );
      expect(button.onPressed, isNull, reason: '$icon must wait for server');
    }

    repository.emit(_chant());
    await tester.pump();
    final share = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
    );
    expect(share.onPressed, isNotNull);
  });

  testWidgets('detail actions remain usable with enlarged text', (
    tester,
  ) async {
    final repository = _ChantRepository();
    final gateway = _ShareGateway();
    addTearDown(repository.controller.close);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        chant: _chant(),
        repository: repository,
        gateway: gateway,
        textScale: 1.8,
        comments: [
          Comment(
            id: 'comment-1',
            chantId: 'arsenal-north-bank-song',
            userId: 'other-user',
            displayName: 'North Bank Fan',
            body: 'Love this one.',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Share this chant'), findsOneWidget);
    expect(find.byTooltip('Report this chant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
