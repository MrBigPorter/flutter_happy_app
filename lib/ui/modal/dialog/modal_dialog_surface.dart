import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/modal/dialog/modal_dialog_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/ui/button/index.dart';


/// ModalDialogSurface
/// ------------------------------------------------------------------
/// 🔹 A framework component for dialogs, responsible for rendering title, content, and bottom buttons.
/// 
/// Features:
/// ✅ Support custom header and footer layouts
/// ✅ Automatically adapt to single/double button layouts
/// ✅ Unified style theme
/// 
/// Parameters:
/// - config: Configure dialog style (border radius, padding, etc.)
/// - onClose: Dialog close callback
/// - child: Dialog main content
/// - onConfirm: Confirm button callback
/// - onCancel: Cancel button callback  
/// - confirmText: Confirm button text
/// - cancelText: Cancel button text
/// - title: Dialog title
class ModalDialogSurface<T> extends StatelessWidget {
  final ModalDialogConfig config;
  final void Function([T? reslut]) onClose;
  final Widget child;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
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
  Widget build(BuildContext context) {
    final hasFooter = config.footerBuilder != null;
    final hasConfirm = confirmText.isNotEmpty;
    final hasCancel = cancelText.isNotEmpty;
    // XOR，只有一个为 true only one button
    final isSingleButton = (hasConfirm ^ hasCancel);
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.headerBuilder != null)
            config.headerBuilder!.call(
              context,([result]) => onClose(result as T?)
            )
          else
            Container(
              height: config.headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: config.headerBackgroundColor ?? context.bgPrimaryAlt,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(config.borderRadius),
                  )
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (title != null)
                    Center(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18.w,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary900,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    right: 10.w,
                    bottom: 0,
                    child: IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close, size: 22.w, color: context.fgPrimary900),
                    ),
                  ),
                ],
              ),
            ),
          Flexible(
            child: Padding(padding: config.contentPadding, child: child),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: hasFooter
                ? config.footerBuilder!.call(
                  context,([result]) => onClose(result as T?),
            )
                : Row(
              children: [
                if (hasCancel)
                  Expanded(
                    child: Button(
                      variant: ButtonVariant.outline,
                      onPressed: onCancel,
                      child: Text(cancelText),
                    ),
                  ),
                if (!isSingleButton) SizedBox(width: 12.w),
                if (hasConfirm)
                  Expanded(
                    child: Button(
                      onPressed: onConfirm,
                      child: Text(confirmText),
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
