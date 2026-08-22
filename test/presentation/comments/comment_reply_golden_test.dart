import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/app/theme.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/presentation/comments/comment_section.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _GoldenUser extends Mock implements User {
  @override
  String get uid => 'viewer';
}

class _GoldenCommentRepository implements CommentRepository {
  final controller = StreamController<List<Comment>>.broadcast();

  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) {
    return controller.stream;
  }

  @override
  Future<CommentLike?> getUserLike({
    required String userId,
    required String commentId,
  }) async {
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoldenProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) {
    final now = DateTime(2026, 8, 17);
    return Stream.value(
      UserProfile(
        id: userId,
        displayName: 'NorthBankFan',
        role: 'user',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comment _comment({
  required String id,
  required String userId,
  required String displayName,
  required String body,
  String? parentCommentId,
  int likeCount = 0,
}) {
  return Comment(
    id: id,
    chantId: 'chant-1',
    userId: userId,
    displayName: displayName,
    body: body,
    parentCommentId: parentCommentId,
    // A fixed future instant keeps the relative-time label at "Just now".
    // Using DateTime.now made the golden depend on total suite runtime.
    createdAt: DateTime(2100, 1, 1),
    likeCount: likeCount,
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

void main() {
  testWidgets('one-level reply thread visual', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/comments/comment_reply_golden_test.dart',
      ),
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final comments = _GoldenCommentRepository();
    addTearDown(comments.controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_GoldenUser() as User?),
          ),
          commentRepositoryProvider.overrideWithValue(comments),
          profileRepositoryProvider.overrideWithValue(
            _GoldenProfileRepository(),
          ),
          blockedUserIdsProvider.overrideWith(
            (ref, userId) => Stream.value(<String>{}),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CommentSection(chantId: 'chant-1', commentCount: 3),
            ),
          ),
        ),
      ),
    );

    final parent = _comment(
      id: 'parent',
      userId: 'funny-fan',
      displayName: 'FunnyFan',
      body: 'He has more songs than touches this season.',
      likeCount: 18,
    );
    comments.controller.add([
      parent,
      _comment(
        id: 'reply-1',
        userId: 'away-end',
        displayName: 'AwayEnd',
        body: 'Still a better first touch than our striker.',
        parentCommentId: parent.id,
        likeCount: 7,
      ),
      _comment(
        id: 'reply-2',
        userId: 'clock-end',
        displayName: 'ClockEnd',
        body: 'The bar is underground mate.',
        parentCommentId: parent.id,
        likeCount: 4,
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/comment_reply_thread.png'),
    );
  });
}
