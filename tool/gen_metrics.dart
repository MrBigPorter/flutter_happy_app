import 'dart:convert';
import 'dart:io';

import 'utils/io_utils.dart';

/// 将 JSON key 转换成 Dart 可用的标识符
String sanitizeKey(String key) {
  var result = key.replaceAll('-', '_');
  if (RegExp(r'^[0-9]').hasMatch(result)) {
    result = 'n$result';
  }
  return result;
}

/// 规范化 JSON key：把 display_* 映射到 2xl~6xl
String normalizeKey(String category, String key) {
  if (category == "fontSize" || category == "lineHeight") {
    switch (key) {
      case "display_xs": return "2xl";
      case "display_sm": return "3xl";
      case "display_md": return "4xl";
      case "display_lg": return "5xl";
      case "display_xl": return "6xl";
    }
  }
  return key;
}

/// 给 context 扩展方法用的 key（去掉 text_ 前缀）
String methodKey(String category, String key) {
  var k = normalizeKey(category, key).replaceAll('-', '_');
  if (category == "lineHeight" && k.startsWith("text_")) {
    k = k.substring(5); // 去掉 text_
  }
  return k;
}

/// 驼峰化：`sm` -> `Sm`, `paragraph_max_width` -> `ParagraphMaxWidth`
/// 特殊：数字开头（2xl）直接返回
String _camel(String key) {
  if (RegExp(r'^\d').hasMatch(key)) return key; // e.g. 2xl 保持原样
  return key
      .split('_')
      .map((part) =>
  part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
      .join();
}

/// 给 BuildContext 扩展生成 getter 名
String makeContextGetterName(String category, String methodKey) {
  final camel = _camel(methodKey);
  switch (category) {
    case "fontSize":
      return "text$camel"; // textSm, text2xl
    case "lineHeight":
      return "leading$camel"; // leadingSm, leading2xl
    case "spacing":
      return "spacing$camel";
    case "borderRadius":
      return "round$camel"; // roundMd
    case "width":
      return "width$camel"; // widthParagraphMaxWidth
    default:
      return "${category}_$camel";
  }
}

/// 转换带单位的值
String parseRemWithUnit(String value, String category) {
  double num;
  if (value.endsWith("rem")) {
    num = double.parse(value.replaceAll("rem", ""));
  } else {
    num = double.parse(value);
  }

  switch (category) {
    case "fontSize":
    case "lineHeight":
      return "$num.sp";
    case "spacing":
    case "width":
      return "$num.w";
    case "borderRadius":
      return "$num.r";
    default:
      return num.toString();
  }
}

extension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}

void main(List<String> args) {
  if (args.length < 2) {
    stdout.writeln(
        "用法: dart run tool/gen_metrics.dart <input.json> <output.dart>");
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
  buffer.writeln("import 'package:flutter_screenutil/flutter_screenutil.dart';");
  buffer.writeln("import 'package:flutter/widgets.dart';\n");

  // ====== 生成常量类 ======
  json.forEach((category, values) {
    if (values is Map<String, dynamic>) {
      final className = "Tw${category[0].toUpperCase()}${category.substring(1)}";

      // Map 常量
      buffer.writeln("final Map<String, dynamic> kTw$category = {");
      values.forEach((k, v) {
        final normalized = normalizeKey(category, k);
        buffer.writeln(
            "  '$k': ${parseRemWithUnit(v.toString(), category)}, // → $normalized");
      });
      buffer.writeln("};\n");

      // 类
      buffer.writeln("class $className { const $className._();");
      values.forEach((k, v) {
        final normalized = normalizeKey(category, k);
        final safeKey = sanitizeKey(normalized);
        buffer.writeln(
            "  static final $safeKey = ${parseRemWithUnit(v.toString(), category)};");
      });
      buffer.writeln("}\n");
    }
  });

  // ====== 生成 BuildContext 扩展 ======
  buffer.writeln("extension TwContextX on BuildContext {");
  json.forEach((category, values) {
    if (values is Map<String, dynamic>) {
      values.forEach((rawKey, v) {
        final normalized = normalizeKey(category, rawKey);
        final staticField = sanitizeKey(normalized); // 类里的字段
        final mKey = methodKey(category, rawKey); // 方法名用
        final extName = makeContextGetterName(category, mKey);
        final className = "Tw${category[0].toUpperCase()}${category.substring(1)}";
        buffer.writeln("  double get $extName => $className.$staticField;");
      });
    }
  });
  buffer.writeln("}\n");

  writeFileIfChanged(outputFile.path, buffer.toString());
}