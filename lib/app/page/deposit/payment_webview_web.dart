import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'deposit_result_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;
  const PaymentWebViewPage({super.key, required this.url, required this.orderNo});
  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewWebState();
}

class _PaymentWebViewWebState extends State<PaymentWebViewPage> {
  web.Window? _popupWindow;
  Timer? _checkTimer;
  StreamSubscription<web.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // Auto-open popup on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPopup();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _openPopup() {
    _popupWindow = web.window.open(widget.url, '_blank');
    _startWebCheck();
  }

  void _startWebCheck() {
    _checkTimer?.cancel();
    _messageSubscription?.cancel();

    // Listen for structured postMessage from payment-redirect.html
    _messageSubscription = web.window.onMessage.listen((web.MessageEvent event) {
      final data = event.data?.dartify();
      if (data is Map && data['type'] == 'payment_redirect') {
        _handlePaymentComplete();
      }
    });

    // Poll: when popup is manually closed, go to result page
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_popupWindow != null && _popupWindow!.closed) {
        timer.cancel();
        _goToResult();
      }
    });
  }

  void _handlePaymentComplete() {
    _messageSubscription?.cancel();
    _checkTimer?.cancel();
    _popupWindow?.close();
    _goToResult();
  }

  void _goToResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DepositResultPage(orderNo: widget.orderNo)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completing Payment")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(), const SizedBox(height: 24),
            const Text("Waiting for payment to complete...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Payment window opened in a new tab", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openPopup,
              label: const Text("Re-open Payment Window"),
            ),
            TextButton(onPressed: _goToResult, child: const Text("I have paid, check status now")),
          ],
        ),
      ),
    );
  }
}