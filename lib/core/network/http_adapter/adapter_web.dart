import 'package:dio/dio.dart';

// Web 端不需要 NativeAdapter，返回 null
HttpClientAdapter? getNativeAdapter() => null;