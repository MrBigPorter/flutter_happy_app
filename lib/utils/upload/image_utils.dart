import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static Future<String> compressImage(String path) async {
    final lastIndex = path.lastIndexOf(new RegExp(r'.jp'));
    final split = path.substring(0, (lastIndex));
    final outPath = "${split}_out${path.substring(lastIndex)}";

    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      outPath,
      quality: 80, // 质量设为 80 左右，肉眼无差，体积骤减
      minWidth: 1920, // 限制最大宽度，适合后端 OCR 识别
      minHeight: 1080,
    );
    return result?.path ?? path; // 压缩失败则返回原路径
  }
}