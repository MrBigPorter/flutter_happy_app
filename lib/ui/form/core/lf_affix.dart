import 'package:flutter/material.dart';

/// 将 prefix/suffix 转换为 prefixIcon/suffixIcon 以便更好地对齐
/// 仅在未设置 prefixIcon/suffixIcon 时转换
/// only convert when prefixIcon/suffixIcon is not set
InputDecoration normalizeAffixes(InputDecoration deco) {
  final pad = deco.contentPadding;
  final EdgeInsets edge = pad is EdgeInsets
      ? pad
      : const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

  var out = deco;


  if (deco.prefix != null && deco.prefixIcon == null) {
    out = out.copyWith(
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: edge.left),
        child: Center(child: deco.prefix!),
      ),
      // 仅在未设置时提供紧凑约束
      prefixIconConstraints:
      deco.prefixIconConstraints ?? const BoxConstraints(minWidth: 0, minHeight: 0),
      prefix: null, // 避免重复
    );
  }

  if (deco.suffix != null && deco.suffixIcon == null) {
    out = out.copyWith(
      suffixIcon: Padding(
        padding: EdgeInsets.only(right: edge.right),
        child: Center(child: deco.suffix!),
      ),
      suffixIconConstraints:
      deco.suffixIconConstraints ?? const BoxConstraints(minWidth: 0, minHeight: 0),
      suffix: null,
    );
  }

  return out;
}