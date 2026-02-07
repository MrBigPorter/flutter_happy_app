// lib/utils/image_provider_utils_stub.dart
import 'package:flutter/material.dart';

ImageProvider? tryBuildFileImageProviderImpl(String source) {
  //  CHANGED: Web 下不支持 FileImage，直接返回 null
  return null;
}