import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider? tryBuildFileImageProviderImpl(String source) {
  if (source.isEmpty) return null;

  // 1. 提取标准化路径
  String path = source;
  if (source.startsWith('file://')) {
    try {
      path = Uri.parse(source).toFilePath();
    } catch (e) {
      return null; // URI 格式非法
    }
  }

  // 2. 核心优化：物理检查
  // 只有路径以 / 开头（绝对路径）且文件确实存在时，才返回 FileImage
  if (path.startsWith('/')) {
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
  }

  // 如果文件不存在，返回 null，让上层逻辑（_getHighResProvider）
  // 能够立刻切换到 NetworkImage 或 CachedNetworkImageProvider
  return null;
}