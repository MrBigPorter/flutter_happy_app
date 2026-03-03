import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'modal_sheet_config.dart';

class SheetSurface<T> extends StatelessWidget {
  final ModalSheetConfig config;
  final VoidCallback onClose;
  final Widget child;
  final bool isFullScreen;

  const SheetSurface({
    super.key,
    required this.config,
    required this.onClose,
    required this.child,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final double top = isFullScreen ? ViewUtils.statusBarHeight : 8.h;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(config.enableHeader ?? true) ...[
            config.headerBuilder != null
                ? SizedBox(
              width: double.infinity,
              height: config.headerHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  config.headerBuilder!.call(context,([result]) => onClose()),
                  CloseIcon(onClose: onClose)
                ],
              ),
            )
                : _SheetHeader(
              onClose: onClose,
              showClose: config.showCloseButton ?? true,
              paddingTop: top,
              showThumb: config.showThumb ?? false,
              title: config.title, 
            ),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: child,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  final bool showClose;
  final double paddingTop;
  final bool showThumb;
  final String? title; // 接收 title

  const _SheetHeader({
    required this.onClose,
    required this.showClose,
    this.paddingTop = 8,
    this.showThumb = false,
    this.title, // 构造参数
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 底部加一点间距，让标题和内容呼吸感更好
      padding: EdgeInsets.only(top: paddingTop, bottom: 8.w),
      child: SizedBox(
        width: double.infinity,
        height: 32.w, // 保持高度，内部绝对居中
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showThumb)
              Positioned(
                top: 0,
                child: Container(
                  width: 40.w,
                  height: 5.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
              ),

            // ADDED: 居中渲染 Title
            if (title != null && title!.isNotEmpty)
              Text(
                title!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900
                ),
              ),

            if (showClose)
              CloseIcon(onClose: onClose),
          ],
        ),
      ),
    );
  }
}

class CloseIcon extends StatelessWidget {
  final VoidCallback onClose;

  const CloseIcon({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      child: InkResponse(
        onTap: onClose,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          // 用 context.fgPrimary900 保持颜色统一
          child: Icon(Icons.close, size: 22, color: context.fgPrimary900),
        ),
      ),
    );
  }
}