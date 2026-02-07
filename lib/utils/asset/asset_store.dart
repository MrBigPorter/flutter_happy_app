import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

abstract class AssetStore {
  String get basePath;

  Future<void> init();

  Future<void> saveFile(XFile source, String fileName, String subDir);

  bool existsSync(String fullPath);

  Future<String?> getCachedAvatarPath(String key);

  Future<void> saveAvatar(String key, Uint8List bytes);
}
