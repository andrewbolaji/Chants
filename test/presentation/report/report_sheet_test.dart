import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chants/app/providers.dart';
import 'package:chants/data/repositories/comment_repository.dart';
import 'package:chants/data/repositories/report_repository.dart';
import 'package:chants/data/repositories/user_report_repository.dart';
import 'package:chants/presentation/report/report_sheet.dart';

// --- Fakes (write boundary only, no logic reimplementation) ---

class _MockUser extends Mock implements User {
  @override
  String get uid => 'reporter-1';
}

class _FakeReportRepository implements ReportRepository {
  String? lastChantId;
  String? lastReportedBy;
  String? lastReason;

  @override
  Future<void> submitReport({
    required String chantId,
    required String reportedBy,
    required String reason,
  }) async {
    lastChantId = chantId;
    lastReportedBy = reportedBy;
    lastReason = reason;
  }

  @override
  Future<bool> hasReported(
      {required String userId, required String chantId}) async {
    return false;
  }
}

class _FakeCommentRepository implements CommentRepository {
  String? lastCommentId;
  String? lastReportedBy;
  String? lastReason;

  @override
  Future<void> submitCommentReport({
    required String commentId,
    required String reportedBy,
    required String reason,
  }) async {
    lastCommentId = commentId;
    lastReportedBy = reportedBy;
    lastReason = reason;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserReportRepository implements UserReportRepository {
  String? lastReportedUserId;
  String? lastReportedBy;
  String? lastReason;

  @override
  Future<void> submitUserReport({
    required String reportedUserId,
    required String reportedBy,
    required String reason,
  }) async {
    lastReportedUserId = reportedUserId;
    lastReportedBy = reportedBy;
    lastReason = reason;
  }

  @override
  Future<bool> hasReportedUser(
      {required String userId, required String reportedUserId}) async {
    return false;
  }
}

void main() {
  final fakeUser = _MockUser();

  group('showReportSheet', () {
    testWidgets('chant mode calls ReportRepository.submitReport',
        (tester) async {
      final reportRepo = _FakeReportRepository();
      final commentRepo = _FakeCommentRepository();
      final userReportRepo = _FakeUserReportRepository();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(reportRepo),
          commentRepositoryProvider.overrideWithValue(commentRepo),
          userReportRepositoryProvider.overrideWithValue(userReportRepo),
          authStateProvider.overrideWith(
            (ref) => Stream.value(fakeUser as User?),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(authStateProvider); // warm up before the sheet reads it
              return Scaffold(
                body: FilledButton(
                  onPressed: () => showReportSheet(
                    context: context,
                    target: const ReportChant('chant-1'),
                    ref: ref,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Report this chant'), findsWidgets);

      await tester.tap(find.text('Hate speech or slurs'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Report this chant'));
      await tester.pump();
      await tester.pump();

      expect(reportRepo.lastChantId, 'chant-1');
      expect(reportRepo.lastReportedBy, 'reporter-1');
      expect(commentRepo.lastCommentId, null);
      expect(userReportRepo.lastReportedUserId, null);
    });

    testWidgets('comment mode calls CommentRepository.submitCommentReport',
        (tester) async {
      final reportRepo = _FakeReportRepository();
      final commentRepo = _FakeCommentRepository();
      final userReportRepo = _FakeUserReportRepository();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(reportRepo),
          commentRepositoryProvider.overrideWithValue(commentRepo),
          userReportRepositoryProvider.overrideWithValue(userReportRepo),
          authStateProvider.overrideWith(
            (ref) => Stream.value(fakeUser as User?),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(authStateProvider); // warm up before the sheet reads it
              return Scaffold(
                body: FilledButton(
                  onPressed: () => showReportSheet(
                    context: context,
                    target: const ReportComment('comment-1'),
                    ref: ref,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Report this comment'), findsWidgets);

      await tester.tap(find.text('Threats or targeting'));
      await tester.pump();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Report this comment'));
      await tester.pump();
      await tester.pump();

      expect(commentRepo.lastCommentId, 'comment-1');
      expect(commentRepo.lastReportedBy, 'reporter-1');
      expect(reportRepo.lastChantId, null);
      expect(userReportRepo.lastReportedUserId, null);
    });

    testWidgets('user mode calls UserReportRepository.submitUserReport',
        (tester) async {
      final reportRepo = _FakeReportRepository();
      final commentRepo = _FakeCommentRepository();
      final userReportRepo = _FakeUserReportRepository();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(reportRepo),
          commentRepositoryProvider.overrideWithValue(commentRepo),
          userReportRepositoryProvider.overrideWithValue(userReportRepo),
          authStateProvider.overrideWith(
            (ref) => Stream.value(fakeUser as User?),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(authStateProvider); // warm up before the sheet reads it
              return Scaffold(
                body: FilledButton(
                  onPressed: () => showReportSheet(
                    context: context,
                    target: const ReportUser('bad-actor-1'),
                    ref: ref,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Report this user'), findsWidgets);

      await tester.tap(find.text('Something else'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Report this user'));
      await tester.pump();
      await tester.pump();

      expect(userReportRepo.lastReportedUserId, 'bad-actor-1');
      expect(userReportRepo.lastReportedBy, 'reporter-1');
      expect(reportRepo.lastChantId, null);
      expect(commentRepo.lastCommentId, null);
    });
  });
}
