import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'sheet_props.dart';
import 'sheet_surface.dart';

class BottomSheetContainer<T> extends StatelessWidget {
  final Animation<double> anim;
  final AnimationController controller;
  final bool clickBgToClose;
  final ModalSheetConfig config;
  final void Function([T?]) onClose;
  final Widget Function(BuildContext) childBuilder;

  const BottomSheetContainer({
    super.key,
    required this.anim,
    required this.controller,
    required this.clickBgToClose,
    required this.config,
    required this.onClose,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final vw = media.size.width;
    final vh = media.size.height;

    final maxSheetWidth = config.maxWidth == double.infinity
        ? vw
        : vw.clamp(0, config.maxWidth).toDouble();
    final maxH = vh * config.maxHeightFactor;

    final barrierColor =
        config.theme.barrierColor ??
        Theme.of(context).colorScheme.scrim.withValues(alpha: 0.45);

    final surfaceColor =
        config.theme.surfaceColor ?? Theme.of(context).colorScheme.surface;

    // 遮罩
    final backdrop = AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value.clamp(0.01, 1.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: clickBgToClose ? () => onClose() : null,
          child: Container(color: barrierColor),
        ),
      ),
    );

    // 面板
    final panel = Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxSheetWidth,
          maxHeight: maxH,
          minHeight: config.minHeight,
        ).tighten(width: config.minWidth),
        child: Padding(
          // 横向不留白：满宽；底部不额外加 padding（内部已加安全区）
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
            child: Material(
              color: surfaceColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(config.borderRadius.w),
              ),
              elevation: 16,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(config.borderRadius),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: GestureDetector(
                    onVerticalDragUpdate: config.enableDragToClose
                        ? (d) {
                            if (d.delta.dy > config.dragToCloseThreshold) {
                              onClose();
                            }
                          }
                        : null,
                    child: SheetSurface(
                      config: config,
                      onClose: onClose,
                      child: childBuilder(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(children: [backdrop, panel]);
  }
}
