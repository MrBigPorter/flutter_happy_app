import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

/// [底层策略接口]
abstract class AssetStore {
  /// 保存普通聊天文件
  Future<void> saveFile(XFile source, String fileName, String subDir);

  /// 获取普通文件路径
  Future<String?> getFullPath(String fileName, String subDir);

  // --- 新增：将头像的 IO 操作也下沉到这里 ---

  /// 获取缓存头像路径 (Mobile返回路径, Web返回null)
  Future<String?> getCachedAvatarPath(String key);

  /// 保存头像 (Mobile写入文件, Web忽略)
  Future<void> saveAvatar(String key, Uint8List bytes);
}