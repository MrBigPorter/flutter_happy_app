import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cross_file/cross_file.dart';
import 'asset_store.dart';

class PlatformAssetStore implements AssetStore {
  String _docPath = '';

  @override
  String get basePath => _docPath;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _docPath = dir.path;
  }

  @override
  Future<void> saveFile(XFile source, String fileName, String subDir) async {
    final targetDir = Directory(p.join(_docPath, subDir));
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
    final targetPath = p.join(targetDir.path, fileName);
    await File(source.path).copy(targetPath);
  }

  @override
  bool existsSync(String fullPath) =>
      fullPath.isNotEmpty && File(fullPath).existsSync();

  @override
  Future<String?> getCachedAvatarPath(String key) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'group_avatars', '$key.png');
    return File(path).existsSync() ? path : null;
  }

  @override
  Future<void> saveAvatar(String key, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final avatarDir = Directory(p.join(dir.path, 'group_avatars'));
    if (!avatarDir.existsSync()) avatarDir.createSync(recursive: true);
    await File(p.join(avatarDir.path, '$key.png')).writeAsBytes(bytes);
  }
}
