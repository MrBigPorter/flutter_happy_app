import 'dart:convert';
import 'package:flutter/material.dart';

/// 1. 所有路由参数类的基类
abstract class BaseRouteArgs {
  Map<String, dynamic> toJson();
  // 自动获取类名作为类型标识
  String get typeName => runtimeType.toString();
}

/// 2. 路由参数注册表
typedef FromJsonFactory<T> = T Function(Map<String, dynamic> json);

class RouteArgsRegistry {
  static final Map<String, FromJsonFactory<Object>> _factories = {};

  /// 注册方法：在 main.dart 或 router 初始化时调用
  static void register<T extends BaseRouteArgs>(String typeName, FromJsonFactory<T> factory) {
    _factories[typeName] = factory;
    debugPrint(" RouteArgs Registered: $typeName");
  }

  static Object? fromJson(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      debugPrint(" RouteArgs Not Found: $typeName. Did you forget to register it?");
      return null;
    }
    return factory(json);
  }
}

/// 3. 通用编解码器 (挂载到 GoRouter)
class CommonExtraCodec extends Codec<Object?, Object?> {
  const CommonExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _CommonDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _CommonEncoder();
}

class _CommonEncoder extends Converter<Object?, Object?> {
  const _CommonEncoder();
  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is BaseRouteArgs) {
      return {
        '__type__': input.typeName,
        ...input.toJson(),
      };
    }
    return input;
  }
}

class _CommonDecoder extends Converter<Object?, Object?> {
  const _CommonDecoder();
  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<String, dynamic>) {
      final typeName = input['__type__'] as String?;
      if (typeName != null) {
        return RouteArgsRegistry.fromJson(typeName, input);
      }
    }
    return input;
  }
}