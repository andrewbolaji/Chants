import 'dart:ui';

import 'package:chants/data/models/performance.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:share_plus/share_plus.dart';

class PerformanceSharePayload {
  final String title;
  final String subject;
  final String text;

  const PerformanceSharePayload({
    required this.title,
    required this.subject,
    required this.text,
  });

  factory PerformanceSharePayload.fromPerformance({
    required Performance performance,
    required Uri publicUrl,
  }) {
    if (publicUrl.scheme != 'https' || publicUrl.host != 'chantsfc.com') {
      throw ArgumentError.value(publicUrl, 'publicUrl');
    }
    final trust = performance.isTerraceProven
        ? 'Terrace Proven chant'
        : 'Chant Lab idea';
    final chantTitle = _normalize(performance.chantTitle);
    final creatorName = _normalize(performance.creatorDisplayName);
    final creatorHandle = _normalize(performance.creatorHandle);
    final subject = _normalize(performance.playerName ?? performance.teamName);
    final caption = _normalize(performance.caption);
    return PerformanceSharePayload(
      title: 'Share $chantTitle',
      subject: '$creatorName on Chants',
      text: [
        chantTitle,
        '$subject · $trust',
        'Performed by $creatorName (@$creatorHandle)',
        if (caption.isNotEmpty) caption,
        publicUrl.toString(),
        'Watch on Chants',
      ].join('\n\n'),
    );
  }

  static String _normalize(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }
}

abstract interface class PerformanceShareGateway {
  Future<bool> share(
    PerformanceSharePayload payload, {
    required Rect sharePositionOrigin,
  });
}

class PlatformPerformanceShareGateway implements PerformanceShareGateway {
  final SharePlatformCall _platformCall;

  PlatformPerformanceShareGateway({SharePlatformCall? platformCall})
    : _platformCall = platformCall ?? SharePlus.instance.share;

  @override
  Future<bool> share(
    PerformanceSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    if (!isValidSharePositionOrigin(sharePositionOrigin)) {
      throw StateError('Share position origin must be non-zero and finite.');
    }
    final result = await _platformCall(
      ShareParams(
        title: payload.title,
        subject: payload.subject,
        text: payload.text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}
