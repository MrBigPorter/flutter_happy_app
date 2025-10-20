import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ButtonVariant { secondary, primary, error,custom }

class Button extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final bool disabled;
  final bool loading;
  final bool noPressAnimation;
  final double height;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;

  final double radius;
  final double gap;
  final Widget? leading;
  final Widget? trailing;
  final ButtonVisual? customButtonStyle;
  final TextStyle? textStyle;

  const Button({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.loading = false,
    this.noPressAnimation = false,
    this.height = 48,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.radius = 8,
    this.gap = 8,
    this.leading,
    this.trailing,
    this.customButtonStyle,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.boxShadow,
    this.borderColor,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _isPressed = false;

  ButtonVisual _resolveTheme(BuildContext ctx, ButtonVariant v) {
    switch (v) {
      case ButtonVariant.primary:
        return ButtonVisual(
          bg: ctx.buttonPrimaryBg,
          fg: ctx.textWhite,
          border:  Colors.transparent,
          shadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        );
      case ButtonVariant.error:
        return ButtonVisual(
          bg: ctx.buttonPrimaryErrorBg,
          fg: ctx.textWhite,
          border: const Color(0x1FFFFFFF),
          shadow: [
          ],
        );
      case ButtonVariant.secondary:
        return ButtonVisual(
          bg: ctx.buttonSecondaryBg,
          fg: ctx.textSecondary700,
          border: ctx.buttonSecondaryBorder,
          shadow: [
            BoxShadow(
              color: ctx.bgDisabled,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        );
      case ButtonVariant.custom:
        return ButtonVisual(
          bg: widget.customButtonStyle?.bg ?? ctx.buttonSecondaryBg,
          fg: widget.customButtonStyle?.fg ?? ctx.textSecondary700,
          border: widget.customButtonStyle?.border ?? ctx.buttonSecondaryBorder,
          shadow: widget.customButtonStyle?.shadow ?? [
            BoxShadow(
              color: ctx.bgDisabled,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = _resolveTheme(context, widget.variant);
    final effectiveDisabled =
        widget.disabled || widget.loading || widget.onPressed == null;

    final targetScale = widget.noPressAnimation
        ? 1.0
        : (_isPressed ? 0.92 : 1.0);

    final bg = effectiveDisabled ? widget.backgroundColor ?? theme.bg.withAlpha(180) : theme.bg;
    final fg = widget.foregroundColor??theme.fg;
    final border = widget.borderColor??theme.border;
    final shadow = effectiveDisabled ? const <BoxShadow>[] : widget.boxShadow??theme.shadow;

    // Default text style
    final defaultTextStyle = TextStyle(
      color: fg,
      fontSize: 14.w,
      fontWeight: FontWeight.w800,
    );
    //  Merge with widget text style if provided
    final effectiveTextStyle = widget.textStyle != null
        ? defaultTextStyle.merge(widget.textStyle)
        : defaultTextStyle;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.loading)
          Padding(
            padding: EdgeInsets.only(
              right: widget.child is SizedBox ? 0 : widget.gap.w,
            ),
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (widget.leading != null) ...[
          widget.leading!,
          SizedBox(width: widget.gap.w),
        ],
        DefaultTextStyle.merge(
          style: effectiveTextStyle,
          child: widget.child,
        ),
        if (widget.trailing != null) ...[
          SizedBox(width: widget.gap.w),
          widget.trailing!,
        ],
      ],
    );

    final buttonCore = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: widget.padding,
      width: widget.width?.w,
      height: widget.height.w,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.radius.w),
        border: Border.all(color: border, width: 1.w),
        boxShadow: shadow,
      ),
      child: IconTheme(
        data: IconThemeData(color: fg, size: 20),
        child: content,
      ),
    );

    return AnimatedScale(
      scale: targetScale,
      duration:  Duration(milliseconds: _isPressed ? 80 : 220),
      curve: _isPressed ? Curves.easeOutCubic : Curves.elasticOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius.w),
          onTap: () async{
            await Future.delayed(const Duration(milliseconds: 50));
            if (!effectiveDisabled) {
              widget.onPressed?.call();
            }
          },
          onHighlightChanged: ((v){
            Future.delayed(const Duration(milliseconds: 40),(){
              setState(() {
                _isPressed = v;
              });
            });
          }),
          child: buttonCore,
        ),
      ),
    );
  }
}

/// Button visual style
/// Used for custom button variant
/// bg: background color
/// fg: foreground color (text and icon)
/// border: border color
/// shadow: box shadow
/// Example:
/// ```dart
/// ButtonVisual(
///  bg: Colors.blue,
///  fg: Colors.white,
///  border: Colors.blueAccent,
///  shadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
///  );
/// ```
/// Used in Button widget
class ButtonVisual {
  final Color bg;
  final Color fg;
  final Color border;
  final List<BoxShadow> shadow;

  ButtonVisual({
    required this.bg,
    required this.fg,
    required this.border,
    required this.shadow,
  });
}
