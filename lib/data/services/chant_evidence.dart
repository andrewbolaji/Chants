import 'package:chants/data/models/chant.dart';

class EvidenceParseResult {
  final ChantEvidence? evidence;
  final String? error;

  const EvidenceParseResult._({this.evidence, this.error});

  const EvidenceParseResult.valid([ChantEvidence? evidence])
    : this._(evidence: evidence);

  const EvidenceParseResult.invalid(String error) : this._(error: error);

  bool get isValid => error == null;
}

abstract final class ChantEvidenceParser {
  static final RegExp _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final RegExp _xHandle = RegExp(r'^[A-Za-z0-9_]{1,15}$');
  static final RegExp _xStatusId = RegExp(r'^[0-9]{1,25}$');
  static final RegExp _explicitPort = RegExp(
    r'^https://[^/?#]+:[0-9]+(?:[/?#]|$)',
    caseSensitive: false,
  );

  static const Set<String> _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
  };

  static const Set<String> _shortYoutubeHosts = {'youtu.be', 'www.youtu.be'};

  static const Set<String> _xHosts = {
    'x.com',
    'www.x.com',
    'mobile.x.com',
    'twitter.com',
    'www.twitter.com',
    'mobile.twitter.com',
  };

  static EvidenceParseResult parseOptional(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const EvidenceParseResult.valid();

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.userInfo.isNotEmpty ||
        _explicitPort.hasMatch(trimmed)) {
      return const EvidenceParseResult.invalid(
        'Use a full HTTPS link from YouTube or X.',
      );
    }

    final host = uri.host.toLowerCase();
    if (_youtubeHosts.contains(host) || _shortYoutubeHosts.contains(host)) {
      return _parseYoutube(uri, host);
    }
    if (_xHosts.contains(host)) return _parseX(uri);

    return const EvidenceParseResult.invalid(
      'For v1, evidence links must be from YouTube or X.',
    );
  }

  static bool isCanonical(ChantEvidence? evidence) {
    if (evidence == null) return false;
    final parsed = parseOptional(evidence.url);
    return parsed.isValid &&
        parsed.evidence?.provider == evidence.provider &&
        parsed.evidence?.url == evidence.url;
  }

  static EvidenceParseResult _parseYoutube(Uri uri, String host) {
    String? videoId;
    if (_shortYoutubeHosts.contains(host)) {
      if (uri.pathSegments.length == 1) videoId = uri.pathSegments.single;
    } else if (uri.pathSegments.length == 1 &&
        uri.pathSegments.single == 'watch') {
      videoId = uri.queryParameters['v'];
    } else if (uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'shorts') {
      videoId = uri.pathSegments.last;
    }

    if (videoId == null || !_youtubeId.hasMatch(videoId)) {
      return const EvidenceParseResult.invalid(
        'Use a link to a specific YouTube video or Short.',
      );
    }

    return EvidenceParseResult.valid(
      ChantEvidence(
        provider: EvidenceProvider.youtube,
        url: 'https://www.youtube.com/watch?v=$videoId',
      ),
    );
  }

  static EvidenceParseResult _parseX(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length != 3 ||
        segments[1] != 'status' ||
        !_xHandle.hasMatch(segments[0]) ||
        !_xStatusId.hasMatch(segments[2])) {
      return const EvidenceParseResult.invalid(
        'Use a link to a specific post on X.',
      );
    }

    return EvidenceParseResult.valid(
      ChantEvidence(
        provider: EvidenceProvider.x,
        url: 'https://x.com/${segments[0]}/status/${segments[2]}',
      ),
    );
  }
}
