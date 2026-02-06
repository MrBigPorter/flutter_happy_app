enum MediaPathType {
  empty,
  localAbs,
  fileUri,
  blob,
  asset,
  http,
  uploads,
  relative,
  unknown,
}

class MediaPath {
  static MediaPathType classify(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty || p == '[Image]' || p == '[File]') return MediaPathType.empty;

    if (p.startsWith('blob:')) return MediaPathType.blob;
    if (p.startsWith('file://')) return MediaPathType.fileUri;
    if (p.startsWith('assets/')) return MediaPathType.asset;
    if (p.startsWith('/')) return MediaPathType.localAbs;
    if (p.startsWith('http://') || p.startsWith('https://')) return MediaPathType.http;

    if (p.startsWith('uploads/') || p.contains('/uploads/') || p.contains('uploads/')) {
      return MediaPathType.uploads;
    }

    if (p.contains('/')) return MediaPathType.relative;
    return MediaPathType.unknown;
  }

  static bool isLocal(String? path) {
    final t = classify(path);
    return t == MediaPathType.localAbs ||
        t == MediaPathType.fileUri ||
        t == MediaPathType.blob ||
        t == MediaPathType.asset;
  }

  static bool isHttp(String? path) => classify(path) == MediaPathType.http;

  static bool isRemote(String? path) {
    final t = classify(path);
    return t == MediaPathType.http || t == MediaPathType.uploads || t == MediaPathType.relative;
  }

  /// 统一把各种写法（含带域名的）裁剪成 key（uploads/...）
  static String normalizeRemoteKey(String path, {String uploadsDir = 'uploads/'}) {
    var res = path.trim();
    if (res.contains(uploadsDir)) {
      res = res.substring(res.indexOf(uploadsDir));
    }
    while (res.startsWith('/')) res = res.substring(1);
    return res;
  }
}