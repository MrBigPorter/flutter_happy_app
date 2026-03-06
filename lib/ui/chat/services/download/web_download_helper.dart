//  核心魔法：Web 环境用 web 版，手机环境用 stub 壳子
export 'web_download_helper_stub.dart' if (dart.library.js_interop) 'web_download_helper_web.dart';