import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

class WebVideoThumbnailService {
  /// Extracts a JPEG thumbnail from video bytes specifically for Web environments.
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
      final blob = html.Blob([videoBytes]);
      blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final video = html.VideoElement()
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

      // Architectural Fix: Cast to dynamic to bypass iOS compilation checks.
      // This circumvents missing properties in universal_html mock classes.
      final int vW = (video as dynamic).videoWidth;
      final int vH = (video as dynamic).videoHeight;

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

      final canvas = html.CanvasElement(width: targetW, height: targetH);
      canvas.context2D.drawImageScaled(video, 0, 0, targetW, targetH);

      final outBlob = await canvas.toBlob('image/jpeg', quality);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(outBlob);
      reader.onLoadEnd.listen((_) {
        completer.complete(reader.result as Uint8List?);
      });

    } catch (e) {
      debugPrint("[WebVideoThumbnailService] Extraction failed: $e");
      completer.complete(null);
    } finally {
      // Resource Management: Revoke Blob URL to prevent memory leaks.
      if (blobUrl != null) {
        html.Url.revokeObjectUrl(blobUrl);
      }
    }

    return completer.future;
  }
}