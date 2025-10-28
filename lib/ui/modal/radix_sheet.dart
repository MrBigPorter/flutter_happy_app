import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/modal_service.dart';

class RadixSheet {
  static Future<T?> show<T>({
    required Widget Function(
      BuildContext context,
      void Function([T? res]) close,
    )
    builder,
    bool clickBgToClose = true,
    bool showClose = true,
  }) {
    return ModalService.instance.showSheet<T>(
      builder: builder,
      clickBgToClose: clickBgToClose,
      showClose: showClose,
    );
  }
}
