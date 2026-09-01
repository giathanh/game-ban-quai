import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Forces device orientation on phones/tablets. No-op on web and desktop, where
/// [SystemChrome.setPreferredOrientations] does nothing useful anyway.
///
/// The playfield uses a fixed 5:3 (landscape) camera, so the round plays in
/// landscape while every menu stays portrait.
class OrientationLock {
  OrientationLock._();

  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> landscape() {
    if (!_isMobile) return Future<void>.value();
    return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> portrait() {
    if (!_isMobile) return Future<void>.value();
    return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }
}
