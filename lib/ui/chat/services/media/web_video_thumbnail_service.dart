import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop'; // Required for WASM JSAny/JSArrayBuffer conversions
import 'package:flutter/foundation.dart';

// Optimization: Replaced universal_html with package:web for WASM compatibility
import 'package:web/web.dart' as web;

class WebVideoThumbnailService {
  /// Extracts a JPEG thumbnail from video bytes specifically for Web environments.
  /// Fully WASM compatible using package:web.
  /// [atSeconds]: The timestamp from which to capture the frame.
  /// [maxWidth]: The target width for the resulting thumbnail.
  static Future<Uint8List?> extractJpegThumb(
      Uint8List videoBytes, {
        double atSeconds = 0.1,
        int maxWidth = 320,
        double quality = 0.85,
      }) async {
    // 1. Environmental Isolation: Immediately return null on non-web platforms
    // to prevent runtime exceptions.
    if (!kIsWeb) return null;

    final completer = Completer<Uint8List?>();
    String? blobUrl;

    try {
      // Wrap Uint8List into a JS Array for strict WASM memory boundaries
      final blob = web.Blob([videoBytes.toJS].toJS);
      blobUrl = web.URL.createObjectURL(blob);

      final video = web.HTMLVideoElement()
        ..src = blobUrl
        ..crossOrigin = 'anonymous'
        ..muted = true
        ..preload = 'metadata'; // Load metadata only to resolve dimensions

      // Set currentTime to avoid capturing a black frame at 0.0s.
      video.currentTime = atSeconds;

      await video.onLoadedData.first;

      // Ensure the seek operation is complete before drawing to canvas.
      if (video.currentTime != atSeconds) {
        await video.onSeeked.first;
      }

      // Architectural Clean-up: package:web handles cross-platform types natively,
      // so the old (video as dynamic) cast hack for iOS is completely removed.
      final int vW = video.videoWidth;
      final int vH = video.videoHeight;

      if (vW == 0 || vH == 0) {
        throw Exception("Video dimensions resolved as zero");
      }

      // Calculate proportional scaling based on maxWidth.
      int targetW = vW;
      int targetH = vH;
      if (targetW > maxWidth) {
        final double ratio = maxWidth / targetW;
        targetW = maxWidth;
        targetH = (vH * ratio).round();
      }

      final canvas = web.HTMLCanvasElement()
        ..width = targetW
        ..height = targetH;

      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;

      // Draw the extracted frame onto the canvas
      context.drawImage(video, 0, 0, targetW, targetH);

      // Async Blob conversion for WASM
      // .toJS proxy wraps the Dart callback into a JS function
      canvas.toBlob((web.Blob? outBlob) {
        if (outBlob == null) {
          completer.complete(null);
          return;
        }

        final reader = web.FileReader();
        reader.readAsArrayBuffer(outBlob);

        reader.onLoadEnd.listen((_) {
          // Safely cast JSAny to JSArrayBuffer, then convert to Dart Uint8List
          final result = reader.result as JSArrayBuffer?;
          completer.complete(result?.toDart.asUint8List());
        });
      }.toJS, 'image/jpeg', quality.toJS);

    } catch (e) {
      debugPrint("[WebVideoThumbnailService] Extraction failed: $e");
      completer.complete(null);
    } finally {
      // Resource Management: Revoke Blob URL to prevent memory leaks.
      // We wait for the future to complete since canvas.toBlob is callback-based.
      completer.future.whenComplete(() {
        if (blobUrl != null) {
          web.URL.revokeObjectURL(blobUrl);
        }
      });
    }

    return completer.future;
  }
}