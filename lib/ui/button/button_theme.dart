import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button_visual.dart';
import 'package:flutter_app/ui/button/variant.dart';



class ButtonThemeResolver {
  static ButtonVisual resolve(
    BuildContext ctx,
    ButtonVariant v, [
    ButtonVisual? custom,
  ]) {
    switch (v) {
      case ButtonVariant.primary:
        return ButtonVisual(
          bg: ctx.buttonPrimaryBg,
          fg: ctx.textWhite,
          border: Colors.transparent,
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
          shadow: [],
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
      case ButtonVariant.outline:
        return ButtonVisual(
          bg: ctx.buttonSecondaryBg,
          fg: ctx.buttonSecondaryFg,
          border: ctx.borderSecondary,
          shadow: [
            BoxShadow(
              color: ctx.bgDisabled,
              offset: Offset(0, 2),
              blurRadius: 6,
            )
          ],
        );
      case ButtonVariant.ghost:
        return ButtonVisual(
          bg: Colors.transparent,
          fg: ctx.textBrandPrimary900,
          border: Colors.transparent,
          shadow: [],
        );
      case ButtonVariant.text:
        return ButtonVisual(
          bg: Colors.transparent,
          fg: ctx.textPrimary900,
          border: Colors.transparent,
          shadow: [],
        );
      case ButtonVariant.custom:
        return custom ??
            ButtonVisual(
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
    }
  }
}
