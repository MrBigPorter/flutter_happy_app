/// check if an object is null or empty
extension NullOrEmpty on Object? {
  bool get isNullOrEmpty => switch (this) {
    null => true,
    String s => s.isEmpty,
    Iterable i => i.isEmpty,
    Map m => m.isEmpty,
    _ => false,
  };

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

/// Parse a list of JSON objects into a list of Dart objects using the provided fromJson function
List<T> parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final list = raw as List;
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
