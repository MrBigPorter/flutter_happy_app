// tool/gen_tw_hints.dart
import 'dart:convert';
import 'dart:io';

import 'utils/io_utils.dart';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('Usage: dart run tool/gen_tw_hints.dart <light.json> <dark.json> <output.dart>');
    exit(64);
  }
  final light = json.decode(File(args[0]).readAsStringSync());
  final dark  = json.decode(File(args[1]).readAsStringSync());
  final out   = args[2];

  final set = <String>{};
  _collectTokens(light, set);
  _collectTokens(dark, set);

  final list = set.toList()..sort();

  final sb = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln('class TwHints {')
    ..writeln('  const TwHints._();')
    ..writeln('  static const all = <String>[');
  for (final k in list) {
    sb.writeln("    '$k',");
  }
  sb.writeln('  ];');

  for (final k in list) {
    final id = _toIdentifier(k);
    sb.writeln("  static const String $id = '$k';");
  }
  sb.writeln('}');
  writeFileIfChanged(out, sb.toString());
  //File(out).writeAsStringSync(sb.toString());
  //stdout.writeln('✅ Wrote ${list.length} tokens to $out');
}

String _toIdentifier(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  var id = cleaned;
  if (RegExp(r'^[0-9]').hasMatch(id)) id = '_$id';
  return id;
}

void _collectTokens(dynamic node, Set<String> out, {List<String> path = const []}) {
  if (node is Map) {
    if (node.containsKey(r'$metadata')) {
      final m = Map<String, dynamic>.from(node);
      m.remove(r'$metadata');
      _collectTokens(m, out, path: path);
      return;
    }
    if (path.isEmpty && node.length == 1 && node.values.first is Map) {
      final k = node.keys.first.toString().toLowerCase();
      if (k == 'core' || k == 'light' || k == 'dark' || k == 'tokens') {
        _collectTokens(node.values.first, out, path: const []);
        return;
      }
    }

    node.forEach((key, value) {
      if (value is Map && value.containsKey('value')) {
        out.add(key.toString());
      } else if (value is String) {
        if (path.isEmpty) {
          out.add(key.toString());
        } else {
          out.add([...path, key.toString()].join('_'));
        }
      }
      _collectTokens(value, out, path: [...path, key.toString()]);
    });
  }
}