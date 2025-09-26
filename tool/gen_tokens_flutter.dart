// tool/gen_tokens_flutter.dart
// 用法：dart run tool/gen_tokens_flutter.dart <input_tokens_json> <output_dir>
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'utils/io_utils.dart';

/// ----------------- JSON 安全读取 -----------------
Map<String, dynamic> _safeJsonDecode(String source) {
  final raw = json.decode(source);
  return Map<String, dynamic>.from(raw as Map);
}

/// ----------------- 颜色工具 -----------------
int _clamp255(num v) => v < 0 ? 0 : (v > 255 ? 255 : v.toInt());

int _parseCssColorToArgb(String s) {
  s = s.trim();
  if (s.startsWith('#')) {
    final hex = s.substring(1);
    if (hex.length == 6) {
      final v = int.parse(hex, radix: 16);
      return 0xFF000000 | v;
    } else if (hex.length == 8) {
      return int.parse(hex, radix: 16);
    }
  }
  final rgba = RegExp(
    r'rgba?\s*\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*(?:,\s*([\d\.]+)\s*)?\)',
  ).firstMatch(s);
  if (rgba != null) {
    final r = double.parse(rgba.group(1)!);
    final g = double.parse(rgba.group(2)!);
    final b = double.parse(rgba.group(3)!);
    final a = rgba.group(4) == null ? 1.0 : double.parse(rgba.group(4)!);
    final ai = _clamp255((a * 255).round());
    return (ai << 24) | (_clamp255(r) << 16) | (_clamp255(g) << 8) | _clamp255(b);
  }
  throw FormatException('Unsupported color format: $s');
}

String _colorLiteralFromArgb(int argb) {
  final hex = argb.toRadixString(16).padLeft(8, '0');
  return 'Color(0x$hex)';
}

/// ----------------- 路径拍平 -----------------
class Leaf {
  final String path;
  final String type;
  final dynamic value;
  Leaf(this.path, this.type, this.value);
}

void _flattenLeaves(String path, Map<String, dynamic> node, List<Leaf> out) {
  if (node.containsKey('value') && node.containsKey('type')) {
    out.add(Leaf(path, node['type'].toString(), node['value']));
    return;
  }
  node.forEach((k, v) {
    if (v is Map) {
      final child = Map<String, dynamic>.from(v);
      final next = path.isEmpty ? k : '$path.$k';
      _flattenLeaves(next, child, out);
    }
  });
}

/// ----------------- 引用解析 -----------------
final _refRe = RegExp(r'^\{(.+)\}$');
String? _asRefPath(String s) => _refRe.firstMatch(s.trim())?.group(1);

Map<String, Leaf> _indexByPath(List<Leaf> leaves) =>
    {for (final l in leaves) l.path: l};

Leaf _lookupRef(String ref, Map<String, Leaf> byPath) {
  final direct = byPath[ref];
  if (direct != null) return direct;

  const prefixes = <String>['_Primitives.', '1.Colormodes.', 'Componentcolors.', 'Components.'];
  for (final pre in prefixes) {
    final alt = byPath['$pre$ref'];
    if (alt != null) return alt;
  }

  final needle = '.$ref';
  final candidates = byPath.entries
      .where((e) => e.key == ref || e.key.endsWith(needle))
      .map((e) => e.value)
      .toList();
  if (candidates.length == 1) return candidates.first;
  if (candidates.isEmpty) {
    throw StateError('Reference not found: {$ref}');
  }
  final sample = candidates.take(5).map((e) => e.path).join(', ');
  throw StateError('Reference {$ref} is ambiguous. Candidates: $sample ...');
}

/// ----------------- 解析颜色 -----------------
class ResolvedColor {
  final int lightArgb;
  final int darkArgb;
  ResolvedColor(this.lightArgb, this.darkArgb);
}

ResolvedColor _resolveColor(dynamic value, Map<String, Leaf> byPath) {
  if (value is String) {
    final ref = _asRefPath(value);
    if (ref == null) {
      final argb = _parseCssColorToArgb(value);
      return ResolvedColor(argb, argb);
    }
    final leaf = _lookupRef(ref, byPath);
    return _resolveColor(leaf.value, byPath);
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final lightV = map['Lightmode'] ?? map['Light mode'] ?? map['light'] ?? map['Light'] ?? map['Value'];
    final darkV  = map['Darkmode']  ?? map['Dark mode']  ?? map['dark']  ?? map['Dark']  ?? lightV;
    final l = _resolveColor(lightV, byPath);
    final d = _resolveColor(darkV, byPath);
    return ResolvedColor(l.lightArgb, d.darkArgb);
  }
  throw StateError('Unsupported color value: $value');
}

/// ----------------- 解析数字 -----------------
double _resolveNumber(dynamic value, Map<String, Leaf> byPath) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final ref = _asRefPath(value);
    if (ref != null) {
      final leaf = _lookupRef(ref, byPath);
      return _resolveNumber(leaf.value, byPath);
    }
    return double.parse(value);
  }
  throw StateError('Unsupported number value: $value');
}

/// ----------------- 命名规则 -----------------
String _toGetterName(String leafName) {
  var s = leafName
      .replaceAll('․', '_')
      .replaceAll('.', ' ')
      .replaceAll('(', ' ')
      .replaceAll(')', ' ')
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .trim();

  if (s.isEmpty) return '';

  // 跳过数字开头的 key
  if (RegExp(r'^\d').hasMatch(s)) {
    return '';
  }

  final parts = s.split(RegExp(r'\s+'));
  var out = '';
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    if (i == 0) {
      out += p[0].toLowerCase() + p.substring(1);
    } else {
      out += p[0].toUpperCase() + p.substring(1);
    }
  }

  return out;
}

/// ----------------- 主流程 -----------------
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/gen_tokens_flutter.dart <input_tokens_json> <output_dir>');
    exit(1);
  }

  final input = File(args[0]);
  final outDir = Directory(args[1]);
  if (!input.existsSync()) {
    stderr.writeln('Input not found: ${input.path}');
    exit(2);
  }
  outDir.createSync(recursive: true);

  final root = _safeJsonDecode(await input.readAsString());
  final leaves = <Leaf>[];
  _flattenLeaves('', root, leaves);
  final byPath = _indexByPath(leaves);

  final colorLeaves = <Leaf>[];
  final numberLeaves = <Leaf>[];

  for (final l in leaves) {
    final t = l.type.toLowerCase();
    final isPrimitiveColor = l.path.startsWith('_Primitives.Colors.');
    if (t == 'color' && !isPrimitiveColor) {
      colorLeaves.add(l);
    } else if (t == 'spacing' || t == 'size' || t == 'borderradius' || t == 'number' || t == 'fontsize') {
      numberLeaves.add(l);
    }
  }

  final buf = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// Source: ${p.basename(input.path)}')
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln("import 'package:flutter_screenutil/flutter_screenutil.dart';")
    ..writeln('');

  buf.writeln('class TokensLight {');
  for (final l in colorLeaves) {
    final getter = _toGetterName(l.path.split('.').last);
    if (getter.isEmpty) continue;
    final res = _resolveColor(l.value, byPath);
    buf.writeln('  static const Color $getter = ${_colorLiteralFromArgb(res.lightArgb)};');
  }
  buf.writeln('}');
  buf.writeln('');

  buf.writeln('class TokensDark {');
  for (final l in colorLeaves) {
    final getter = _toGetterName(l.path.split('.').last);
    if (getter.isEmpty) continue;
    final res = _resolveColor(l.value, byPath);
    buf.writeln('  static const Color $getter = ${_colorLiteralFromArgb(res.darkArgb)};');
  }
  buf.writeln('}');
  buf.writeln('');

  buf.writeln('extension TokensX on BuildContext {');
  buf.writeln('  Brightness get _b => Theme.of(this).brightness;');
  buf.writeln('');

  // 颜色
  for (final l in colorLeaves) {
    final getter = _toGetterName(l.path.split('.').last);
    if (getter.isEmpty) continue;
    buf.writeln('  Color get $getter => _b == Brightness.dark ? TokensDark.$getter : TokensLight.$getter;');
  }
  buf.writeln('');

  // 数字
  for (final l in numberLeaves) {
    final getter = _toGetterName(l.path.split('.').last);
    if (getter.isEmpty) continue;

    final v = _resolveNumber(l.value, byPath);
    final s = v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

    String suffix;
    switch (l.type.toLowerCase()) {
      case 'size':
      case 'spacing':
        suffix = '.w'; // 用宽度缩放
        break;
      case 'borderradius':
        suffix = '.r';
        break;
      case 'fontsize':
        suffix = '.sp';
        break;
      default:
        suffix = '';
    }

    buf.writeln('  double get $getter => $s$suffix;');
  }
  buf.writeln('}');
  buf.writeln('');

  final outPath = p.join(outDir.path, 'design_tokens.g.dart');
  writeFileIfChanged(outPath, buf.toString());
  stdout.writeln('✅ Generated: $outPath');
}