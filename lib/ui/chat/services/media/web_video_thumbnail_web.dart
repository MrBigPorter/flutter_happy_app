import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebVideoThumbnailService {
  static Future<Uint8List?> extractJpegThumb(Uint8List videoBytes, {double atSeconds = 0.1, int maxWidth = 320, double quality = 0.85}) async {
    final completer = Completer<Uint8List?>();
    String? blobUrl;
    try {
      final blob = web.Blob([videoBytes.toJS].toJS);
      blobUrl = web.URL.createObjectURL(blob);
      final video = web.HTMLVideoElement()
        ..src = blobUrl ..crossOrigin = 'anonymous' ..muted = true ..preload = 'metadata';
      video.currentTime = atSeconds;
      await video.onLoadedData.first;
      if (video.currentTime != atSeconds) await video.onSeeked.first;

      final int vW = video.videoWidth;
      final int vH = video.videoHeight;
      if (vW == 0 || vH == 0) throw Exception("Video dimensions zero");

      int targetW = vW, targetH = vH;
      if (targetW > maxWidth) {
        final double ratio = maxWidth / targetW;
        targetW = maxWidth;
        targetH = (vH * ratio).round();
      }

      final canvas = web.HTMLCanvasElement()..width = targetW..height = targetH;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      context.drawImage(video, 0, 0, targetW, targetH);

      canvas.toBlob((web.Blob? outBlob) {
        if (outBlob == null) { completer.complete(null); return; }
        final reader = web.FileReader();
        reader.readAsArrayBuffer(outBlob);
        reader.onLoadEnd.listen((_) {
          final result = reader.result as JSArrayBuffer?;
          completer.complete(result?.toDart.asUint8List());
        });
      }.toJS, 'image/jpeg', quality.toJS);
    } catch (e) {
      completer.complete(null);
    } finally {
      completer.future.whenComplete(() { if (blobUrl != null) web.URL.revokeObjectURL(blobUrl); });
    }
    return completer.future;
  }
}