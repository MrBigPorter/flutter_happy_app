import 'chat_ui_model.dart';

// --- 1. File Message Extensions ---
extension FileMessageExt on ChatUiModel {
  /// Extracts the original file name from metadata
  String? get fileName => meta?['fileName'] ?? meta?['name'];

  /// Parses the file size into an integer format
  int? get fileSize {
    final s = meta?['fileSize'];
    if (s is int) return s;
    return int.tryParse(s?.toString() ?? '0');
  }

  /// Extracts the file extension, prioritizing 'fileExt' or falling back to filename parsing
  String? get fileExt => meta?['fileExt'] ??
      (fileName?.contains('.') == true ? fileName!.split('.').last : null);

  /// Converts bytes into a human-readable string (B, KB, MB)
  String get displaySize {
    final size = fileSize;
    if (size == null || size == 0) return '0 B';
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// --- 2. Media (Image/Video) Message Extensions ---
extension MediaMessageExt on ChatUiModel {
  /// Safe parsing of image/video width from metadata
  double? get imgWidth => meta?['w'] is num ? (meta!['w'] as num).toDouble() : null;

  /// Safe parsing of image/video height from metadata
  double? get imgHeight => meta?['h'] is num ? (meta!['h'] as num).toDouble() : null;

  /// Retrieves the blurHash string for placeholder rendering
  String? get blurHash => meta?['blurHash'] as String?;
}

// --- 3. Location Message Extensions ---
extension LocationMessageExt on ChatUiModel {
  /// Latitude coordinate parsed from location metadata
  double? get latitude => meta?['latitude'] is num ? (meta!['latitude'] as num).toDouble() : null;

  /// Longitude coordinate parsed from location metadata
  double? get longitude => meta?['longitude'] is num ? (meta!['longitude'] as num).toDouble() : null;

  /// Physical address string (e.g., Street name)
  String? get address => meta?['address'] as String?;

  /// Descriptive title for the location (e.g., Building name)
  String? get locationTitle => meta?['title'] as String?;
}