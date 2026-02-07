import 'dart:io';
import 'dart:typed_data'; // 必须引入
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:image/image.dart' as img;

import '../../../../core/api/http_client.dart';

class GroupAvatarService {

  static Future<Uint8List?> getOrGenerateGroupAvatar(List<String> memberUrls) async {
    if (memberUrls.isEmpty) return null;

    // 1. 生成唯一 Key
    final validUrls = memberUrls.where((url) => url.isNotEmpty).take(9).toList();
    if (validUrls.isEmpty) return null;

    final key = AssetManager.generateAvatarKey(validUrls);

    // 2. [修复] 检查本地缓存 (Native Only)
    // 刚才 AssetManager 改成了返回 String 路径，所以这里要改
    if (!kIsWeb) {
      final String? cachedPath = await AssetManager.getCachedAvatar(key);
      if (cachedPath != null && cachedPath.isNotEmpty) {
        final file = File(cachedPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    }

    // 3. 生成新头像
    try {
      // Fetch
      final List<Uint8List> imagesData = await _fetchAllImages(validUrls);
      if (imagesData.isEmpty) return null;

      // Compute (Isolate)
      final Uint8List? composedBytes = await compute(_composeImages, imagesData);

      // Save
      if (composedBytes != null && !kIsWeb) {
        await AssetManager.saveAvatar(key, composedBytes);
      }
      return composedBytes;
    } catch (e) {
      debugPrint("Group Avatar Generation Error: $e");
      return null;
    }
  }

  // --- Helpers ---

  static Future<List<Uint8List>> _fetchAllImages(List<String> urls) async {
    final List<Future<Uint8List?>> tasks = urls.map((url) async {
      try {
        final resp = await Http.rawDio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        // 强转类型，确保安全
        if (resp.data is List<int>) {
          return Uint8List.fromList(resp.data);
        }
        return null;
      } catch (e) {
        debugPrint("Fetch Avatar Image Error: $e");
        return null;
      }
    }).toList();

    final results = await Future.wait(tasks);
    return results.whereType<Uint8List>().toList();
  }

  // 这里的逻辑稍微调整以适配 image 库的强类型检查
  static Uint8List? _composeImages(List<Uint8List> imagesData) {
    if (imagesData.isEmpty) return null;

    const int size = 200;
    const int gap = 4;

    // 创建画布
    final canvas = img.Image(width: size, height: size);

    // 填充背景 (灰白)
    img.fill(canvas, color: img.ColorRgb8(240, 240, 240));

    int count = imagesData.length;
    if (count > 9) count = 9;

    // 计算九宫格布局
    int columns = 1;
    if (count >= 2 && count <= 4) columns = 2;
    if (count >= 5) columns = 3;

    final int cellSize = (size - (columns + 1) * gap) ~/ columns;

    for (int i = 0; i < count; i++) {
      // 解码图片
      final smallImage = img.decodeImage(imagesData[i]);
      if (smallImage == null) continue;

      // 缩放
      final resized = img.copyResize(
        smallImage,
        width: cellSize,
        height: cellSize,
        interpolation: img.Interpolation.average,
      );

      // 计算坐标
      final row = i ~/ columns;
      final col = i % columns;

      int x = gap + col * (cellSize + gap);
      int y = gap + row * (cellSize + gap);

      // 3张图特殊处理：第一张居中
      if (count == 3 && i == 0) {
        x = (size - cellSize) ~/ 2;
      }

      // 绘制 (注意 compositeImage API 参数)
      img.compositeImage(canvas, resized, dstX: x, dstY: y);
    }

    return Uint8List.fromList(img.encodePng(canvas));
  }
}