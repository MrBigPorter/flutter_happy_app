// tool/gen_token_alias.dart
import 'dart:convert';
import 'dart:io';

import 'utils/io_utils.dart';

/// 将 token key 转换为更简短的 Dart getter 名
String _toGetterName(String key) {
  // 例子: colors_background_bg_primary -> bgPrimary
  final parts = key.split('_');
  if (parts.isEmpty) return key;

  // 去掉前缀（如 colors, componentcolors）
  final filtered = parts.skipWhile((p) =>
  p == 'colors' ||
      p == 'componentcolors' ||
      p == 'buttons');

  // 转换成 camelCase
  final camel = filtered.mapIndexed((i, part) {
    if (i == 0) return part;
    return part[0].toUpperCase() + part.substring(1);
  }).join();

  return camel;
}

extension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}

void main(List<String> args) async {
  if (args.length < 2) {
    stdout.writeln('用法: dart run tool/gen_token_alias.dart');
    exit(1);
  }

  final input = File(args[0]);
  final output = File(args[1]);

  final jsonData = json.decode(await input.readAsString()) as Map<String, dynamic>;

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ignore_for_file: unnecessary_this');
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'token_theme.dart';");
  buffer.writeln('');
  buffer.writeln('extension TokenAlias on BuildContext {');

  for (final entry in jsonData.entries) {
    final key = entry.key;
    final getter = _toGetterName(key);

    buffer.writeln('  Color? get $getter => figmaTokens?.color("$key");');
  }

  buffer.writeln('}');

  writeFileIfChanged(output.path, buffer.toString());
  //await output.writeAsString(buffer.toString());
  //print('✅ 生成完成: ${output.path}');
}