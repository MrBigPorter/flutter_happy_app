import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:js_interop'; // Required for WASM byte and callback conversions
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Optimization: Replaced universal_html with package:web for WASM compatibility
import 'package:web/web.dart' as web;

class ImageCompressionService {
  /// Compresses images for network upload.
  /// Skips processing if the file is already under 500 KB.
  static Future<XFile> compressForUpload(XFile file) async {
    try {
      final int size = await file.length();
      if (size < 500 * 1024) return file;

      if (kIsWeb) {
        return await _compressWebCanvas(file, quality: 0.8, maxWidth: 1920);
      } else {
        return await _compressMobile(file, 1920, 80);
      }
    } catch (e) {
      return file;
    }
  }

  /// Generates a tiny thumbnail for local DB placeholders.
  static Future<Uint8List> getTinyThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        final XFile tinyFile = await _compressWebCanvas(file, quality: 0.5, maxWidth: 200);
        return await tinyFile.readAsBytes();
      } else {
        final XFile tinyFile = await _compressMobile(file, 200, 50);
        return await tinyFile.readAsBytes();
      }
    } catch (e) {
      return Uint8List(0);
    }
  }

  /// Extracts a video frame on Web using the browser's Canvas API.
  /// Fully WASM compatible using package:web.
  static Future<Uint8List?> captureWebVideoFrame(String blobUrl) async {
    if (!kIsWeb) return null;
    final completer = Completer<Uint8List?>();

    try {
      final video = web.HTMLVideoElement()
        ..src = blobUrl
        ..crossOrigin = 'anonymous'
        ..muted = true;

      video.onLoadedData.listen((_) {
        final int vW = video.videoWidth;
        final int vH = video.videoHeight;

        final canvas = web.HTMLCanvasElement()
          ..width = vW ~/ 2
          ..height = vH ~/ 2;

        final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;

        // Draw the video frame onto the canvas
        context.drawImage(video, 0, 0, canvas.width, canvas.height);

        // Convert canvas to Blob asynchronously
        // toJS is required for passing Dart callbacks to JS in WASM
        canvas.toBlob((web.Blob? blob) {
          if (blob == null) {
            completer.complete(null);
            return;
          }

          final reader = web.FileReader();
          reader.readAsArrayBuffer(blob);

          reader.onLoadEnd.listen((_) {
            // Safely cast JSAny to JSArrayBuffer, then convert to Dart Uint8List
            final result = reader.result as JSArrayBuffer?;
            completer.complete(result?.toDart.asUint8List());
          });
        }.toJS, 'image/jpeg', 0.7.toJS);
      });

      video.onError.listen((_) => completer.complete(null));
      video.load();
    } catch (e) {
      completer.complete(null);
    }

    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  /// Private: Compresses images on Web using Canvas to preserve performance.
  static Future<XFile> _compressWebCanvas(XFile file, {double quality = 0.8, int maxWidth = 1920}) async {
    final Completer<XFile> completer = Completer();
    try {
      final bytes = await file.readAsBytes();

      // package:web requires wrapping the byte array into a JS array
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final img = web.HTMLImageElement()..src = url;

      await img.onLoad.first;

      int w = img.naturalWidth;
      int h = img.naturalHeight;

      if (w == 0 || h == 0) {
        web.URL.revokeObjectURL(url);
        return file;
      }

      // Aspect Ratio Preservation
      if (w > maxWidth || h > maxWidth) {
        final double ratio = w > h ? (maxWidth / w) : (maxWidth / h);
        w = (w * ratio).round();
        h = (h * ratio).round();
      }

      final canvas = web.HTMLCanvasElement()
        ..width = w
        ..height = h;

      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      context.imageSmoothingEnabled = true;
      context.imageSmoothingQuality = 'high';
      context.drawImage(img, 0, 0, w, h);

      // Async Blob conversion for WASM compatibility
      canvas.toBlob((web.Blob? outBlob) {
        web.URL.revokeObjectURL(url);

        if (outBlob != null) {
          final newUrl = web.URL.createObjectURL(outBlob);
          completer.complete(XFile(
              newUrl,
              name: file.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg'),
              mimeType: 'image/jpeg'
          ));
        } else {
          completer.complete(file);
        }
      }.toJS, 'image/jpeg', quality.toJS);
    } catch (e) {
      completer.complete(file);
    }
    return completer.future;
  }

  /// Private: Compresses images on Mobile using native libraries.
  static Future<XFile> _compressMobile(XFile file, int minWidth, int quality) async {
    final String filePath = file.path;
    final String outPath = "${filePath.split('.').first}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        minWidth: minWidth,
        minHeight: minWidth,
        quality: quality,
        format: CompressFormat.jpeg
    );
    return result ?? file;
  }
}