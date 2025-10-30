import 'package:flutter/cupertino.dart';

typedef VoidCloser = void Function();

class ModalManager extends NavigatorObserver {
  static final ModalManager instance = ModalManager._();
  ModalManager._();

  VoidCloser? _activeCloser;

  void bind(VoidCloser closer)  => _activeCloser = closer;

  void unbind(VoidCloser closer) {
    if(_activeCloser == closer) {
      _activeCloser = null;
    }
  }

  void closeActive() {
    try { _activeCloser?.call(); } catch (_) {}
    _activeCloser = null;
  }

}

///  push、pop、replace、remove 时，自动调用注册的 NavigatorObserver
///  when push, pop, replace, remove, automatically call the registered NavigatorObserver
///
class ModalAutoCloseObserver extends NavigatorObserver {

  void _tryClose() => ModalManager.instance.closeActive();

  @override
  void didPush(Route route, Route? previousRoute) => _tryClose();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _tryClose();
  @override
  void didPop(Route route, Route? previousRoute) => _tryClose();
  @override
  void didRemove(Route route, Route? previousRoute) => _tryClose();
}