import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'deposit_result_page.dart';

/// A widget that handles the payment success redirect in a popup window.
///
/// When the Flutter app boots in a popup (detected via `window.opener != null`),
/// this widget sends a [postMessage] to the main window with the payment result,
/// then auto-closes the popup after a short delay.
///
/// When NOT in a popup (e.g. direct navigation), it renders [DepositResultPage]
/// normally so the route works the same as before.
class WebPopupAutoClose extends StatelessWidget {
  final String orderNo;
  const WebPopupAutoClose({super.key, required this.orderNo});

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, this route is never hit (mobile uses inline WebView),
    // but we keep it as a safe fallback.
    if (!kIsWeb) {
      return DepositResultPage(orderNo: orderNo);
    }

    // Check if running in a popup window
    final opener = web.window.opener;
    if (opener != null) {
      return _PopupAutoCloseBody(orderNo: orderNo);
    }

    // Not in a popup — render the normal result page.
    return DepositResultPage(orderNo: orderNo);
  }
}

class _PopupAutoCloseBody extends StatefulWidget {
  final String orderNo;
  const _PopupAutoCloseBody({required this.orderNo});

  @override
  State<_PopupAutoCloseBody> createState() => _PopupAutoCloseBodyState();
}

class _PopupAutoCloseBodyState extends State<_PopupAutoCloseBody> {
  @override
  void initState() {
    super.initState();
    _handlePopupClose();
  }

  void _handlePopupClose() {
    // Send postMessage to the opener (main app window)
    try {
      final opener = web.window.opener;
      if (opener != null) {
        // Build JS object message using dart:js_interop_unsafe
        final message = JSObject();
        message['type'] = 'payment_redirect'.toJS;
        message['orderNo'] = widget.orderNo.toJS;
        message['status'] = 'success'.toJS;

        // Dynamic dispatch: opener.postMessage(message, '*')
        // opener is JSAny? but in JS it's the Window object with postMessage.
        (opener as dynamic).postMessage(message, '*');
      }
    } catch (e) {
      debugPrint('[WebPopupAutoClose] postMessage error: $e');
    }

    // Auto-close the popup after 1.5 seconds to ensure the message is received
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        web.window.close();
      } catch (e) {
        debugPrint('[WebPopupAutoClose] close error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Closing this window...',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
