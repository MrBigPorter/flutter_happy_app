/// Lucky IM Web 兼容性桩文件
/// 当在 Mobile 端运行时，代码会引用这个文件而不是真正的 dart:html
library web_image_utils;

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class Blob {
  Blob(List<dynamic> bytes);
}

class ImageElement {
  ImageElement({String? src});
  String? src;
  int naturalWidth = 0;
  int naturalHeight = 0;
  // 提供一个空的 Stream 避免 Mobile 端报错
  Stream<dynamic> get onLoad => const Stream.empty();
}

class CanvasElement {
  CanvasElement({int? width, int? height});
  CanvasRenderingContext2D get context2D => CanvasRenderingContext2D();
  String toDataUrl(String type, double quality) => '';
}

class CanvasRenderingContext2D {
  void drawImageScaled(dynamic source, num x, num y, num w, num h) {}
}