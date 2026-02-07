import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:cross_file/cross_file.dart';

import 'asset_store.dart';
import '../../ui/chat/models/chat_ui_model.dart';
import 'asset_store_mobile.dart' if (dart.library.html) 'asset_store_web.dart';

class AssetManager {
  AssetManager._();

  static final AssetStore _store = PlatformAssetStore();

  static Future<void> init() async => await _store.init();

  static String getRuntimePath(String? path) {
    if (path == null || path.isEmpty) return '';
    if (kIsWeb ||
        path.startsWith('http') ||
        path.startsWith('blob:') ||
        path.startsWith('/'))
      return path;
    return p.join(_store.basePath, path);
  }

  static bool existsSync(String? path) =>
      _store.existsSync(getRuntimePath(path));

  static Future<String> save(XFile rawFile, MessageType type) async {
    final subDir = getSubDir(type);
    final ext = p.extension(rawFile.path).isEmpty
        ? _getExt(type)
        : p.extension(rawFile.path);
    final fileName = "${const Uuid().v4()}$ext";
    await _store.saveFile(rawFile, fileName, subDir);
    return p.join(subDir, fileName); // 存储相对路径协议
  }

  // 兼容旧代码
  static Future<String?> getFullPath(String? fileName, MessageType type) async {
    if (fileName == null || fileName.isEmpty) return null;
    String path = getRuntimePath(fileName);
    if (!existsSync(path) && !fileName.contains('/')) {
      path = getRuntimePath(p.join(getSubDir(type), fileName));
    }
    return existsSync(path) ? path : null;
  }

  static String generateAvatarKey(List<String> urls) {
    final sorted = List<String>.from(urls)..sort();
    return hex.encode(md5.convert(sorted.join('|').codeUnits).bytes);
  }

  static Future<String?> getCachedAvatar(String key) =>
      _store.getCachedAvatarPath(key);

  static Future<void> saveAvatar(String key, Uint8List bytes) =>
      _store.saveAvatar(key, bytes);

  static String getSubDir(MessageType type) {
    if (type == MessageType.audio) return 'chat_audio';
    if (type == MessageType.video) return 'chat_video';
    return 'chat_images';
  }

  static String _getExt(MessageType type) =>
      type == MessageType.video ? '.mp4' : '.jpg';
}
