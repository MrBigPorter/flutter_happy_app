import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p; //  引入 path 库，处理路径最稳

class ImageUtils {
  static Future<String?> compressImage(String path) async {
    try {
      // 1. 获取原文件的扩展名 (例如 .jpg, .png, .HEIC)
      final extension = p.extension(path);

      // 2. 构造输出路径: /path/to/image.jpg -> /path/to/image_out.jpg
      // 使用 p.withoutExtension 安全去掉后缀，再拼回去
      final outPath = "${p.withoutExtension(path)}_out$extension";

      // 3. 执行压缩
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        outPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1080,
        // 💡 自动旋转：防止有些手机拍出来的照片是横着的
        autoCorrectionAngle: true,
      );

      return result?.path;
    } catch (e) {
      // 压缩出错了（比如文件损坏），优雅降级返回原图，不要崩
      return path;
    }
  }
}