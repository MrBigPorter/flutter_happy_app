import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cross_file/cross_file.dart';
import 'asset_store.dart';

/// 这是一个具体的类，供 AssetManager 条件导入使用
class PlatformAssetStore implements AssetStore {
  final String _avatarDir = 'group_avatars';

  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, subDir));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final savePath = p.join(dir.path, fileName);
    try {
      // 尝试移动文件（高效）
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
    final fullPath = p.join(appDir.path, subDir, p.basename(fileName));
    if (File(fullPath).existsSync()) {
      return fullPath;
    }
    return null;
  }

  @override
  Future<String?> getCachedAvatarPath(String key) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, _avatarDir, '$key.png');
      final file = File(path);
      if (file.existsSync() && await file.length() > 0) {
        return path;
      }
    } catch (e) {
      debugPrint("Get Cached Avatar Error: $e");
    }
    return null;
  }

  @override
  Future<void> saveAvatar(String key, Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final avatarDir = Directory(p.join(dir.path, _avatarDir));
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final path = p.join(avatarDir.path, '$key.png');
      await File(path).writeAsBytes(bytes);
    } catch (e) {
      debugPrint("Save Avatar Error: $e");
    }
  }
}