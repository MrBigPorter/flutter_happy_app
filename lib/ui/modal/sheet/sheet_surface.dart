import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'modal_sheet_config.dart';

/// Widget that renders the surface of a modal sheet
/// This includes the sheet header and content
class SheetSurface<T> extends StatelessWidget {
  /// Configuration object for the modal sheet
  final ModalSheetConfig config;

  /// Callback function to close the sheet
  final VoidCallback onClose;

  /// Child widget to display in the sheet body
  final Widget child;

  /// Whether the sheet takes up full screen height
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
    // 1. 如果是全屏模式，顶部留出刘海高度；否则留一点间距
    final double top = isFullScreen ? ViewUtils.statusBarHeight : 8.h;

    return Padding(
      // 2. 这里的 Padding 只管水平，垂直的交给 Column 内部或 Child，避免计算打架
      padding:EdgeInsets.symmetric(horizontal: 16.w,),
      child: Column(
        // 核心 A：使用 min，表示“我们尽量紧凑，别瞎占空”
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
              showClose: config.showCloseButton,
              paddingTop: top,
              showThumb: config.showThumb ?? false,
            ),
          ],
          // 核心 B：关键中的关键！
          // 使用 Flexible + fit: loose
          // 翻译：“儿子（child），你多大都行，但要是太大了，你就得在剩下的空间里呆着，别把屋顶顶破了。”
          Flexible(
            fit: FlexFit.loose,
            child: child,
          ),
          // 底部可以加个安全距离，防止贴底
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

  const _SheetHeader({
    required this.onClose,
    required this.showClose,
    this.paddingTop = 8,
    this.showThumb = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: SizedBox(
        width: double.infinity,
        height: 32.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showThumb)
            Container(
              width: 40.w,
              height: 5.w,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3.w),
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
      child:  InkResponse(
        onTap: onClose,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child:  Icon(Icons.close, size: 22, color: context.fgPrimary900),
        ),
      ),
    );
  }
}
