// tool/gen_token_keys.dart
import 'dart:convert';
import 'dart:io';

import 'utils/io_utils.dart';

void main(List<String> args) {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln('Usage: dart run tool/gen_token_keys.dart <input.json> <output.dart> [ClassName]');
    exit(64);
  }
  final input = args[0];
  final output = args[1];
  final className = args.length == 3 ? args[2] : _classNameFromOut(output);

  final raw = File(input).readAsStringSync();
  final data = json.decode(raw);

  final tokens = <String>{};
  _collectTokens(data, tokens);

  final sorted = tokens.toList()..sort();

  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln('class $className {')
    ..writeln('  const $className._();')
    ..writeln('  static const all = <String>[');
  for (final k in sorted) {
    buf.writeln("    '$k',");
  }
  buf
    ..writeln('  ];')
    ..writeln();

  for (final k in sorted) {
    // 生成合法的 Dart 标识符（尽量保留原名，非字母数字转下划线）
    final id = _toIdentifier(k);
    buf.writeln("  static const String $id = '$k';");
  }
  buf.writeln('}');

  //File(output).writeAsStringSync(buf.toString());
  //stdout.writeln('✅ Wrote ${sorted.length} tokens to $output');
  writeFileIfChanged(output, buf.toString());
}

String _classNameFromOut(String out) {
  final base = out.split('/').last;
  if (base.toLowerCase().contains('light')) return 'TwLightTokens';
  if (base.toLowerCase().contains('dark')) return 'TwDarkTokens';
  return 'TwTokens';
}

String _toIdentifier(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  var id = cleaned;
  if (RegExp(r'^[0-9]').hasMatch(id)) id = '_$id';
  return id;
}

void _collectTokens(dynamic node, Set<String> out, {List<String> path = const []}) {
  if (node is Map) {
    // 跳过 metadata
    if (node.containsKey(r'$metadata')) {
      final m = Map<String, dynamic>.from(node);
      m.remove(r'$metadata');
      _collectTokens(m, out, path: path);
      return;
    }

    // 如果只有一个顶级集合（如 core/light/dark），直接下钻，不把集合名带进键名
    if (path.isEmpty && node.length == 1 && node.values.first is Map) {
      final k = node.keys.first.toString().toLowerCase();
      if (k == 'core' || k == 'light' || k == 'dark' || k == 'tokens') {
        _collectTokens(node.values.first, out, path: const []);
        return;
      }
    }

    node.forEach((key, value) {
      // 兼容 Figma Tokens：{ key: { value: "#fff" } }
      if (value is Map && value.containsKey('value')) {
        // 这里 key 就是实际 token 名
        out.add(key.toString());
        // 同时继续递归，避免漏掉更深的值
        _collectTokens(value, out, path: [...path, key.toString()]);
      } else if (value is String) {
        // 平铺 JSON：{ key: "#fff" }
        if (path.isEmpty) {
          out.add(key.toString());
        } else {
          out.add([...path, key.toString()].join('_'));
        }
      } else {
        _collectTokens(value, out, path: [...path, key.toString()]);
      }
    });
    return;
  }
  // 其它类型忽略
}