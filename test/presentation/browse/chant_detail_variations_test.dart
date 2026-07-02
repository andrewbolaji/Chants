import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/models/comment.dart';
import 'package:chants/data/models/comment_like.dart';
import 'package:chants/data/models/user_profile.dart';
import 'package:chants/data/repositories/chant_repository.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/profile_repository.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class _MockChantRepository extends Mock implements ChantRepository {
  @override
  Stream<Chant?> chantStream(String id) => Stream.value(null);
}

class _MockCommentRepository extends Mock implements CommentRepository {
  @override
  Stream<List<Comment>> commentsForChantStream({required String chantId}) =>
      Stream.value([]);
  @override
  Future<CommentLike?> getUserLike(
          {required String userId, required String commentId}) async =>
      null;
}

class _MockProfileRepository extends Mock implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) => Stream.value(null);
}

Chant _makeChant({List<ChantVariation> variations = const []}) {
  return Chant(
    id: 'test-chant',
    title: 'Super Mik Arteta',
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'coach',
    lyrics: "We've got Super Mik Arteta,\nHe knows exactly what we need",
    tuneName: 'Traditional terrace tune',
    contextNotes: 'A tribute to manager Mikel Arteta.',
    mediaType: 'none',
    status: 'canonical',
    realOrParody: 'real',
    createdBy: 'system',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    variations: variations,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      chantRepositoryProvider.overrideWithValue(_MockChantRepository()),
      commentRepositoryProvider.overrideWithValue(_MockCommentRepository()),
      profileRepositoryProvider.overrideWithValue(_MockProfileRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ChantDetailScreen variations', () {
    testWidgets('shows "Also sung as" section when variations exist',
        (tester) async {
      final chant = _makeChant(variations: [
        const ChantVariation(
          label: 'Current version',
          lyric: 'Gabi at the back, Gabi in attack',
          contextNote: 'Kieran Tierney left, so fans swapped his name out.',
        ),
      ]);
      await tester.pumpWidget(_wrap(ChantDetailScreen(chant: chant)));
      await tester.pumpAndSettle();

      expect(find.text('ALSO SUNG AS'), findsOneWidget);
      expect(find.text('CURRENT VERSION'), findsOneWidget);
      expect(find.text('Gabi at the back, Gabi in attack'), findsOneWidget);
      expect(
        find.text('Kieran Tierney left, so fans swapped his name out.'),
        findsOneWidget,
      );
    });

    testWidgets('hides "Also sung as" section when no variations',
        (tester) async {
      final chant = _makeChant();
      await tester.pumpWidget(_wrap(ChantDetailScreen(chant: chant)));
      await tester.pumpAndSettle();

      expect(find.text('ALSO SUNG AS'), findsNothing);
    });

    testWidgets('variation with null contextNote shows lyric only',
        (tester) async {
      final chant = _makeChant(variations: [
        const ChantVariation(
          label: 'Original',
          lyric: 'Kieran at the back, Gabi in attack',
        ),
      ]);
      await tester.pumpWidget(_wrap(ChantDetailScreen(chant: chant)));
      await tester.pumpAndSettle();

      expect(find.text('ORIGINAL'), findsOneWidget);
      expect(
        find.text('Kieran at the back, Gabi in attack'),
        findsOneWidget,
      );
    });
  });
}
