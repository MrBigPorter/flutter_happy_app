// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadImageOnWeb(Uint8List bytes, {String? imageUrl}) async {
  if (imageUrl != null) {
    // 直接用 URL 触发浏览器下载
    final a = html.AnchorElement(href: imageUrl)
      ..download = 'poster.png'
      ..target = '_blank';
    a.click();
    return;
  }

  // 从 bytes 生成 Blob 然后下载
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

   html.AnchorElement(href: url)
    ..download = 'poster.png'
    ..click();

  html.Url.revokeObjectUrl(url);
}