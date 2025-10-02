import 'package:flutter/material.dart';
import 'package:flutter_app/theme/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ButtonVariant { normal, error }

/// 通用按钮组件 - normal / error 两种样式 + loading 状态 normal/error button with loading
/// 主要功能：
/// 1. 支持 normal 和 error 两种样式  support normal and error styles
/// 2. 支持 loading 状态，显示加载动画 support loading state with spinner
/// 3. 支持自定义高度、内边距、背景图片、圆角 custom height, padding, background image, border radius
/// 4. 支持禁用状态 disabled state
/// 5. 支持无点击动画效果 no press animation effect
/// 参数说明: parameters:
/// - child: 按钮内容 button content
/// - onPressed: 点击回调 click callback
/// - variant: 按钮样式，normal / error
/// - loading: 是否显示加载动画 show loading spinner
/// - noPressAnimation: 是否禁用点击动画效果 disable press animation
/// - height: 按钮高度 button height
/// - padding: 按钮内边距 button padding
/// - backgroundImage: 按钮背景图片 button background image
/// - borderRadius: 按钮圆角 button border radius
/// 示例:
/// ```dart
/// EnterButton(
///  child: Text('Submit'),
///  onPressed: () { /* Handle press */ },
///  variant: ButtonVariant.normal,
///  loading: false,
///  noPressAnimation: false,
///  height: 48,
///  padding: EdgeInsets.symmetric(horizontal: 16),
///  backgroundImage: AssetImage('assets/button_bg.png'),
///  borderRadius: BorderRadius.circular(8),
///  )
///  ```
class EnterButton extends StatefulWidget {
  /// EnterButton - 通用按钮组件
  final Widget child;

  /// 按钮点击回调 click callback
  final VoidCallback? onPressed;

  /// 按钮样式，normal / error button style: normal / error
  final ButtonVariant variant;

  /// 是否显示加载动画 show loading spinner
  final bool loading;

  /// 是否禁用点击动画效果 disable press animation
  final bool noPressAnimation;

  /// 按钮高度 button height
  final double? height;

  /// 按钮内边距 button padding
  final EdgeInsets? padding;

  /// 按钮背景图片 button background image
  final ImageProvider? backgroundImage;

  /// 按钮圆角 button border radius
  final BorderRadius? borderRadius;

  final int pressDelayMs = 60;
  final int cooldownMs = 250;

  const EnterButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.normal,
    this.loading = false,
    this.noPressAnimation = false,
    this.height = 49,
    this.padding,
    this.backgroundImage,
    this.borderRadius,
  });

  @override
  State<EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<EnterButton> {
  bool _pressing = false;
  bool _locked = false;

  void _setPress(bool pressing) {
    setState(() {
      _pressing = pressing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    final radius = widget.borderRadius ?? BorderRadius.circular(8);

    final (Color bg, Color txt, Color border) = switch (widget.variant) {
      ButtonVariant.normal => (
        context.utilityBrand500,
        Colors.white,
        Colors.white.withAlpha(12),
      ),
      ButtonVariant.error => (
        context.utilityError500,
        Colors.white,
        Colors.white.withAlpha(12),
      ),
    };

    final double scale = widget.noPressAnimation
        ? 1.0
        : (_pressing ? 0.85 : 1.0);

    final double boxH = (widget.height ?? 49).w; // 统一用 .w

    return SizedBox(
      width: 120.w,
      height: boxH,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: disabled ? 0.7 : 1.0,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                border: Border.all(color: Colors.white.withAlpha(12), width: 2),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: .5,
                    offset: Offset(0, .5),
                    color: Color(0x99000000),
                  ),
                ],
                image: widget.backgroundImage == null
                    ? null
                    : DecorationImage(
                        image: widget.backgroundImage!,
                        fit: BoxFit.cover,
                      ),
              ),
              // 👇 关键：让 InkWell 铺满
              child: SizedBox.expand(
                child: InkWell(
                  borderRadius: radius,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  // 用 Tap 事件切 pressing，最稳定
                  onTapDown: disabled ? null : (_) => _setPress(true),
                  onTapUp: disabled ? null : (_) => _setPress(false),
                  onTapCancel: disabled ? null : () => _setPress(false),
                  onTap: disabled
                      ? null
                      : () async {
                          _locked = true;
                          setState(() {});
                          await Future.delayed(
                            Duration(milliseconds: widget.pressDelayMs),
                          );

                          widget.onPressed?.call();

                          await Future.delayed(Duration(milliseconds: 80));
                          if (mounted) _setPress(false);

                          await Future.delayed(
                            Duration(milliseconds: widget.cooldownMs),
                          );
                          if (mounted) {
                            setState(() {
                              _locked = false;
                            });
                          }
                        },
                  child: Padding(
                    padding:
                        widget.padding ??
                        EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.loading) ...[
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: AlwaysStoppedAnimation<Color>(txt),
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        DefaultTextStyle(
                          style: TextStyle(
                            color: txt,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          child: widget.child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
