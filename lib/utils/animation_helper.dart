import 'dart:async';

import 'package:flutter/animation.dart';

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