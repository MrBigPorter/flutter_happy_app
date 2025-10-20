import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';

/// Animation Sync Manager
/// used to sync multiple animations
/// for example, play all animations or reset all animations
/// singleton class
/// use StreamController to broadcast events
/// playAll() to play all animations
/// resetAll() to reset all animations
/// animations can listen to the stream and react accordingly
/// true means play, false means reset
/// example:
/// AnimationSyncManager.instance.stream.listen((play) {
///  if (play) {
///  // play animation
///  } else {
///  // reset animation
///  }
/// });
/// note: remember to cancel the subscription when not needed
/// for example, in dispose() method
/// _subscription.cancel();
/// also, make sure to import 'dart:async';
/// this class is a singleton, so use AnimationSyncManager.instance to access it
/// no need to create multiple instances
/// this class is thread-safe
/// you can call playAll() and resetAll() from any thread
/// the stream will handle the synchronization
class AnimationSyncManager {
  // private constructor
  AnimationSyncManager._();
  // singleton instance
  static final AnimationSyncManager instance = AnimationSyncManager._();

  // broadcast stream controller
  final StreamController<bool> _controller = StreamController.broadcast();

  Stream<bool> get stream => _controller.stream;

  void playAll() => _controller.add(true);
  void resetAll() => _controller.add(false);
}

/// Page Motion Direction
/// used to manage multiple animation controllers
/// for example, play all animations or reset all animations
/// singleton class
/// use register() to register an animation controller
/// use play() to play all registered animations
/// use reset() to reset all registered animations
/// use unregister() to unregister an animation controller
/// use disposeAll() to dispose all registered animations
/// example:
/// PageMotionDirection.instance.register(controller);
/// PageMotionDirection.instance.play();
/// PageMotionDirection.instance.reset();
/// PageMotionDirection.instance.unregister(controller);
/// PageMotionDirection.instance.disposeAll();
/// note: remember to unregister the controller when not needed
/// for example, in dispose() method
/// PageMotionDirection.instance.unregister(controller);
/// also, make sure to import 'package:flutter/animation.dart';
class PageMotionDirection {
  // private constructor
  PageMotionDirection._();
  // singleton instance
  static final instance = PageMotionDirection._();

  final List<AnimationController> _controllers = [];

  void register(AnimationController ctl){
    if(!_controllers.contains(ctl)){
      _controllers.add(ctl);
    }
  }

  void play(){
    for(final ctl in _controllers){
      ctl.forward();
    }
  }

  void reset(){
    for(final ctl in _controllers){
      ctl.reset();
    }
  }

  void unregister(AnimationController ctl) => _controllers.remove(ctl);

  void disposeAll(){
    for(final ctl in _controllers){
      ctl.dispose();
    }
    _controllers.clear();
  }

}

/// Scroll Speed Tracker
/// used to track scroll speed in pixels per second
/// singleton class
/// use update(newPixels) to update the scroll position
/// use speed getter to get the current scroll speed
/// example:
/// ScrollSpeedTracker.instance.update(newPixels);
/// double currentSpeed = ScrollSpeedTracker.instance.speed;
/// note: remember to import 'package:flutter/foundation.dart';
/// this class extends ChangeNotifier, so you can listen to changes
/// for example, using a ChangeNotifierProvider in Riverpod or Provider package
/// you can also use addListener() method to listen to changes
/// ScrollSpeedTracker.instance.addListener(() {
///   double currentSpeed = ScrollSpeedTracker.instance.speed;
///   // do something with currentSpeed
class ScrollSpeedTracker extends ChangeNotifier {
  // singleton instance
  static final instance = ScrollSpeedTracker._();
  // private constructor
  ScrollSpeedTracker._();

  double _lastPixels = 0;
  DateTime _latestTime = DateTime.now();
  double _speed = 0; // pixels per millisecond

  double get speed => _speed;

  void update(double newPixels){
    final now = DateTime.now();
    final dt = now.difference(_latestTime).inMilliseconds / 1000.0;

    if(dt > 0){
      // calculate speed, pixels per second, absolute value
      //speed = (当前位置 - 上一位置) / 时间差
      //在连续两帧之间记录
      _speed = ((newPixels - _lastPixels).abs() / dt);
      // update last values
      _lastPixels = newPixels;
      _latestTime = now;
      notifyListeners();
    }
  }
}

/// Scroll Direction Tracker
/// used to track scroll direction (up or down)
/// singleton class
/// use update(newPixels) to update the scroll position
/// use direction getter to get the current scroll direction
/// example:
/// ScrollDirectionTracker.instance.update(newPixels);
/// ScrollDirection dir = ScrollDirectionTracker.instance.direction;
/// note: remember to import 'package:flutter/foundation.dart';
/// this class extends ChangeNotifier, so you can listen to changes
/// for example, using a ChangeNotifierProvider in Riverpod or Provider package
/// you can also use addListener() method to listen to changes
/// ScrollDirectionTracker.instance.addListener(() {
///   ScrollDirection dir = ScrollDirectionTracker.instance.direction;
///   // do something with dir
enum ScrollDirection {
  up,
  down,
}

class ScrollDirectionTracker extends ChangeNotifier {
  // singleton instance
  static final instance = ScrollDirectionTracker._();
  // private constructor
  ScrollDirectionTracker._();

  double _lastPixels = 0;
  ScrollDirection _direction = ScrollDirection.down;
  //  缓冲距离累计 buffer distance accumulation
  double _bufferDistance = 0.0;
  //  阈值，超过该值才改变方向 threshold, only change direction if exceeded
  static const double _threshold = 60.0;

  ScrollDirection get direction => _direction;

  void update(double newPixels){
    final delta = newPixels - _lastPixels;
    print("ScrollDirectionTracker update: delta=$delta");
    final newDirection = delta > 0 ? ScrollDirection.down : ScrollDirection.up;
    // direction changed
    if(newDirection != _direction){
      // accumulate buffer distance
      _bufferDistance += delta.abs();

      // 超过阈值才改变方向 Only change direction if exceeded threshold
      if(_bufferDistance >= _threshold){
        // change direction
        _direction = newDirection;
        _bufferDistance = 0.0;
        notifyListeners();
      }else{
        // 如果方向一致，则清零缓冲 If direction is consistent, reset buffer
        _bufferDistance = 0;
      }
    }
    _lastPixels = newPixels;
  }
}