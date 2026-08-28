import 'dart:ui';

import 'package:chants/data/models/creator_profile.dart';
import 'package:chants/data/services/chant_share.dart';
import 'package:share_plus/share_plus.dart';

class CreatorSharePayload {
  final String title;
  final String subject;
  final String text;

  const CreatorSharePayload({
    required this.title,
    required this.subject,
    required this.text,
  });

  factory CreatorSharePayload.fromCreator({
    required CreatorProfile creator,
    required Uri publicUrl,
  }) {
    if (publicUrl.scheme != 'https' || publicUrl.host != 'chantsfc.com') {
      throw ArgumentError.value(publicUrl, 'publicUrl');
    }
    final name = _normalize(creator.displayName);
    final handle = _normalize(creator.handle);
    return CreatorSharePayload(
      title: 'Share @$handle',
      subject: '$name on Chants',
      text: [
        '$name (@$handle)',
        'Creator on Chants',
        publicUrl.toString(),
        'See their chant performances on Chants',
      ].join('\n\n'),
    );
  }

  static String _normalize(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }
}

abstract interface class CreatorShareGateway {
  Future<void> share(
    CreatorSharePayload payload, {
    required Rect sharePositionOrigin,
  });
}

class PlatformCreatorShareGateway implements CreatorShareGateway {
  final SharePlatformCall _platformCall;

  PlatformCreatorShareGateway({SharePlatformCall? platformCall})
    : _platformCall = platformCall ?? SharePlus.instance.share;

  @override
  Future<void> share(
    CreatorSharePayload payload, {
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
