import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

Future<XFile> compressWebCanvasImpl(XFile file, {double quality = 0.8, int maxWidth = 1920}) async {
  final Completer<XFile> completer = Completer();
  try {
    final bytes = await file.readAsBytes();
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final img = web.HTMLImageElement()..src = url;
    await img.onLoad.first;

    int w = img.naturalWidth, h = img.naturalHeight;
    if (w == 0 || h == 0) { web.URL.revokeObjectURL(url); return file; }

    if (w > maxWidth || h > maxWidth) {
      final double ratio = w > h ? (maxWidth / w) : (maxWidth / h);
      w = (w * ratio).round(); h = (h * ratio).round();
    }

    final canvas = web.HTMLCanvasElement()..width = w..height = h;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    context.imageSmoothingEnabled = true; context.imageSmoothingQuality = 'high';
    context.drawImage(img, 0, 0, w, h);

    canvas.toBlob((web.Blob? outBlob) {
      web.URL.revokeObjectURL(url);
      if (outBlob != null) {
        final newUrl = web.URL.createObjectURL(outBlob);
        completer.complete(XFile(newUrl, name: file.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg'), mimeType: 'image/jpeg'));
      } else {
        completer.complete(file);
      }
    }.toJS, 'image/jpeg', quality.toJS);
  } catch (e) { completer.complete(file); }
  return completer.future;
}

Future<Uint8List?> captureWebVideoFrameImpl(String blobUrl) async {
  final completer = Completer<Uint8List?>();
  try {
    final video = web.HTMLVideoElement()..src = blobUrl..crossOrigin = 'anonymous'..muted = true;
    video.onLoadedData.listen((_) {
      final int vW = video.videoWidth, vH = video.videoHeight;
      final canvas = web.HTMLCanvasElement()..width = vW ~/ 2..height = vH ~/ 2;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      context.drawImage(video, 0, 0, canvas.width, canvas.height);

      canvas.toBlob((web.Blob? blob) {
        if (blob == null) { completer.complete(null); return; }
        final reader = web.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((_) {
          final result = reader.result as JSArrayBuffer?;
          completer.complete(result?.toDart.asUint8List());
        });
      }.toJS, 'image/jpeg', 0.7.toJS);
    });
    video.onError.listen((_) => completer.complete(null));
    video.load();
  } catch (e) { completer.complete(null); }
  return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
}