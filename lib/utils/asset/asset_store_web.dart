import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'asset_store.dart';

class PlatformAssetStore implements AssetStore {
  @override
  String get basePath => '';
  @override
  Future<void> init() async {}
  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {}
  @override
  bool existsSync(String fullPath) => false;
  @override
  Future<String?> getCachedAvatarPath(String key) async => null;
  @override
  Future<void> saveAvatar(String key, Uint8List bytes) async {}
}