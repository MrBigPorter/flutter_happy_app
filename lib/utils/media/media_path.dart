enum MediaPathType {
  empty,
  localAbs,
  fileUri,
  blob,
  asset,
  http,
  uploads,
  relative, //  加回来了，为了兼容旧代码不报错
  unknown,  //  新增：所有不认识的路径都归这里
}

class MediaPath {
  static MediaPathType classify(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty) return MediaPathType.empty;

    // 1. 识别标准的本地/Web 协议
    if (p.startsWith('blob:')) return MediaPathType.blob;
    if (p.startsWith('file://')) return MediaPathType.fileUri;
    if (p.startsWith('assets/')) return MediaPathType.asset;
    if (p.startsWith('/')) return MediaPathType.localAbs;

    // 2.  重点：识别 AssetManager 存储的本地业务目录
    if (p.startsWith('chat_images/') ||
        p.startsWith('chat_audio/') ||
        p.startsWith('chat_video/')) {
      return MediaPathType.localAbs; // 统一归类为本地，或者加个 localRelative
    }

    // 3. 识别远程
    if (p.startsWith('http://') || p.startsWith('https://')) return MediaPathType.http;
    if (p.startsWith('uploads/')) return MediaPathType.uploads;

    return MediaPathType.unknown;
  }

  static bool isRemote(String? path) {
    final t = classify(path);
    // relative 保留在这里是为了兼容，但 classify 不会返回它了
    return t == MediaPathType.http || t == MediaPathType.uploads || t == MediaPathType.relative;
  }

  static bool isLocal(String? path) {
    final t = classify(path);
    return t == MediaPathType.localAbs ||
        t == MediaPathType.fileUri ||
        t == MediaPathType.blob ||
        t == MediaPathType.asset ||
        t == MediaPathType.unknown; //  未知路径优先当本地处理
  }

  static bool isHttp(String? path) => classify(path) == MediaPathType.http;

  static String normalizeRemoteKey(String path, {String uploadsDir = 'uploads/'}) {
    var res = path.trim();
    if (res.contains(uploadsDir)) {
      res = res.substring(res.indexOf(uploadsDir));
    }
    while (res.startsWith('/')) res = res.substring(1);
    return res;
  }
}