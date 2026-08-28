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
import 'package:chants/data/repositories/public_share_repository.dart';
import 'package:chants/data/repositories/vote_repository.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:chants/presentation/browse/chant_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/tolerant_golden_file_comparator.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'viewer-1';
}

class _ChantRepository extends Mock implements ChantRepository {
  @override
  Stream<LiveChantSnapshot> chantStream(String id) async* {
    yield LiveChantSnapshot(chant: _chant, isFromCache: false);
    await Completer<void>().future;
  }
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

class _ProfileRepository extends Mock implements ProfileRepository {
  @override
  Stream<UserProfile?> profileStream(String userId) => Stream.value(null);
}

class _VoteRepository extends Mock implements VoteRepository {
  @override
  Future<Vote?> getUserVote({
    required String userId,
    required String chantId,
  }) async => null;
}

class _ShareGateway implements ChantShareGateway {
  @override
  Future<void> share(
    ChantSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {}
}

const _team = Team(
  id: 'arsenal',
  sportId: 'football',
  competitionId: 'premier-league',
  name: 'Arsenal',
);

final _chant = Chant(
  id: 'arsenal-kai-havertz-scores-again',
  title: 'Kai Havertz Scores Again',
  sportId: _team.sportId,
  competitionId: _team.competitionId,
  teamId: _team.id,
  playerId: 'kai-havertz',
  subjectTag: 'player',
  lyrics:
      'Tsamina mina, eh eh,\n'
      'Waka waka, eh eh,\n'
      '60 million down the drain,\n'
      'Kai Havertz scores again!',
  tuneName: 'Waka Waka (Shakira)',
  contextNotes: 'Sung for Kai Havertz after his move to Arsenal.',
  mediaType: 'none',
  status: 'canonical',
  chantType: 'sincere',
  score: 24,
  createdBy: 'system',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 8, 24),
);

Future<void> _loadFonts() async {
  final fonts = {
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
    'Anton': 'assets/fonts/Anton-Regular.ttf',
    'SpaceMono': 'assets/fonts/SpaceMono-Regular.ttf',
    'Fraunces': 'assets/fonts/Fraunces-Variable.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

void main() {
  testWidgets('live chant detail share action at 390 by 844', (tester) async {
    installTolerantGoldenComparator(
      testFile: Uri.base.resolve(
        'test/presentation/browse/chant_share_out_golden_test.dart',
      ),
      // Ubuntu Flutter 3.47.2 differs from the inspected macOS 3.44.8
      // baseline by 1.97% after adding the performance action.
      precisionTolerance: 0.020,
    );
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_User() as User?),
          ),
          chantRepositoryProvider.overrideWithValue(_ChantRepository()),
          commentRepositoryProvider.overrideWithValue(_CommentRepository()),
          profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
          voteRepositoryProvider.overrideWithValue(_VoteRepository()),
          blockedUserIdsProvider.overrideWith(
            (ref, uid) => Stream.value(const <String>{}),
          ),
          savedSongbookProvider.overrideWith(
            (ref, uid) async => SavedSongbook.empty(),
          ),
          chantShareGatewayProvider.overrideWithValue(_ShareGateway()),
          publicShareRepositoryProvider.overrideWithValue(
            PublicShareRepository(
              resolver: (_, id) async =>
                  Uri.parse('https://chantsfc.com/chants/$id'),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ChantTheme.dark,
          home: ChantDetailScreen(chant: _chant, team: _team),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chant_detail_share.png'),
    );
  });
}
