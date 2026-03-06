import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebBlobUrl {
  WebBlobUrl._();
  static String fromBytes(Uint8List bytes, {String mime = 'application/octet-stream'}) {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
    return web.URL.createObjectURL(blob);
  }
  static void revoke(String? url) {
    if (url == null || url.isEmpty) return;
    try { web.URL.revokeObjectURL(url); } catch (_) {}
  }
}