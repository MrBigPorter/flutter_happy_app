import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import 'asset_store.dart'; // 引入接口
import '../../ui/chat/models/chat_ui_model.dart'; // 引用 MessageType

// 如果是 HTML 环境（Web），导入 web 实现；否则导入 mobile 实现。
// 两个文件里都必须有一个叫 `PlatformAssetStore` 的类。
import 'asset_store_mobile.dart' if (dart.library.html) 'asset_store_web.dart';

class AssetManager {
  AssetManager._();

  // 1. 初始化：直接实例化 PlatformAssetStore，编译器会自动选择对应的文件
  static final AssetStore _store = PlatformAssetStore();

  // 2. 目录映射
  static String getSubDir(MessageType type) {
    switch (type) {
      case MessageType.audio: return 'chat_audio';
      case MessageType.video: return 'chat_video';
      case MessageType.file:  return 'chat_files';
      case MessageType.image:
      default: return 'chat_images';
    }
  }

  // 3. 后缀映射
  static String _getExtension(String originalPath, MessageType type) {
    String ext = '';
    try {
      ext = p.extension(originalPath);
    } catch (_) {} // Web blob 路径可能导致 path 解析异常，加个 try-catch

    if (ext.isNotEmpty) return ext;

    // 兜底逻辑
    switch (type) {
      case MessageType.audio: return '.m4a';
      case MessageType.video: return '.mp4';
      case MessageType.file:  return '.bin';
      default: return '.jpg';
    }
  }

  static String generateAvatarKey(List<String> urls) {
    if (urls.isEmpty) return 'default_group';
    final sortedUrls = List<String>.from(urls)..sort();
    final String combined = sortedUrls.join('|');
    final digest = md5.convert(combined.codeUnits);
    return hex.encode(digest.bytes);
  }

  // ================= 业务方法 =================

  /// [保存]
  static Future<String> save(XFile rawFile, MessageType type) async {
    final fileName = "${const Uuid().v4()}${_getExtension(rawFile.path, type)}";
    final subDir = getSubDir(type);

    await _store.saveFile(rawFile, fileName, subDir);

    return fileName;
  }

  /// [获取]
  static Future<String?> getFullPath(String? fileName, MessageType type) async {
    if (fileName == null || fileName.isEmpty) return null;
    return await _store.getFullPath(fileName, getSubDir(type));
  }

  // ================= 群头像缓存业务 =================

  /// [查] 获取本地缓存的头像路径
  /// 注意：这里返回 String? 而不是 File?，因为 Web 端没有 File 类
  static Future<String?> getCachedAvatar(String key) async {
    return await _store.getCachedAvatarPath(key);
  }

  /// [存]
  static Future<void> saveAvatar(String key, Uint8List bytes) async {
    await _store.saveAvatar(key, bytes);
  }
}