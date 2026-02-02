import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../ui/chat/models/chat_ui_model.dart';
import 'asset_store.dart'; // 引用 MessageType


class AssetManager {
  AssetManager._();

  //  1. 初始化策略：根据平台自动选择 (单例模式)
  static final AssetStore _store = kIsWeb
      ? WebAssetStore()
      : MobileAssetStore();

  //  2. 定义目录映射 (以后加 Video/File 就在这里加)
  static String getSubDir(MessageType type) {
    switch (type) {
      case MessageType.audio:
        return 'chat_audio';
      case MessageType.video:
        return 'chat_video'; // 未来扩展非常容易
      case MessageType.file:
        return 'chat_files';
      case MessageType.image:
      default:
        return 'chat_images';
    }
  }

  // 头像目录
  static const String _avatarDir = 'group_avatars';

  //  3. 定义后缀映射
  static String _getExtension(String originalPath, MessageType type) {
    final ext = p.extension(originalPath);
    if (ext.isNotEmpty) return ext;

    // 兜底逻辑
    switch (type) {
      case MessageType.audio:
        return '.m4a';
      case MessageType.video:
        return '.mp4';
      case MessageType.file:
        return '.bin'; //  文件如果没有后缀，给个 .bin
      default:
        return '.jpg';
    }
  }

  //  4. 头像专用方法：生成唯一 Key
  static String generateAvatarKey(List<String> urls) {
    if (urls.isEmpty) return 'default_group';
    final sortedUrls = List<String>.from(urls)..sort();
    final String combined = sortedUrls.join('|');
    final digest = md5.convert(combined.codeUnits);
    return hex.encode(digest.bytes);
  }

  // ================= 业务方法 =================

  ///  [保存]：业务层只管传文件和类型，剩下的交给底层
  static Future<String> save(XFile rawFile, MessageType type) async {
    final fileName = "${const Uuid().v4()}${_getExtension(rawFile.path, type)}";
    final subDir = getSubDir(type);

    await _store.saveFile(rawFile, fileName, subDir);

    return fileName; // 返回给数据库的纯文件名
  }

  /// [获取]：还原路径
  static Future<String?> getFullPath(String? fileName, MessageType type) async {
    if (fileName == null || fileName.isEmpty) return null;
    return await _store.getFullPath(fileName, getSubDir(type));
  }

  // =================  群头像缓存业务 (新增) =================
  // 注意：头像缓存主要用于 Native 端优化，Web 端交给浏览器
  /// [查] 获取本地缓存的头像文件
  static Future<File?> getCachedAvatar(String key) async {
    if (kIsWeb) return null; // Web 端不缓存

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$_avatarDir/$key.png';
      final file = File(path);
      if (file.existsSync() && await file.length() > 0) {
        return file;
      }
    } catch (e) {
      debugPrint("Get Cached Avatar Error: $e");
    }
    return null;
  }

  /// [存] 将合成好的 Bytes 写入本地
  static Future<File?> saveAvatar(String key, Uint8List bytes) async {
    if (kIsWeb) return null; // Web 端不缓存

    try {
      final dir = await getTemporaryDirectory();
      // 确保目录存在
      final avatarDir = Directory('${dir.path}/$_avatarDir');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final path = '${avatarDir.path}/$key.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint("Save Avatar Error: $e");
    }
    return null;
  }
}
