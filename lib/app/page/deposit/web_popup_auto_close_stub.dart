import 'package:flutter/material.dart';
import 'deposit_result_page.dart';

/// A widget that handles the payment success redirect in a popup window.
///
/// Stub version (non-web platforms). Always renders [DepositResultPage]
/// since popup auto-close is only needed on web.
class WebPopupAutoClose extends StatelessWidget {
  final String orderNo;
  const WebPopupAutoClose({super.key, required this.orderNo});

  @override
  Widget build(BuildContext context) {
    return DepositResultPage(orderNo: orderNo);
  }
}
