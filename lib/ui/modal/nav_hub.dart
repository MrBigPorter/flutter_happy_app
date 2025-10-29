import 'package:flutter/material.dart';

/// NavHub
/// 全局 NavigatorKey，用于统一弹层、路由、对话框、BottomSheet 的根导航。
class NavHub {
  static final key = GlobalKey<NavigatorState>();
}