import 'package:flutter/material.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'sheet_props.dart';

class SheetSurface extends StatelessWidget {
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


    final double top = isFullScreen ? ViewUtils.statusBarHeight : 8.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        config.customHeader ??
        _SheetHeader(
          onClose: onClose,
          showClose: config.showCloseButton,
          paddingTop: top,
        ),
        if(config.headerActions != null)
          SizedBox(
            height: config.headerHeight ?? 40.w,
            child: config.headerActions,
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