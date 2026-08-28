import 'package:cloud_functions/cloud_functions.dart';

enum PublicShareTarget { chant, performance, creator }

typedef PublicDestinationResolver =
    Future<Uri> Function(PublicShareTarget target, String targetId);

class PublicShareRepository {
  final PublicDestinationResolver _resolver;

  PublicShareRepository({
    FirebaseFunctions? functions,
    PublicDestinationResolver? resolver,
  }) : _resolver =
           resolver ??
           _firebaseResolver(
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west2'),
           );

  static PublicDestinationResolver _firebaseResolver(
    FirebaseFunctions functions,
  ) {
    return (target, targetId) async {
      final result = await functions
          .httpsCallable('resolvePublicShareDestination')
          .call({'targetType': target.name, 'targetId': targetId});
      final data = result.data;
      if (data is! Map || data['url'] is! String) {
        throw const FormatException('Public destination is unavailable.');
      }
      final uri = Uri.tryParse(data['url'] as String);
      if (uri == null || uri.scheme != 'https' || uri.host != 'chantsfc.com') {
        throw const FormatException('Public destination is unavailable.');
      }
      return uri;
    };
  }

  Future<Uri> resolve(PublicShareTarget target, String targetId) {
    return _resolver(target, targetId);
  }
}
