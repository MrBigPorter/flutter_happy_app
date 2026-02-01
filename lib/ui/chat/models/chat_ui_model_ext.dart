import 'chat_ui_model.dart';

// --- 1. 文件消息扩展 ---
extension FileMessageExt on ChatUiModel {
  String? get fileName => meta?['fileName'] ?? meta?['name'];

  int? get fileSize {
    final s = meta?['fileSize'];
    if (s is int) return s;
    return int.tryParse(s?.toString() ?? '0');
  }

  String? get fileExt => meta?['fileExt'] ??
      (fileName?.contains('.') == true ? fileName!.split('.').last : null);

  String get displaySize {
    final size = fileSize;
    if (size == null || size == 0) return '0 B';
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// --- 2. 媒体(图/视)消息扩展 ---
extension MediaMessageExt on ChatUiModel {
  double? get imgWidth => meta?['w'] is num ? (meta!['w'] as num).toDouble() : null;
  double? get imgHeight => meta?['h'] is num ? (meta!['h'] as num).toDouble() : null;
  String? get blurHash => meta?['blurHash'] as String?;
}

// --- 3. 新增：位置消息扩展 ---
extension LocationMessageExt on ChatUiModel {
  double? get latitude => meta?['latitude'] is num ? (meta!['latitude'] as num).toDouble() : null;
  double? get longitude => meta?['longitude'] is num ? (meta!['longitude'] as num).toDouble() : null;
  String? get address => meta?['address'] as String?;
  String? get locationTitle => meta?['title'] as String?;
}