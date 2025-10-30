import 'package:flutter/material.dart';
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
    final double top = isFullScreen ? ViewUtils.statusBarHeight : 8.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        config.headerBuilder != null ?
        SizedBox(
          height: config.headerHeight,
          child: config.headerBuilder!.call(
                  ([result]) => onClose()
          ),
        ) :
        _SheetHeader(
          onClose: onClose,
          showClose: config.showCloseButton,
          paddingTop: top,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  final bool showClose;
  final double paddingTop;

  const _SheetHeader({
    required this.onClose,
    required this.showClose,
    this.paddingTop = 8,
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
            Container(
              width: 40.w,
              height: 5.w,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3.w)
              ),
            ),
            if(showClose)
             Positioned(
               right: 10.w,
               child: InkResponse(
                 onTap: onClose,
                 child: Container(
                   width: 32,
                   height: 32,
                   decoration: BoxDecoration(
                       color: Colors.black26,
                       shape: BoxShape.circle
                   ),
                   alignment: Alignment.center,
                   child: const Icon(Icons.close, size: 18, color: Colors.white),
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }
}