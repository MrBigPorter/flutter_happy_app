import 'dart:async';

import 'package:flutter_app/utils/events/global_events.dart';

class EventBus {
  // 单例模式
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<GlobalEvent>.broadcast();

  // 发送事件
  void emit(GlobalEvent event) {
    _controller.add(event);
  }

  // 监听事件
  Stream<GlobalEvent> get stream => _controller.stream;
}