import 'package:chants/data/models/performance_draft.dart';
import 'package:chants/data/repositories/performance_draft_repository.dart';
import 'package:chants/data/services/performance_media_selection.dart';
import 'package:flutter_test/flutter_test.dart';

const _media = SelectedPerformanceMedia(
  filePath: '/tmp/performance.mp4',
  fileName: 'performance.mp4',
  contentType: 'video/mp4',
  sizeBytes: 42,
  durationMs: 12000,
);

void main() {
  test('creates the exact server-owned draft request', () async {
    final calls = <(String, Map<String, Object>)>[];
    final repository = PerformanceDraftRepository(
      invoker: (callable, payload) async {
        calls.add((callable, payload));
        return {
          'draftId': 'draft-1',
          'uploadPath': 'performance-staging/fan/draft-1/source',
        };
      },
      uploader: ({required ticket, required media, required ownerId}) =>
          throw UnimplementedError(),
    );

    final ticket = await repository.createDraft(
      chantId: 'chant-1',
      caption: 'First take.',
      media: _media,
    );

    expect(ticket.draftId, 'draft-1');
    expect(calls, hasLength(1));
    expect(calls.single.$1, 'createPerformanceDraft');
    expect(calls.single.$2, {
      'chantId': 'chant-1',
      'caption': 'First take.',
      'contentType': 'video/mp4',
      'sizeBytes': 42,
      'durationMs': 12000,
    });
  });

  test('passes only the server ticket into the uploader boundary', () async {
    PerformanceDraftTicket? receivedTicket;
    SelectedPerformanceMedia? receivedMedia;
    String? receivedOwner;
    final repository = PerformanceDraftRepository(
      invoker: (_, _) async => const {},
      uploader: ({required ticket, required media, required ownerId}) {
        receivedTicket = ticket;
        receivedMedia = media;
        receivedOwner = ownerId;
        return PerformanceUploadHandle(
          completion: Future.value(),
          progress: Stream.value(1),
          cancel: () async => true,
        );
      },
    );
    const ticket = PerformanceDraftTicket(
      draftId: 'draft-1',
      uploadPath: 'performance-staging/fan/draft-1/source',
    );

    final handle = repository.upload(
      ticket: ticket,
      media: _media,
      ownerId: 'fan',
    );
    await handle.completion;

    expect(receivedTicket, same(ticket));
    expect(receivedMedia, same(_media));
    expect(receivedOwner, 'fan');
  });

  test(
    'uses exact submit, cancel, moderation, and preview callables',
    () async {
      final calls = <(String, Map<String, Object>)>[];
      final repository = PerformanceDraftRepository(
        invoker: (callable, payload) async {
          calls.add((callable, payload));
          return callable == 'resolvePerformanceDraftPlayback'
              ? {'url': 'https://signed.example.test/media'}
              : const {};
        },
        uploader: ({required ticket, required media, required ownerId}) =>
            throw UnimplementedError(),
      );

      await repository.submit('draft-1');
      await repository.cancel('draft-2');
      await repository.moderate(
        draftId: 'draft-3',
        approve: false,
        reason: 'Policy issue.',
      );
      final preview = await repository.resolveDraftPlayback('draft-4');

      expect(preview.scheme, 'https');
      expect(calls.map((call) => call.$1), [
        'submitPerformanceDraft',
        'cancelPerformanceDraft',
        'moderatePerformance',
        'resolvePerformanceDraftPlayback',
      ]);
      expect(calls[0].$2, {'draftId': 'draft-1'});
      expect(calls[1].$2, {'draftId': 'draft-2'});
      expect(calls[2].$2, {
        'draftId': 'draft-3',
        'action': 'reject',
        'reason': 'Policy issue.',
      });
      expect(calls[3].$2, {'draftId': 'draft-4'});
    },
  );

  test('injected owner and review streams remain separate', () async {
    final owners = <String>[];
    final repository = PerformanceDraftRepository(
      invoker: (_, _) async => const {},
      uploader: ({required ticket, required media, required ownerId}) =>
          throw UnimplementedError(),
      ownerDraftsLoader: (ownerId) {
        owners.add(ownerId);
        return Stream.value(const []);
      },
      reviewQueueLoader: () => Stream.value(const []),
    );

    expect(await repository.draftsForOwner('fan').first, isEmpty);
    expect(await repository.pendingReviewQueue().first, isEmpty);
    expect(owners, ['fan']);
  });
}
