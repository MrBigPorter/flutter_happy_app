
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket; // 设为可空，防止未初始化调用

  // 获取当前 socket 实例，如果为空则抛出异常或返回 null
  IO.Socket get socket {
    if (_socket == null) {
      throw Exception("Socket not initialized. Call init() first.");
    }
    return _socket!;
  }

  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSyncNeeded => _syncController.stream;

  ///  1. 全局初始化 (通常在 APP 启动或登录成功后调用)
  void init({required String token}) {
    // 如果已经连着且 Token 没变，就不用重连了
    if (_socket != null && _socket!.connected) return;

    // 清理旧连接
    _socket?.dispose();

    const String socketUrl = 'https://api.yourdomain.com/events';

    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({'token': token}) // 注入 Token
        .build());

    _setupListeners();
    _socket!.connect();
  }

  /// 监听通用事件
  void _setupListeners() {
    _socket!.onConnect((_) {
      debugPrint('✅ [Global Socket] Connected: ${_socket!.id}');
      // 连接成功后触发全局数据同步,全量刷新
      _syncController.add(null);
    });

    _socket!.onDisconnect((_) => debugPrint('❌ [Global Socket] Disconnected'));

    //  监听全局 IM 消息 (比如私信)
    _socket!.on('new_message', (data) {
      // 弹出全局通知 NotificationService.show(...)
    });
  }

  ///  2. 登出时销毁连接
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('👋 [Global Socket] Destroyed');
  }

  // --- 业务房间管理 (只进不出连接，只进出房间) ---

  void joinLobby() {
    if (_socket?.connected == true) {
      _socket!.emit('join_lobby');
    }
  }

  void leaveLobby() {
    if (_socket?.connected == true) {
      _socket!.emit('leave_lobby');
    }
  }

  void dispose() {
    _syncController.close();
    disconnect();
  }
}