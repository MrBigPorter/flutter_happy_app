import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider? tryBuildFileImageProviderImpl(String source) {
  // 本地文件直接读
  if (source.startsWith('/') || source.startsWith('file://')) {
    final path = source.startsWith('file://')
        ? Uri.parse(source).toFilePath()
        : source;
    return FileImage(File(path));
  }
  return null;
}