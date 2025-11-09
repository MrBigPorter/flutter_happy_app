import 'dart:async';

import 'package:flutter/cupertino.dart';

class Countdown {
  final ValueNotifier<int> seconds = ValueNotifier<int>(0);
  bool get running => _timer != null;

  DateTime? _target;
  Timer? _timer;

  // Start a countdown for the given duration in seconds
  void start(int duration) {
    startUntil(DateTime.now().add(Duration(seconds: duration)));
  }

  // start countdown until the target DateTime
  void startUntil(DateTime target) {
    _target = target;
    _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_)=> _tick());
  }

  void _tick(){
    if(_target == null) return;
    final remain = _target!.difference(DateTime.now()).inSeconds;
    if(remain <= 0){
      seconds.value = 0;
      stop();
    }else{
      seconds.value = remain;
    }

  }

  void dispose(){
    stop();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _target = null;
    seconds.value = 0;
  }
}