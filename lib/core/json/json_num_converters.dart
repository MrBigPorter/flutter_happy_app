class JsonNumConverter {
  static double toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static double? toDoubleOrNull(dynamic val) {
    if (val == null) return null;
    return toDouble(val);
  }

  static String doubleToString(double? val) {
    return val?.toString() ?? '0.00';
  }

  static String? toStringOrNull(dynamic val) {
    if (val == null) return null;
    return val.toString();
  }

  static int toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}