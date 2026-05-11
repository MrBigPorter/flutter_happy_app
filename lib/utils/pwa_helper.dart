import 'package:flutter/foundation.dart';

/// PWA utility — wraps browser install prompt and SW update signals.
/// All methods are safe to call on native (iOS/Android) — they return
/// false/no-op when [kIsWeb] is false.
abstract class PwaHelper {
  /// True if the browser has a pending "Add to Home Screen" prompt.
  static bool get canInstall {
    if (!kIsWeb) return false;
    return PwaHelperPlatform.instance.canInstall;
  }

  /// Shows the browser's native install prompt.
  static Future<bool> promptInstall() {
    if (!kIsWeb) return Future.value(false);
    return PwaHelperPlatform.instance.promptInstall();
  }

  /// True if a newer Service Worker version is waiting to activate.
  static bool get updateAvailable {
    if (!kIsWeb) return false;
    return PwaHelperPlatform.instance.updateAvailable;
  }

  /// Reloads the page so the waiting SW activates.
  static void applyUpdate() {
    if (!kIsWeb) return;
    PwaHelperPlatform.instance.applyUpdate();
  }

  /// Triggers a service worker update check.
  static Future<void> checkForUpdate() {
    if (!kIsWeb) return Future.value();
    return PwaHelperPlatform.instance.checkForUpdate();
  }

  /// True when running in standalone (installed PWA) mode.
  static bool get isInstalledPwa {
    if (!kIsWeb) return false;
    return PwaHelperPlatform.instance.isInstalledPwa;
  }

  /// Removes the App Shell overlay from the DOM (web only).
  /// Call from a post-frame callback after Flutter's first frame is painted
  /// so there is zero blank gap between App Shell disappearance and Flutter
  /// content becoming visible.
  static void removeAppShell() {
    if (!kIsWeb) return;
    PwaHelperPlatform.instance.removeAppShell();
  }
}

/// Platform interface — replaced by [PwaHelperWeb] on web builds.
class PwaHelperPlatform {
  static PwaHelperPlatform _instance = PwaHelperPlatform();
  static PwaHelperPlatform get instance => _instance;
  // ignore: use_setters_to_change_properties
  static void setInstance(PwaHelperPlatform impl) => _instance = impl;

  bool get canInstall => false;
  Future<bool> promptInstall() async => false;
  bool get updateAvailable => false;
  void applyUpdate() {}
  Future<void> checkForUpdate() async {}
  bool get isInstalledPwa => false;
  void removeAppShell() {}
}
