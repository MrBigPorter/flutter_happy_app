// lib/token_theme.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 把 Figma Tokens（单文件）解析成 Flutter 的 ThemeExtension，支持 light/dark 与引用 {foo.bar}
class TokenTheme extends ThemeExtension<TokenTheme> {
  final Map<String, Color> colors;
  const TokenTheme({required this.colors});

  Color? color(String name) => colors[name];

  @override
  TokenTheme copyWith({Map<String, Color>? colors}) =>
      TokenTheme(colors: colors ?? this.colors);

  @override
  ThemeExtension<TokenTheme> lerp(ThemeExtension<TokenTheme>? other, double t) {
    if (other is! TokenTheme) return this;
    return t < 0.5 ? this : other;
  }

  /// 从 assets 加载（文件中可同时包含 light/dark）
  static Future<TokenTheme> fromAsset(String assetPath, {bool dark = false}) async {
    final raw = await rootBundle.loadString(assetPath);
    return fromSource(raw, dark: dark);
  }

  /// 从字符串加载（允许 JSON with comments、允许多个对象拼在一起）
  static TokenTheme fromSource(String source, {bool dark = false}) {
    String cleaned = _stripComments(source);
    cleaned = _removeTrailingCommas(cleaned);
    final objects = _extractTopLevelJsonObjects(cleaned);

    Map<String, dynamic> merged = {};
    for (final obj in objects) {
      final map = json.decode(obj) as Map<String, dynamic>;
      merged = _deepMerge(merged, map);
    }

    final resolver = _FigmaResolver(merged, dark: dark);
    final colors = resolver.buildFlatColorMap();
    return TokenTheme(colors: colors);
  }
}

// ---------- helpers ----------
String _stripComments(String s) {
  final block = RegExp(r"/\*[\s\S]*?\*/");
  final line  = RegExp(r"(^|\n)\s*//.*?(?=\n|\Z)");
  return s.replaceAll(block, '').replaceAllMapped(line, (m) => m.group(1) ?? '');
}
String _removeTrailingCommas(String s) =>
    s.replaceAll(RegExp(r",\s*(?=[}\]])"), "");

List<String> _extractTopLevelJsonObjects(String s) {
  final list = <String>[];
  int depth = 0; int start = -1; bool inStr = false; bool esc = false;
  for (int i = 0; i < s.length; i++) {
    final ch = s[i];
    if (inStr) {
      if (esc) { esc = false; }
      else if (ch == "\\") { esc = true; }
      else if (ch == '"') { inStr = false; }
      continue;
    }
    if (ch == '"') { inStr = true; continue; }
    if (ch == '{') { if (depth == 0) start = i; depth++; }
    else if (ch == '}') {
      depth--;
      if (depth == 0 && start >= 0) { list.add(s.substring(start, i+1)); start = -1; }
    }
  }
  if (list.isEmpty && s.trim().startsWith('{')) list.add(s.trim());
  return list;
}

Map<String, dynamic> _deepMerge(Map<String, dynamic> a, Map<String, dynamic> b) {
  final out = <String, dynamic>{}..addAll(a);
  b.forEach((k, v) {
    if (out[k] is Map && v is Map) {
      out[k] = _deepMerge(out[k] as Map<String, dynamic>, v as Map<String, dynamic>);
    } else {
      out[k] = v;
    }
  });
  return out;
}

Color _parseHex(String v) {
  var hex = v.replaceAll('#', '').trim();
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}
Color _parseRgb(String v) {
  final inner = v.substring(v.indexOf('(')+1, v.lastIndexOf(')'));
  final p = inner.split(',').map((e) => e.trim()).toList();
  final r = int.parse(p[0]), g = int.parse(p[1]), b = int.parse(p[2]);
  return Color.fromARGB(255, r, g, b);
}
Color _parseRgba(String v) {
  final inner = v.substring(v.indexOf('(')+1, v.lastIndexOf(')'));
  final p = inner.split(',').map((e) => e.trim()).toList();
  final r = int.parse(p[0]), g = int.parse(p[1]), b = int.parse(p[2]);
  final a = double.parse(p[3]);
  return Color.fromARGB((a*255).round().clamp(0, 255), r, g, b);
}
Color _toColor(dynamic value) {
  if (value is String) {
    final v = value.trim();
    if (v.startsWith('#')) return _parseHex(v);
    if (v.startsWith('rgba')) return _parseRgba(v);
    if (v.startsWith('rgb'))  return _parseRgb(v);
  }
  return const Color(0xFF000000);
}
String _slug(String s) => s.toLowerCase()
    .replaceAll(RegExp(r"[()\.]"), '')
    .replaceAll(RegExp(r"\s+"), '_')
    .replaceAll('-', '_');

class _FigmaResolver {
  final Map<String, dynamic> root;
  final bool dark;
  _FigmaResolver(this.root, {required this.dark});

  /// 构建拍平后的颜色表。会优先按你的“Colors / Component colors”结构提取；
  /// 如果没有这些结构，则回退为“泛化递归提取”，尽量把所有叶子颜色都收集出来。
  Map<String, Color> buildFlatColorMap() {
    final out = <String, Color>{};

    // 兼容大小写键名
    Map<String, dynamic> section(String a, String b) {
      final m = <String, dynamic>{};
      final v = (root[a] ?? root[b]);
      if (v is Map) m.addAll(v.cast<String, dynamic>());
      return m;
    }

    final colors = section('Colors', 'colors');
    if (colors.isNotEmpty) _walkColors(colors, out);

    final comp = section('Component colors', 'component colors');
    if (comp.isNotEmpty) _walkComponentColors(comp, out);

    // 回退：如果以上都为空，或你还希望抓取色板（如 brand/gray 500…），做一次全量递归
    if (out.isEmpty) {
      _collectAllColors(root, out);
    }

    return out;
  }

  // ======== 按常用分组提取（与你之前的 key 命名保持一致） ========
  void _walkColors(Map<String, dynamic> colors, Map<String, Color> out) {
    final text = (colors['Text'] ?? colors['text']) as Map?;
    text?.cast<String, dynamic>().forEach((k, v) {
      out['colors_text_${_normalizeTextKey(k)}'] = _resolveColorValue(v);
    });

    final border = (colors['Border'] ?? colors['border']) as Map?;
    border?.cast<String, dynamic>().forEach((k, v) {
      out['colors_border_${_normalizeGenericKey(k)}'] = _resolveColorValue(v);
    });

    final fg = (colors['Foreground'] ?? colors['foreground']) as Map?;
    fg?.cast<String, dynamic>().forEach((k, v) {
      out['colors_foreground_${_normalizeFgKey(k)}'] = _resolveColorValue(v);
    });

    final bg = (colors['Background'] ?? colors['background']) as Map?;
    bg?.cast<String, dynamic>().forEach((k, v) {
      out['colors_background_${_normalizeBgKey(k)}'] = _resolveColorValue(v);
    });

    final effects = (colors['Effects'] ?? colors['effects']) as Map?;
    final rings = (effects?['Focus rings'] ?? effects?['focus rings']) as Map?;
    rings?.cast<String, dynamic>().forEach((k, v) {
      out['colors_effects_focusrings_${_slug(k)}'] = _resolveColorValue(v);
    });
    final shadows = (effects?['Shadows'] ?? effects?['shadows']) as Map?;
    shadows?.cast<String, dynamic>().forEach((k, v) {
      out['colors_effects_shadows_${_slug(k)}'] = _resolveColorValue(v);
    });
  }

  void _walkComponentColors(Map<String, dynamic> comp, Map<String, Color> out) {
    final alpha = (comp['Alpha'] ?? comp['alpha']) as Map?;
    alpha?.cast<String, dynamic>().forEach((k, v) {
      out['componentcolors_alpha_${_slug(k)}'] = _resolveColorValue(v);
    });

    final util = (comp['Utility'] ?? comp['utility']) as Map?;
    util?.cast<String, dynamic>().forEach((groupName, groupVal) {
      if (groupVal is Map<String, dynamic>) {
        groupVal.forEach((k, v) {
          out['componentcolors_utility_${_slug(groupName)}_${_slug(k)}'] = _resolveColorValue(v);
        });
      }
    });
  }

  // ======== 回退：抓取所有叶子颜色（把路径拼成 key） ========
  void _collectAllColors(dynamic node, Map<String, Color> out,
      {List<String> path = const []}) {
    if (node is Map<String, dynamic>) {
      // Figma Tokens 常见结构：{ "value": <...> }
      if (node.containsKey('value')) {
        final c = _resolveColorValue(node);
        final key = path.map(_slug).join('_');
        if (key.isNotEmpty) out[key] = c;
        return;
      }
      // mode 值：{ light: "#fff", dark: "#000" }
      if (node.containsKey('light') || node.containsKey('dark')) {
        final pick = _pickModeValue(node);
        final key = path.map(_slug).join('_');
        if (key.isNotEmpty) out[key] = _toColor(pick);
        return;
      }
      node.forEach((k, v) {
        _collectAllColors(v, out, path: [...path, k]);
      });
      return;
    }
    if (node is String) {
      final key = path.map(_slug).join('_');
      if (key.isNotEmpty) out[key] = _toColor(node);
    }
  }

  // ======== key 规范化（与你之前的一致） ========
  String _normalizeTextKey(String raw) =>
      _slug(raw.replaceAll('text-', 'text_')).replaceAll('_900', '900');
  String _normalizeFgKey(String raw)   =>
      _slug(raw.replaceAll('fg-'  , 'fg_'  )).replaceAll('_900', '900');
  String _normalizeBgKey(String raw)   =>
      _slug(raw.replaceAll('bg-'  , 'bg_'  ));
  String _normalizeGenericKey(String raw) => _slug(raw);

  // ======== 解析颜色值 / 引用 / 模式 ========
  Color _resolveColorValue(dynamic node) {
    // node 既可能是 {"value": ...} 也可能是直接字符串，或 {light/dark}
    if (node is Map<String, dynamic>) {
      // 先处理 mode 值
      if (node.containsKey('light') || node.containsKey('dark')) {
        return _toColor(_pickModeValue(node));
      }
      final value = node['value'];
      if (value is Map) {
        // value 本身是 mode 对象
        return _toColor(_pickModeValue(value.cast<String, dynamic>()));
      }
      if (value is String) {
        final v = value.trim();
        if (v.startsWith('{') && v.endsWith('}')) {
          final ref = v.substring(1, v.length - 1);
          final refVal = _lookupRef(ref);
          return _toColor(refVal);
        }
        return _toColor(v);
      }
      if (value != null) return _toColor(value.toString());
    }
    if (node is String) {
      final v = node.trim();
      if (v.startsWith('{') && v.endsWith('}')) {
        final ref = v.substring(1, v.length - 1);
        final refVal = _lookupRef(ref);
        return _toColor(refVal);
      }
      return _toColor(v);
    }
    return const Color(0xFF000000);
  }

  dynamic _pickModeValue(Map<String, dynamic> m) {
    // 兼容大小写
    final light = m['light'] ?? m['Light'];
    final darkV = m['dark']  ?? m['Dark'];
    return dark ? (darkV ?? light) : (light ?? darkV);
  }

  /// 解析 {a.b.c} 引用（大小写不敏感），若指到对象则取其 value
  dynamic _lookupRef(String ref) {
    final parts = ref.split('.');
    dynamic cur = root;
    for (final p in parts) {
      if (cur is Map<String, dynamic>) {
        if (cur.containsKey(p)) { cur = cur[p]; continue; }
        // 大小写不敏感匹配
        final hit = cur.keys.firstWhere(
              (k) => k.toString().toLowerCase() == p.toLowerCase(),
          orElse: () => '',
        );
        if (hit != '') { cur = cur[hit]; continue; }
        break;
      }
    }
    if (cur is Map<String, dynamic>) return cur['value'] ?? cur;
    return cur;
  }
}

// 语法糖：context.figmaTokens
extension FigmaTokenX on BuildContext {
  TokenTheme? get figmaTokens => Theme.of(this).extension<TokenTheme>();
}