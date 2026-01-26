import 'dart:async'; //  1. 必须引入
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/ui/button/index.dart';

/// ModalDialogSurface
/// ------------------------------------------------------------------
/// 🔹 A framework component for dialogs, responsible for rendering title, content, and bottom buttons.
class ModalDialogSurface<T> extends StatefulWidget {
  final ModalDialogConfig config;
  final void Function([T? reslut]) onClose;
  final Widget child;

  //  2. 类型改为 FutureOr，允许传入 async 函数
  final FutureOr<void> Function() onConfirm;
  final FutureOr<void> Function() onCancel;

  final String confirmText;
  final String cancelText;
  final String? title;

  const ModalDialogSurface({
    super.key,
    required this.config,
    required this.onClose,
    required this.child,
    required this.onConfirm,
    required this.onCancel,
    required this.confirmText,
    required this.cancelText,
    required this.title,
  });

  @override
  State<ModalDialogSurface<T>> createState() => _ModalDialogSurfaceState<T>();
}

//  3. 改为 State 类以维护 Loading 状态
class _ModalDialogSurfaceState<T> extends State<ModalDialogSurface<T>> {
  bool _isConfirmLoading = false;
  bool _isCancelLoading = false;

  /// 通用处理函数：自动管理 Loading 状态
  Future<void> _handleAction({
    required bool isConfirm,
    required FutureOr<void> Function() action,
  }) async {
    // 防止重复点击
    if (_isConfirmLoading || _isCancelLoading) return;

    if (mounted) {
      setState(() {
        if (isConfirm) {
          _isConfirmLoading = true;
        } else {
          _isCancelLoading = true;
        }
      });
    }

    try {
      // 等待异步操作完成
      await action();
    } finally {
      // 无论成功失败，恢复按钮状态
      if (mounted) {
        setState(() {
          if (isConfirm) {
            _isConfirmLoading = false;
          } else {
            _isCancelLoading = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFooter = widget.config.footerBuilder != null;
    final hasConfirm = widget.confirmText.isNotEmpty;
    final hasCancel = widget.cancelText.isNotEmpty;
    // XOR，只有一个为 true only one button
    final isSingleButton = (hasConfirm ^ hasCancel);

    // 只要有任何一个按钮在 Loading，就锁定交互
    final isBusy = _isConfirmLoading || _isCancelLoading;

    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header ---
          if (widget.config.headerBuilder != null)
            widget.config.headerBuilder!.call(
                context, ([result]) => widget.onClose(result as T?))
          else
            Container(
              height: widget.config.headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: widget.config.headerBackgroundColor ??
                      context.bgPrimaryAlt,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(widget.config.borderRadius),
                  )),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.title != null)
                    Center(
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 18.w,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary900,
                        ),
                      ),
                    ),
                  if (widget.config.showCloseButton)
                    Positioned(
                      top: 0,
                      right: 10.w,
                      bottom: 0,
                      child: IconButton(
                        //  如果正在 Loading，禁用关闭按钮
                        onPressed: isBusy ? null : () => widget.onClose(),
                        icon: Icon(Icons.close,
                            size: 22.w, color: context.fgPrimary900),
                      ),
                    ),
                ],
              ),
            ),

          // --- Content ---
          Flexible(
            child: Padding(
              padding: widget.config.contentPadding,
              child: widget.child,
            ),
          ),

          // --- Footer ---
          Padding(
            padding: EdgeInsets.all(12.w),
            child: hasFooter
                ? widget.config.footerBuilder!.call(
              context,
                  ([result]) => widget.onClose(result as T?),
            )
                : Row(
              children: [
                if (hasCancel)
                  Expanded(
                    child: Button(
                      variant: ButtonVariant.outline,
                      //  传入 Loading 状态
                      loading: _isCancelLoading,
                      //  忙碌时禁用点击
                      onPressed: isBusy
                          ? null
                          : () => _handleAction(
                        isConfirm: false,
                        action: widget.onCancel,
                      ),
                      child: Text(widget.cancelText),
                    ),
                  ),
                if (!isSingleButton) SizedBox(width: 12.w),
                if (hasConfirm)
                  Expanded(
                    child: Button(
                      //  传入 Loading 状态
                      loading: _isConfirmLoading,
                      //  忙碌时禁用点击
                      onPressed: isBusy
                          ? null
                          : () => _handleAction(
                        isConfirm: true,
                        action: widget.onConfirm,
                      ),
                      child: Text(widget.confirmText),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}