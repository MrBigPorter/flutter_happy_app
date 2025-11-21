abstract class JsonNumConverter {
  static double toDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  static String doubleToString(dynamic value) {
    if (value is String) {
      return value;
    } else if (value is int || value is double || value is bool) {
      return value.toString();
    } else {
      return '';
    }
  }
}