import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebLivenessIframe extends StatefulWidget {
  final String sessionId;

  const WebLivenessIframe({super.key, required this.sessionId});

  @override
  State<WebLivenessIframe> createState() => _WebLivenessIframeState();
}

class _WebLivenessIframeState extends State<WebLivenessIframe> {
  late final String _viewType;
  html.MessageEvent? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // name iframe view type with sessionId to ensure uniqueness, preventing conflicts if multiple instances exist
    _viewType = 'liveness-iframe-${widget.sessionId}';

    // 1. register the iframe view factory, creating an iframe that points to the React app with sessionId as a query parameter
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'https://live.joyminis.com/?sessionId=${widget.sessionId}'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('allow', 'camera *; microphone *; fullscreen');
      return iframe;
    });

    // 2. listen for messages from the React app, expecting a specific data structure indicating liveness check results
    html.window.onMessage.listen((html.MessageEvent event) {
     // For security, you might want to check event.origin here to ensure messages are from a trusted source
      if (event.data is Map) {
        final data = event.data as Map;
        if (data['type'] == 'LIVENESS_RESULT') {
          final bool isSuccess = data['success'] == true;

          if (isSuccess) {
            debugPrint("web liveness check passed! Session ID: ${widget.sessionId}");
          } else {
            debugPrint(" web liveness check fail ：${data['error']}");
          }

          if (mounted) {
            Navigator.of(context).pop(isSuccess);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. render the iframe using HtmlElementView, which will display the React app's UI for liveness detection
    return HtmlElementView(viewType: _viewType);
  }
}