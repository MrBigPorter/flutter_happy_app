import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cross_file/cross_file.dart';

/// [底层策略接口]
/// 不关心业务（是头像还是聊天图），只关心：给我个文件，我把它存到指定目录
abstract class AssetStore {
  Future<void> saveFile(XFile source, String fileName, String subDir);
  Future<String?> getFullPath(String fileName, String subDir);
}

///  [Mobile 实现]：物理文件存储
class MobileAssetStore implements AssetStore {
  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, subDir));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final savePath = p.join(dir.path, fileName);

    // 优先尝试 rename (剪切)，失败则 copy (复制)，再失败则 read/write
    try {
      // 如果是刚录好的音，rename 效率最高
      await File(source.path).copy(savePath);
    } catch (e) {
      debugPrint("MobileStore Copy Error: $e, fallback to write.");
      await File(savePath).writeAsBytes(await source.readAsBytes());
    }
  }

  @override
  Future<String?> getFullPath(String fileName, String subDir) async {
    if (fileName.isEmpty) return null;
    final appDir = await getApplicationDocumentsDirectory();
    // 清洗文件名，防止注入路径
    final cleanName = p.basename(fileName);
    final fullPath = p.join(appDir.path, subDir, cleanName);

    if (File(fullPath).existsSync()) {
      return fullPath;
    }
    return null;
  }
}

///  [Web 实现]：虚拟存储 (Pass-through)
class WebAssetStore implements AssetStore {
  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {
    // Web 端不需要物理移动文件，浏览器已经管理了 Blob
    // 这里什么都不用做，或者可以做一些 IndexedDB 的缓存逻辑
    return;
  }

  @override
  Future<String?> getFullPath(String fileName, String subDir) async {
    // Web 端只认 HTTP 或 Blob 协议
    if (fileName.startsWith('http') || fileName.startsWith('blob:')) {
      return fileName;
    }
    return null;
  }
}