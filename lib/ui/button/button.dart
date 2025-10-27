import 'package:flutter/material.dart';
import 'package:flutter_app/ui/button/button_size.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/button/button_visual.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'button_theme.dart';

/// Button - A customizable button widget with various styles and states
/// Parameters:
/// - onPressed: VoidCallback? - Callback when the button is pressed
/// - child: Widget - The content of the button
/// - variant: ButtonVariant - The visual variant of the button
/// - disabled: bool - Whether the button is disabled
/// - loading: bool - Whether to show a loading indicator
/// - noPressAnimation: bool - Disable press animation if true
/// - height: double? - Custom height of the button
/// - width: double? - Custom width of the button
/// - backgroundColor: Color? - Custom background color
/// - foregroundColor: Color? - Custom foreground color
/// - borderColor: Color? - Custom border color
/// - boxShadow: List<'BoxShadow'>? - Custom box shadow
/// - paddingX: double? - Custom horizontal padding
/// - paddingY: double? - Custom vertical padding
/// - radius: double? - Custom border radius
/// - gap: double? - Gap between leading/trailing widgets and text
/// - leading: Widget? - Widget to display before the text
/// - trailing: Widget? - Widget to display after the text
/// - customButtonStyle: ButtonVisual? - Custom button visual style
/// - textStyle: TextStyle? - Custom text style
/// - size: String - Size of the button ('small', 'medium', 'large')
/// Usage:
/// ```dart
/// Button(
///  onPressed: () { /* Handle press */ },
///  child: Text('Click Me'),
///  variant: ButtonVariant.primary,
///  loading: true,
///  )
///  ```
///
class Button extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final ButtonVariant variant;
  final bool disabled;
  final bool loading;
  final bool noPressAnimation;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double? paddingX;
  final double? paddingY;

  final double? radius;
  final double? gap;
  final Widget? leading;
  final Widget? trailing;
  final ButtonVisual? customButtonStyle;
  final TextStyle? textStyle;
  final String size;

  const Button({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.loading = false,
    this.noPressAnimation = false,
    this.height,
    this.width,
    this.paddingX,
    this.paddingY,
    this.radius,
    this.gap,
    this.leading,
    this.trailing,
    this.customButtonStyle,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.boxShadow,
    this.borderColor,
    this.size = 'small',
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _isPressed = false;


  @override
  Widget build(BuildContext context) {
    final sizeValue = resolveButtonSize(widget.size);


    final H = widget.height ?? sizeValue.height.w;
    final W = widget.width?.w;
    final R = widget.radius ?? sizeValue.radius.w;
    final pX = widget.paddingX ?? sizeValue.padding.horizontal.w;
    final pY = widget.paddingY ?? sizeValue.padding.vertical.w;
    final G = widget.gap ?? 8.w;

    final theme = ButtonThemeResolver.resolve(context, widget.variant, widget.customButtonStyle);
    final effectiveDisabled =
        widget.disabled || widget.loading || widget.onPressed == null;

    final targetScale = widget.noPressAnimation
        ? 1.0
        : (_isPressed ? 0.92 : 1.0);

    final bg = effectiveDisabled ? (widget.backgroundColor?.withValues(alpha: 0.8) ?? theme.bg.withValues(alpha: 0.8)) : (widget.backgroundColor??theme.bg);
    final fg = widget.foregroundColor??theme.fg;
    final border = widget.borderColor??theme.border;
    final shadow = effectiveDisabled ? const <BoxShadow>[] : widget.boxShadow??theme.shadow;

    // Default text style
    final defaultTextStyle = TextStyle(
      color: fg,
      fontSize: sizeValue.fontSize.w,
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
              right: widget.child is SizedBox ? 0 : G,
            ),
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (widget.leading != null) ...[
          widget.leading!,
          SizedBox(width: G),
        ],
        if(widget.child is Widget)
        DefaultTextStyle.merge(
          style: effectiveTextStyle,
          child: widget.child!,
        ),
        if (widget.trailing != null) ...[
          if(widget.child is Widget)
            SizedBox(width: G),
          widget.trailing!,
        ],
      ],
    );

    final buttonCore = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: pX, vertical: pY),
      width: W,
      height: H,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(R),
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
          borderRadius: BorderRadius.circular(R),
          onTap: () async{
            await Future.delayed(const Duration(milliseconds: 50));
            if (!effectiveDisabled) {
              widget.onPressed?.call();
            }
          },
          onTapDown: (_){
            Future.delayed(const Duration(milliseconds: 40),(){
              setState(() {
                _isPressed = true;
              });
            });
          },
          onTapCancel: (){
            Future.delayed(const Duration(milliseconds: 40),(){
              setState(() {
                _isPressed = false;
              });
            });
          },
          onTapUp: (_){
            Future.delayed(const Duration(milliseconds: 40),(){
              setState(() {
                _isPressed = false;
              });
            });
          },
          child: buttonCore,
        ),
      ),
    );
  }
}

