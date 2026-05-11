// Web-only implementation registered via PwaHelperPlatform.setInstance()
// Called from main.dart on web builds.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

import 'pwa_helper.dart';

/// Register this on web platform before the app starts.
void registerPwaHelperWeb() {
  PwaHelperPlatform.setInstance(PwaHelperWeb());
}

class PwaHelperWeb extends PwaHelperPlatform {
  @override
  bool get canInstall {
    try {
      final v = (web.window as JSObject).getProperty('__pwaInstallReady'.toJS);
      if (v.isUndefinedOrNull) return false;
      return (v as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> promptInstall() async {
    try {
      final result = (web.window as JSObject).callMethod<JSBoolean>(
        'triggerPwaInstall'.toJS,
      );
      return result.toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get updateAvailable {
    try {
      final v = (web.window as JSObject).getProperty('__pwaUpdateReady'.toJS);
      if (v.isUndefinedOrNull) return false;
      return (v as JSBoolean).toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  void removeAppShell() {
    try {
      (web.window as JSObject).callMethod<JSAny?>('__removeAppShell'.toJS);
    } catch (_) {}
  }

  @override
  void applyUpdate() {
    try {
      final hasHook = (web.window as JSObject)
          .hasProperty('applyPwaUpdate'.toJS)
          .toDart;
      if (hasHook) {
        (web.window as JSObject).callMethod<JSAny?>('applyPwaUpdate'.toJS);
        return;
      }
      (web.window as JSObject).setProperty('__pwaUpdateReady'.toJS, false.toJS);
      web.window.location.reload();
    } catch (_) {}
  }

  @override
  Future<void> checkForUpdate() async {
    try {
      final hasHook = (web.window as JSObject)
          .hasProperty('forcePwaUpdateCheck'.toJS)
          .toDart;
      if (hasHook) {
        (web.window as JSObject).callMethod<JSAny?>('forcePwaUpdateCheck'.toJS);
      }
    } catch (_) {}
  }

  @override
  bool get isInstalledPwa {
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }
}
