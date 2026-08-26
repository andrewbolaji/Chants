import 'dart:ui';

import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

Chant _chant({
  String title = 'North Bank Song',
  String lyrics = 'Sing it loud\nSing it proud',
  String tuneName = 'Traditional',
  String status = 'canonical',
  ChantOrigin? origin,
}) {
  return Chant(
    id: 'arsenal-north-bank-song',
    title: title,
    sportId: 'football',
    competitionId: 'premier-league',
    teamId: 'arsenal',
    subjectTag: 'club',
    lyrics: lyrics,
    tuneName: tuneName,
    contextNotes: 'Do not share this context.',
    coverImageUrl: 'https://example.com/cover.png',
    mediaUrl: 'https://example.com/media.mp4',
    mediaType: 'crowdClip',
    status: status,
    chantType: 'sincere',
    origin: origin,
    evidence: const ChantEvidence(
      provider: EvidenceProvider.youtube,
      url: 'https://www.youtube.com/watch?v=abcdefghijk',
    ),
    upvotes: 100,
    downvotes: 2,
    score: 98,
    commentCount: 12,
    createdBy: 'private-user-id',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
    flagCount: 1,
    variations: const [
      ChantVariation(label: 'Away', lyric: 'Do not share this variation.'),
    ],
  );
}

void main() {
  group('ChantSharePayload', () {
    test('builds a complete text fallback with known team', () {
      final payload = ChantSharePayload.fromChant(
        chant: _chant(),
        teamName: 'Arsenal',
      );

      expect(payload.title, 'Share North Bank Song');
      expect(payload.subject, 'North Bank Song | Chants');
      expect(
        payload.text,
        'North Bank Song\n'
        'Arsenal\n\n'
        'Sing it loud\n'
        'Sing it proud\n\n'
        'Tune: Traditional\n'
        'Terrace Proven\n\n'
        'Shared from Chants',
      );
      expect(payload.text, isNot(contains('private-user-id')));
      expect(payload.text, isNot(contains('youtube.com')));
      expect(payload.text, isNot(contains('Do not share this context.')));
      expect(payload.text, isNot(contains('Do not share this variation.')));
      expect(payload.text, isNot(contains('98')));
    });

    test('uses honest trust wording for every community origin', () {
      final cases = <ChantOrigin?, String>{
        ChantOrigin.alreadySung:
            'Chant Lab: Already sung, not yet Terrace Proven',
        ChantOrigin.originalIdea: 'Chant Lab: Original idea',
        null: 'Chant Lab: Community chant',
      };

      for (final entry in cases.entries) {
        final payload = ChantSharePayload.fromChant(
          chant: _chant(status: 'community', origin: entry.key),
        );
        expect(payload.text, contains(entry.value));
        expect(payload.text, isNot(contains('\nTerrace Proven\n')));
      }
    });

    test('omits an unavailable team without an empty header section', () {
      final payload = ChantSharePayload.fromChant(
        chant: _chant(),
        teamName: '  ',
      );

      expect(payload.text, startsWith('North Bank Song\n\nSing it loud'));
    });

    test('normalizes field boundaries and CRLF without rewriting lyrics', () {
      final payload = ChantSharePayload.fromChant(
        chant: _chant(
          title: '  North Bank Song\r\n',
          lyrics: '  First line\r\nSecond line\rThird line  ',
          tuneName: '  Traditional  ',
        ),
        teamName: '  Arsenal  ',
      );

      expect(payload.text, contains('First line\nSecond line\nThird line'));
      expect(payload.text, isNot(contains('\r')));
      expect(payload.text, startsWith('North Bank Song\nArsenal'));
      expect(payload.text, contains('Tune: Traditional'));
    });

    test('appends only a supplied HTTPS public URL', () {
      final valid = ChantSharePayload.fromChant(
        chant: _chant(),
        publicUrl: Uri.parse(
          'https://chantsfc.com/chants/arsenal-north-bank-song',
        ),
      );
      final http = ChantSharePayload.fromChant(
        chant: _chant(),
        publicUrl: Uri.parse(
          'http://chantsfc.com/chants/arsenal-north-bank-song',
        ),
      );
      final hostless = ChantSharePayload.fromChant(
        chant: _chant(),
        publicUrl: Uri.parse('https:///chants/arsenal-north-bank-song'),
      );

      expect(
        valid.text,
        contains('https://chantsfc.com/chants/arsenal-north-bank-song'),
      );
      expect(http.text, isNot(contains('http://')));
      expect(hostless.text, isNot(contains('https:///')));
      expect(http.text, endsWith('Shared from Chants'));
      expect(hostless.text, endsWith('Shared from Chants'));
    });

    test('keeps the accepted maximum main lyrics intact', () {
      final lyrics = List.filled(5000, 'x').join();
      final payload = ChantSharePayload.fromChant(
        chant: _chant(
          title: List.filled(200, 't').join(),
          lyrics: lyrics,
          tuneName: List.filled(200, 'u').join(),
        ),
      );

      expect(payload.text, contains(lyrics));
      expect(payload.text.length, lessThan(5600));
    });
  });

  group('PlatformChantShareGateway', () {
    test('passes the payload and source rectangle to the platform', () async {
      ShareParams? captured;
      final gateway = PlatformChantShareGateway(
        platformCall: (params) async {
          captured = params;
          return const ShareResult('messages', ShareResultStatus.success);
        },
      );
      const origin = Rect.fromLTWH(300, 20, 48, 48);
      final payload = ChantSharePayload.fromChant(chant: _chant());

      await gateway.share(payload, sharePositionOrigin: origin);

      expect(captured?.title, payload.title);
      expect(captured?.subject, payload.subject);
      expect(captured?.text, payload.text);
      expect(captured?.sharePositionOrigin, origin);
      expect(captured?.files, isNull);
      expect(captured?.uri, isNull);
    });

    test(
      'accepts dismissed and result-unavailable platform outcomes',
      () async {
        for (final result in const [
          ShareResult('', ShareResultStatus.dismissed),
          ShareResult.unavailable,
        ]) {
          final gateway = PlatformChantShareGateway(
            platformCall: (_) async => result,
          );

          await expectLater(
            gateway.share(
              ChantSharePayload.fromChant(chant: _chant()),
              sharePositionOrigin: const Rect.fromLTWH(1, 1, 48, 48),
            ),
            completes,
          );
        }
      },
    );

    test(
      'rejects an unusable source rectangle before the platform call',
      () async {
        var callCount = 0;
        final gateway = PlatformChantShareGateway(
          platformCall: (_) async {
            callCount += 1;
            return ShareResult.unavailable;
          },
        );

        await expectLater(
          gateway.share(
            ChantSharePayload.fromChant(chant: _chant()),
            sharePositionOrigin: Rect.zero,
          ),
          throwsStateError,
        );
        expect(callCount, 0);
      },
    );
  });
}
