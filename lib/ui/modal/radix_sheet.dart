import 'package:flutter/material.dart';
import 'modal_service.dart';
import 'sheet_props.dart';

/// RadixSheet
/// ------------------------------------------------------------------
/// 统一封装底部弹窗的调用入口。
/// - 内部使用 ModalService 实现 showModalBottomSheet
/// - 自动支持点击背景关闭、拖动关闭、圆角样式、主题同步
/// - 不内置滚动逻辑（由内容决定）
///
/// ✅ 短内容自动自适应高度
/// ✅ 长内容需外部包 SingleChildScrollView
/// ------------------------------------------------------------------
class RadixSheet {
  static Future<T?> show<T>({
    required Widget Function(BuildContext context, void Function([T? res]) close) builder,
    bool clickBgToClose = true,
    bool showClose = true,
    ModalSheetConfig? config,
  }) {
    // 使用统一的 ModalService，负责管理展示与关闭逻辑
    return ModalService.instance.showSheet<T>(
      builder: builder,
      clickBgToClose: clickBgToClose,
      config: config ?? const ModalSheetConfig(),
    );
  }
}