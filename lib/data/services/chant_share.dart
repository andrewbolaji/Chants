import 'dart:ui';

import 'package:chants/data/models/chant.dart';
import 'package:share_plus/share_plus.dart';

class ChantSharePayload {
  final String title;
  final String subject;
  final String text;

  const ChantSharePayload({
    required this.title,
    required this.subject,
    required this.text,
  });

  factory ChantSharePayload.fromChant({
    required Chant chant,
    String? teamName,
    Uri? publicUrl,
  }) {
    final title = _normalize(chant.title);
    final knownTeam = _normalize(teamName ?? '');
    final lyrics = _normalize(chant.lyrics);
    final tuneName = _normalize(chant.tuneName);
    final header = [title, if (knownTeam.isNotEmpty) knownTeam].join('\n');
    final tuneAndTrust = ['Tune: $tuneName', _trustLine(chant)].join('\n');
    final validPublicUrl = _validPublicUrl(publicUrl);

    return ChantSharePayload(
      title: 'Share $title',
      subject: '$title | Chants',
      text: [
        header,
        lyrics,
        tuneAndTrust,
        if (validPublicUrl != null) validPublicUrl.toString(),
        'Shared from Chants',
      ].join('\n\n'),
    );
  }

  static String _normalize(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  static String _trustLine(Chant chant) {
    if (chant.status == 'canonical') return 'Terrace Proven';
    return switch (chant.origin) {
      ChantOrigin.alreadySung =>
        'Chant Lab: Already sung, not yet Terrace Proven',
      ChantOrigin.originalIdea => 'Chant Lab: Original idea',
      null => 'Chant Lab: Community chant',
    };
  }

  static Uri? _validPublicUrl(Uri? value) {
    if (value == null ||
        value.scheme.toLowerCase() != 'https' ||
        value.host.isEmpty) {
      return null;
    }
    return value;
  }
}

bool isValidSharePositionOrigin(Rect origin) {
  return origin.width > 0 &&
      origin.height > 0 &&
      origin.left.isFinite &&
      origin.top.isFinite &&
      origin.right.isFinite &&
      origin.bottom.isFinite;
}

abstract interface class ChantShareGateway {
  Future<void> share(
    ChantSharePayload payload, {
    required Rect sharePositionOrigin,
  });
}

typedef SharePlatformCall = Future<ShareResult> Function(ShareParams params);

class PlatformChantShareGateway implements ChantShareGateway {
  final SharePlatformCall _platformCall;

  PlatformChantShareGateway({SharePlatformCall? platformCall})
    : _platformCall = platformCall ?? SharePlus.instance.share;

  @override
  Future<void> share(
    ChantSharePayload payload, {
    required Rect sharePositionOrigin,
  }) async {
    if (!isValidSharePositionOrigin(sharePositionOrigin)) {
      throw StateError('Share position origin must be non-zero and finite.');
    }

    await _platformCall(
      ShareParams(
        title: payload.title,
        subject: payload.subject,
        text: payload.text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
