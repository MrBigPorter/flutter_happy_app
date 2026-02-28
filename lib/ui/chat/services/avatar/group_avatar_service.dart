import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:image/image.dart' as img;

import '../../../../core/api/http_client.dart';

class GroupAvatarService {
  /// Entry point: Returns cached group avatar bytes or generates a new composite image.
  /// [memberUrls]: List of participant avatar URLs (up to 9 will be processed).
  static Future<Uint8List?> getOrGenerateGroupAvatar(List<String> memberUrls) async {
    if (memberUrls.isEmpty) return null;

    // 1. Generate unique cache key based on URL hashes
    final validUrls = memberUrls.where((url) => url.isNotEmpty).take(9).toList();
    if (validUrls.isEmpty) return null;

    final key = AssetManager.generateAvatarKey(validUrls);

    // 2. Cache Validation (Native Mobile only)
    if (!kIsWeb) {
      final String? cachedPath = await AssetManager.getCachedAvatar(key);
      if (cachedPath != null && cachedPath.isNotEmpty) {
        final file = File(cachedPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    }

    // 3. New Avatar Generation Lifecycle
    try {
      // Step A: Fetch remote image bytes in parallel
      final List<Uint8List> imagesData = await _fetchAllImages(validUrls);
      if (imagesData.isEmpty) return null;

      // Step B: Offload heavy image processing to a background Isolate
      final Uint8List? composedBytes = await compute(_composeImages, imagesData);

      // Step C: Persist generated result to local storage (Mobile)
      if (composedBytes != null && !kIsWeb) {
        await AssetManager.saveAvatar(key, composedBytes);
      }
      return composedBytes;
    } catch (e) {
      debugPrint("[GroupAvatarService] Generation Error: $e");
      return null;
    }
  }

  // --- Networking Helpers ---

  /// Fetches raw image bytes for multiple URLs concurrently
  static Future<List<Uint8List>> _fetchAllImages(List<String> urls) async {
    final List<Future<Uint8List?>> tasks = urls.map((url) async {
      try {
        final resp = await Http.rawDio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (resp.data is List<int>) {
          return Uint8List.fromList(resp.data);
        }
        return null;
      } catch (e) {
        debugPrint("[GroupAvatarService] Fetch Error: $e");
        return null;
      }
    }).toList();

    final results = await Future.wait(tasks);
    return results.whereType<Uint8List>().toList();
  }

  // --- Image Processing Logic (Executed in Isolate) ---

  /// Internal algorithmic logic for composing multiple avatars into a single grid.
  static Uint8List? _composeImages(List<Uint8List> imagesData) {
    if (imagesData.isEmpty) return null;

    const int size = 200; // Final canvas size
    const int gap = 4;   // Spacing between sub-images

    // Initialize blank canvas
    final canvas = img.Image(width: size, height: size);

    // Fill background with light gray (HEX: F0F0F0)
    img.fill(canvas, color: img.ColorRgb8(240, 240, 240));

    int count = imagesData.length;
    if (count > 9) count = 9;

    // Calculate grid layout columns based on participant count
    int columns = 1;
    if (count >= 2 && count <= 4) columns = 2;
    if (count >= 5) columns = 3;

    final int cellSize = (size - (columns + 1) * gap) ~/ columns;

    for (int i = 0; i < count; i++) {
      // Decode raw bytes into Image object
      final smallImage = img.decodeImage(imagesData[i]);
      if (smallImage == null) continue;

      // Downscale to fit the calculated cell size
      final resized = img.copyResize(
        smallImage,
        width: cellSize,
        height: cellSize,
        interpolation: img.Interpolation.average,
      );

      // Calculate placement coordinates
      final row = i ~/ columns;
      final col = i % columns;

      int x = gap + col * (cellSize + gap);
      int y = gap + row * (cellSize + gap);

      // Visual Optimization: Center the first avatar if exactly 3 participants exist
      if (count == 3 && i == 0) {
        x = (size - cellSize) ~/ 2;
      }

      // Merge sub-image into the main canvas
      img.compositeImage(canvas, resized, dstX: x, dstY: y);
    }

    // Encode result as PNG bytes
    return Uint8List.fromList(img.encodePng(canvas));
  }
}