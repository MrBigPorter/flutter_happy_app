import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';

class OverlayManager {
  OverlayManager._privateConstructor();
  static final OverlayManager instance = OverlayManager._privateConstructor();

  OverlayEntry? _currentEntry;


  // 3. 改用 getter 直接获取现有的 NavHub.key
  // 这样 OverlayManager 就能操作现有的路由栈，而不破坏原有逻辑
  GlobalKey<NavigatorState> get navigatorKey => NavHub.key;

  /// 显示悬浮窗
  void show({required Widget widget}) {
    hide(); // 先清理旧的

    // 直接使用 navKey 获取 Overlay
    final overlayState = navigatorKey.currentState?.overlay;

    if (overlayState == null) {
      debugPrint(" OverlayManager Error: NavigatorState is null. Is NavHub.key attached?");
      return;
    }

    _currentEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: widget,
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  /// 隐藏悬浮窗
  void hide() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }

  bool get isShowing => _currentEntry != null;
}