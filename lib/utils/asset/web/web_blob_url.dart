//  核心魔法：如果是 Web 环境，自动加载 web 版，否则加载 stub 壳子
export 'web_blob_url_stub.dart' if (dart.library.js_interop) 'web_blob_url_web.dart';