import 'package:flutter_test/flutter_test.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_evidence.dart';

void main() {
  group('ChantEvidenceParser', () {
    test('accepts an empty optional value', () {
      final result = ChantEvidenceParser.parseOptional('  ');
      expect(result.isValid, true);
      expect(result.evidence, isNull);
    });

    test('normalizes supported YouTube inputs', () {
      for (final input in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&utm_source=test',
        'https://m.youtube.com/shorts/dQw4w9WgXcQ?feature=share',
        'https://youtu.be/dQw4w9WgXcQ?t=10',
      ]) {
        final result = ChantEvidenceParser.parseOptional(input);
        expect(result.isValid, true, reason: input);
        expect(result.evidence?.provider, EvidenceProvider.youtube);
        expect(
          result.evidence?.url,
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        );
      }
    });

    test('normalizes supported X and Twitter inputs', () {
      for (final input in [
        'https://x.com/arsenal/status/1234567890?s=20',
        'https://mobile.twitter.com/Arsenal/status/1234567890',
      ]) {
        final result = ChantEvidenceParser.parseOptional(input);
        expect(result.isValid, true, reason: input);
        expect(result.evidence?.provider, EvidenceProvider.x);
        expect(
          result.evidence?.url,
          input.contains('/Arsenal/')
              ? 'https://x.com/Arsenal/status/1234567890'
              : 'https://x.com/arsenal/status/1234567890',
        );
      }
    });

    test('rejects unsupported, deceptive, and non-content URLs', () {
      for (final input in [
        'http://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com.example.test/watch?v=dQw4w9WgXcQ',
        'https://user@www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com:443/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/playlist?list=PL123',
        'https://www.youtube.com/watch?v=short',
        'https://x.com/arsenal',
        'https://x.com/arsenal/status/not-a-number',
        'https://x.com/arsenal/status/12345678901234567890123456',
        'https://example.com/video',
      ]) {
        expect(
          ChantEvidenceParser.parseOptional(input).isValid,
          false,
          reason: input,
        );
      }
    });

    test('recognizes only already-canonical stored evidence', () {
      expect(
        ChantEvidenceParser.isCanonical(
          const ChantEvidence(
            provider: EvidenceProvider.youtube,
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
        ),
        true,
      );
      expect(
        ChantEvidenceParser.isCanonical(
          const ChantEvidence(
            provider: EvidenceProvider.youtube,
            url: 'https://youtu.be/dQw4w9WgXcQ',
          ),
        ),
        false,
      );
      expect(
        ChantEvidenceParser.isCanonical(
          const ChantEvidence(
            provider: EvidenceProvider.x,
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
        ),
        false,
      );
    });
  });
}
