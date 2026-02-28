import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:blurhash/blurhash.dart' as bh;

/// Encapsulated processing result: [thumbBytes] will be persisted in the Sembast DB as [previewBytes].
class ThumbBlurResult {
  final Uint8List thumbBytes;
  final int thumbW;
  final int thumbH;
  final String thumbMime;
  final String blurHash;

  const ThumbBlurResult({
    required this.thumbBytes,
    required this.thumbW,
    required this.thumbH,
    required this.thumbMime,
    required this.blurHash,
  });
}

class ThumbBlurHashService {
  /// Core Entry Point: Decodes in background (Isolate) and encodes via platform channels.
  /// [thumbWidth]: Low-res dimension for local database storage (100px is optimal).
  /// [blurSize]: Dimensions for BlurHash calculation (32x32 provides sufficient entropy).
  static Future<ThumbBlurResult?> build(
      Uint8List originalFileBytes, {
        int thumbWidth = 100,
        int blurSize = 32,
        int compX = 4,
        int compY = 3,
      }) async {
    if (originalFileBytes.isEmpty) return null;

    final payload = {
      'fileBytes': originalFileBytes,
      'thumbWidth': thumbWidth,
      'blurSize': blurSize,
    };

    // 1. Image Scaling & Processing
    // Web: Runs in main thread; Mobile: Offloaded to Isolate to prevent UI jank.
    final Map<String, dynamic>? out = kIsWeb
        ? _worker(payload)
        : await compute(_worker, payload);

    if (out == null) return null;

    // 2. Main Thread: BlurHash Encoding
    String blurHash = "";

    try {
      // Direct processing of BlurHash (Supported on Web via pure Dart implementations).
      // Input images are extremely small, ensuring non-blocking UI performance.
      final Uint8List blurInputPng = out['blurInputPng'] as Uint8List;

      final String? hash = await bh.BlurHash.encode(blurInputPng, compX, compY);
      blurHash = hash ?? "";
    } catch (e) {
      debugPrint("[ThumbBlurHashService] BlurHash generation failed: $e");
    }

    return ThumbBlurResult(
      thumbBytes: out['thumbBytes'] as Uint8List,
      thumbW: out['thumbW'] as int,
      thumbH: out['thumbH'] as int,
      thumbMime: 'image/png',
      blurHash: blurHash,
    );
  }

  /// Atomic Image Processing Unit (Executes in Isolate or Web environment).
  @pragma('vm:entry-point')
  static Map<String, dynamic>? _worker(Map<String, dynamic> input) {
    try {
      final bytes = input['fileBytes'] as Uint8List;

      // Decode using the Image library
      final raw = img.decodeImage(bytes);
      if (raw == null) return null;

      // Step 1: Generate a small PNG for local DB storage (previewBytes placeholder)
      final thumbImg = img.copyResize(raw, width: input['thumbWidth'] as int);
      final thumbBytes = img.encodePng(thumbImg);

      // Step 2: Generate an ultra-small image (32x32) as input for the BlurHash algorithm.
      // BlurHash is detail-agnostic; smaller inputs yield faster computation and shorter strings.
      final blurImg = img.copyResize(raw, width: input['blurSize'] as int, height: input['blurSize'] as int);
      final blurInputPng = img.encodePng(blurImg);

      return <String, dynamic>{
        'thumbBytes': thumbBytes,
        'thumbW': thumbImg.width,
        'thumbH': thumbImg.height,
        'blurInputPng': blurInputPng,
      };
    } catch (e) {
      if (kDebugMode) print("[ThumbBlurHashService] Worker internal error: $e");
      return null;
    }
  }
}