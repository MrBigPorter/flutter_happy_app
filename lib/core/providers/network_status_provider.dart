import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

// 简单的 StreamProvider，监听手机的物理网络连接
final networkStatusProvider = StreamProvider.autoDispose<NetworkStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // 只要结果里包含 none，或者列表为空，就算断网
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  });
});
