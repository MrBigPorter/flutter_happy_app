import 'package:dio/dio.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart'; // 只有这里引用这个包

// 移动端返回真实实例
HttpClientAdapter? getNativeAdapter() => NativeAdapter();