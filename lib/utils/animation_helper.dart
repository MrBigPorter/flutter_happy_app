import 'dart:async';
import 'dart:math' as math;

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


  //当前滚动速度 100 => 200 => 300
  double speed = 0; // pixels per millisecond
  // 加速度 500 => 700 => 900 =  200 200 200
  // 900 600 400 100 = -300 -200 -300
  // 当前加速度（速度变化趋势）
  double accel = 0; // pixels per millisecond squared

  double _lastPixels = 0.0;
  double _lastSpeed = 0.0;
   int _lastTime = DateTime.now().millisecondsSinceEpoch;

  int get direction{
    if(speed > 0.5) return 1; // down go to the bottom
    if(speed < -0.5) return -1; // up go to the top
    return 0; // stationary
  }


  void update(ScrollNotification n){
      final now = DateTime.now().millisecondsSinceEpoch;
      final dt = (now - _lastTime).clamp(1, 1000); // in milliseconds
     _lastTime = now;

     final double delta = n.metrics.pixels - _lastPixels;
     _lastPixels = n.metrics.pixels;

     //  没有滚动或者就1px 比如 10=》1.01
     if(delta.abs() < 0.1){
       // 惯性结束后让速度缓慢归零（防止残留）
       if(speed.abs() > 0.1){
         speed *= 0.9; // friction
         notifyListeners();
       }
       return;
     }

     //计算真实速度 pixels per millisecond
     final newSpeed = delta / dt; // pixels per millisecond
      //计算加速度 pixels per millisecond squared
      accel = (newSpeed - _lastSpeed) / dt; // pixels per millisecond
      _lastSpeed = newSpeed;

      // notify only if speed changed significantly
      speed = newSpeed;

      notifyListeners();
  }

  /// 手动重置（切换页面或重载列表时用）
  void reset(){
    speed = 0;
    accel = 0;
    _lastPixels = 0.0;
    _lastSpeed = 0.0;
    _lastTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
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

/// Velocity Wave Delay
/// 根据滚动速度和索引计算动画延迟时间
/// 速度越快，延迟越小
/// 延迟随索引呈波动变化，观感更自然
/// 可选抖动避免同步
/// example:
/// int delayMs = VelocityWaveDelay.compute(
///  index: itemIndex,
///  baseMs: 50,
///  speed: scrollSpeed,
///  speedNorm: 1000.0,
///  waveDivisor: 2.0,
///  waveAmp: 0.5,
///  waveBias: 0.5,
///  jitterMs: 10.0,
///  );
///  note: remember to import 'dart:math' as math;
class VelocityWaveDelay {
  static int compute({
    required int index,
    required int baseMs,
    required double speed,

    // 速度归一化分母（≈多快算“很快”）
    double speedNorm = 1000.0,
    // 波密度：越大越平缓
    double waveDivisor = 2.0,
    // 波幅：0~1，越大起伏越明显
    double waveAmp = 0.5,
    // 波偏置：通常保持 0.5，让结果落在 0~1
    double waveBias = 0.5,
    // 可选：给每个 item 加一点确定性抖动，避免同步
    double jitterMs = 0.0,
}){
    // 速度越大 → 延迟越小
    //// 归一化速度 normalized speed
    final s = ( speed.abs() / speedNorm).clamp(0.0, 1.0);
    final delayFactor = 1.0 - s; // 速度越大，延迟因子越小

    // 波动影响 wave effect
    //// 正弦波：让延迟随 index 起伏，观感更自然
    final waveFactor = (math.sin(index / waveDivisor) * waveAmp + waveBias).clamp(0.0, 1.0);
    // 基础延迟 × 速度缩放 × 波形扰动
    final base = index * baseMs * delayFactor * waveFactor;

    final jitter = jitterMs == 0.0
        ? 0.0
        : ((index * 13) % 7) / 6.0 * jitterMs;

    final ms = base + jitter;
    return ms.isFinite ? ms.round() : 0;

  }
}