import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheForExtension on Ref{
  void cacheFor(Duration duration){
    final link = keepAlive();
    Timer? timer;

    onDispose((){
      timer?.cancel();
    });

    // 当最后一个监听器移除时，开始倒计时
    onCancel((){
      timer = Timer(duration, (){
        link.close();
      });
    });
    // 如果在 60 秒内用户又回来了，取消倒计时，继续保活
    onResume((){
      timer?.cancel();
    });

  }
}