import 'dart:typed_data';
import 'dart:js_interop'; // Required for WASM array conversions
import 'package:flutter/foundation.dart';

// Optimization: Replaced universal_html with package:web for WASM compatibility
import 'package:web/web.dart' as web;

/// Web Specific: Converts Uint8List bytes into a browser-native blob: URL
class WebBlobUrl {
  WebBlobUrl._();

  /// Creates an Object URL from a byte array.
  /// Fully WASM compatible using package:web and JSInterop.
  static String fromBytes(Uint8List bytes, {String mime = 'application/octet-stream'}) {
    if (!kIsWeb) {
      throw UnsupportedError('WebBlobUrl is only available on Web platforms.');
    }

    // WASM Memory Boundary Fix:
    // 1. bytes.toJS converts the Dart Uint8List to a JS Uint8Array
    // 2. [ ... ].toJS wraps that JS array into a JS Array expected by the Blob constructor
    // 3. BlobPropertyBag is strictly required in modern web APIs to pass the MIME type
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mime),
    );

    return web.URL.createObjectURL(blob);
  }

  /// Revokes an existing Object URL to free up browser memory.
  static void revoke(String? url) {
    if (!kIsWeb) return;
    if (url == null || url.isEmpty) return;

    try {
      web.URL.revokeObjectURL(url);
    } catch (_) {
      // Silently catch exceptions if the URL was already revoked or invalid
    }
  }
}