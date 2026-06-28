import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:chants/app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check: debug provider for dev, real providers for release (C14)
  // Non-blocking so a token failure never prevents startup or auth.
  try {
    debugPrint('[AppCheck] Activating — kDebugMode=$kDebugMode');
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.debug,
        androidProvider: AndroidProvider.debug,
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        androidProvider: AndroidProvider.playIntegrity,
      );
    }
    debugPrint('[AppCheck] Activated successfully');
  } catch (e, st) {
    debugPrint('[AppCheck] Activation failed (non-blocking): $e');
    debugPrint('[AppCheck] $st');
  }

  // Crashlytics (D4): capture Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ProviderScope(child: ChantApp()));
}
