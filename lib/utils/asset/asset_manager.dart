import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../ui/chat/models/chat_ui_model.dart';
import 'asset_store.dart'; // 引用 MessageType

class AssetManager {
  AssetManager._();

  //  1. 初始化策略：根据平台自动选择 (单例模式)
  static final AssetStore _store = kIsWeb ? WebAssetStore() : MobileAssetStore();

  //  2. 定义目录映射 (以后加 Video/File 就在这里加)
  static String _getSubDir(MessageType type) {
    switch (type) {
      case MessageType.audio:
        return 'chat_audio';
      case MessageType.video:
        return 'chat_video'; // 未来扩展非常容易
      case MessageType.image:
      default:
        return 'chat_images';
    }
  }

  //  3. 定义后缀映射
  static String _getExtension(String originalPath, MessageType type) {
    final ext = p.extension(originalPath);
    if (ext.isNotEmpty) return ext;

    // 兜底逻辑
    switch (type) {
      case MessageType.audio: return '.m4a';
      case MessageType.video: return '.mp4';
      default: return '.jpg';
    }
  }

  // ================= 业务方法 =================

  ///  [保存]：业务层只管传文件和类型，剩下的交给底层
  static Future<String> save(XFile rawFile, MessageType type) async {
    final fileName = "${const Uuid().v4()}${_getExtension(rawFile.path, type)}";
    final subDir = _getSubDir(type);

    await _store.saveFile(rawFile, fileName, subDir);

    return fileName; // 返回给数据库的纯文件名
  }

  /// [获取]：还原路径
  static Future<String?> getFullPath(String? fileName, MessageType type) async {
    if (fileName == null || fileName.isEmpty) return null;
    return await _store.getFullPath(fileName, _getSubDir(type));
  }
}