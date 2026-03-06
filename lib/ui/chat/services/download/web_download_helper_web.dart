import 'dart:js_interop';
import 'package:web/web.dart' as web;

// 真实的 H5 浏览器下载逻辑全在这里
void downloadFileWeb(String url, {String? fileName}) {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.target = '_blank';

  String finalName = fileName ?? '';
  if (finalName.isEmpty) {
    if (url.startsWith('http')) finalName = url.split('/').last;
    if (finalName.isEmpty || finalName.contains('?')) finalName = "download_file.pdf";
  }
  anchor.download = finalName;

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}