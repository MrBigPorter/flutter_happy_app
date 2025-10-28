import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'sheet_props.dart';

class SheetSurface extends StatelessWidget {
  final ModalSheetConfig config;
  final VoidCallback onClose;
  final Widget child;

  const SheetSurface({
    super.key,
    required this.config,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    Widget closeBtn() => IconButton(onPressed: onClose, icon: Icon(Icons.close, size: 24.w));

    Widget? positionedClose;
    if (config.showCloseButton) {
      switch (config.closeAlignment) {
        case CloseButtonAlignment.topRight:
          positionedClose = Positioned(top: 8, right: 8, child: closeBtn());
          break;
        case CloseButtonAlignment.topCenter:
          positionedClose = Positioned(top: 8, left: 0, right: 0, child: Center(child: closeBtn()));
          break;
        case CloseButtonAlignment.topLeft:
          positionedClose = Positioned(top: 8, left: 8, child: closeBtn());
          break;
      }
    }

    return Padding(
      // 只在内部追加底部安全区，视觉保持贴底（外层不再叠加 SafeArea）
      padding: config.contentPadding.add(EdgeInsets.only(bottom: mq.padding.bottom)),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: config.showCloseButton ? 10.w : 0),
            child: child,
          ),
          if (positionedClose != null) positionedClose,
        ],
      ),
    );

  }
}