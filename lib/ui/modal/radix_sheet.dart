import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/modal_service.dart';
import 'package:flutter_app/ui/modal/sheet_props.dart';

class RadixSheet {
  static Future<T?> show<T>({
    required Widget Function(
      BuildContext context,
      void Function([T? res]) close,
    )
    builder,
    bool clickBgToClose = true,
    bool showClose = true,
    ModalSheetConfig? config,
  }) {
    return ModalService.instance.showSheet<T>(
      builder: builder,
      clickBgToClose: clickBgToClose,
      showClose: showClose,
      config: config?? const ModalSheetConfig(),
    );
  }
}
