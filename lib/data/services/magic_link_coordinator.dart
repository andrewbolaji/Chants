import 'dart:async';

import 'package:app_links/app_links.dart';

class MagicLinkCoordinator {
  final AppLinks _appLinks;

  MagicLinkCoordinator({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  Stream<Uri> links() async* {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) yield initial;
    yield* _appLinks.uriLinkStream;
  }
}
