import 'dart:convert';
import 'dart:io';

import 'utils/io_utils.dart';

/// 将 JSON key 转换成合法的 Dart 标识符
String sanitizeKey(String key) {
  // 1. 处理破折号 → 下划线
  var result = key.replaceAll('-', '_');

  // 2. 如果以数字开头 → 加前缀 tw_
  if (RegExp(r'^[0-9]').hasMatch(result)) {
    result = 'tw_$result';
  }

  // 3. 特殊 case: "paragraph-max-width" → paragraph_max_width
  // （其实上面 replaceAll 已经处理了）
  return result;
}

/// 将 rem 转换成 double（假设 1rem = 1.0）
double parseRem(String value) {
  if (value.endsWith("rem")) {
    return double.parse(value.replaceAll("rem", ""));
  }
  return double.parse(value);
}

void main(List<String> args) {
  if (args.length < 2) {
    stdout.write("Usage: dart run tool/gen_metrics.dart <input.json> <output.dart>");
    exit(1);
  }

  final inputFile = File(args[0]);
  final outputFile = File(args[1]);

  final json = jsonDecode(inputFile.readAsStringSync()) as Map<String, dynamic>;

  final buffer = StringBuffer();
  buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
  buffer.writeln("// ignore_for_file: constant_identifier_names");
  buffer.writeln("// Source: ${args[0]}");
  buffer.writeln("library tw_metrics;\n");

  // 遍历 json 顶层 keys
  json.forEach((category, values) {
    if (values is Map<String, dynamic>) {
      final className = "Tw${category[0].toUpperCase()}${category.substring(1)}";

      // Map 常量
      buffer.writeln("const Map<String, double> kTw$category = {");
      values.forEach((k, v) {
        buffer.writeln("  '$k': ${parseRem(v.toString())},");
      });
      buffer.writeln("};\n");

      // 类
      buffer.writeln("class $className { const $className._();");
      values.forEach((k, v) {
        final safeKey = sanitizeKey(k);
        buffer.writeln("  static const double $safeKey = ${parseRem(v.toString())};");
      });
      buffer.writeln("}\n");
    }
  });

  //outputFile.writeAsStringSync(buffer.toString());
  writeFileIfChanged(outputFile.path, buffer.toString());
}