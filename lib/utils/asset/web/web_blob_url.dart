import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Web 专用：把 Uint8List bytes 变成 blob: URL
class WebBlobUrl {
  WebBlobUrl._();

  static String fromBytes(Uint8List bytes, {String mime = 'application/octet-stream'}) {
    if (!kIsWeb) {
      throw UnsupportedError('WebBlobUrl is only available on Web.');
    }
    final blob = html.Blob([bytes], mime);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  static void revoke(String? url) {
    if (!kIsWeb) return;
    if (url == null || url.isEmpty) return;
    try {
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }
}