import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/utils/animation_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final bool fade, slide, scale;
  final double beginOffsetY, beginScale;
  final Curve curve, scaleCurve;
  final bool playWhenVisible;
  final bool fadeOutWhenLeave;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 400),
    this.fade = true,
    this.slide = true,
    this.scale = true,
    this.beginOffsetY = 20.0,
    this.beginScale = 0.9,
    this.curve = Curves.easeOutCubic,
    this.scaleCurve = Curves.elasticOut,
    this.playWhenVisible = true,
    this.fadeOutWhenLeave = false,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _offsetAnimation;
  late Animation<double> _scaleAnimation;

  // cached played keys
  static final Set<String> _playedKeys = {};

  // already played animation
  bool _played = false;
  // unique id for this item
  late final String _id;

  late final StreamSubscription<bool> _syncSub;


  @override
  void initState() {
    super.initState();

    _id = 'animated-list-item-${widget.index}-${widget.key ?? UniqueKey()}';

    // 获取滚动速度 // get scroll speed
    final speed = ScrollSpeedTracker.instance.speed;
    final dir =  ScrollSpeedTracker.instance.direction;
    final accel = ScrollSpeedTracker.instance.accel;

    //  速度越快 → 位移越小 // the faster the speed, the smaller the offset
    // -1 ≤ dir ≤ 1
     final offsetY = widget.beginOffsetY * dir;
     final duration = speed.abs() > 0.5 ? const Duration(milliseconds: 200) : const Duration(milliseconds: 400);

     final curve = accel < 0 ? Curves.easeOutCubic : Curves.easeInOut;

    // 创建节拍
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );



    _syncSub = AnimationSyncManager.instance.stream.listen((play){
      if(play){
        _tryPlay();
      }else{
        if(mounted){
          try {
            _controller.reset();
            _played = false;
            _playedKeys.remove(_id);
          }catch(_){}
        }
      }
    });
    PageMotionDirection.instance.register(_controller);

    // already played before, set to end state
    if(_playedKeys.contains(_id)){
      _controller.value = 1.0;
      _played = true;
    }

    // 定义透明度动画 0 => 1
    _opacityAnimation = Tween(
      begin: widget.fade ? 0.05 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    // 定义位移动画 20 => 0
    _offsetAnimation = Tween(
      begin: widget.slide ? offsetY : 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    // 定义缩放动画 0.95 => 1.0
    _scaleAnimation = Tween(
      begin: widget.scale ? widget.beginScale : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    if (!widget.playWhenVisible) {
      // 如果有延迟，设置定时器启动动画 if there's a delay, set a timer to start the animation

      final delayMs = VelocityWaveDelay.compute(index: widget.index, baseMs: widget.delayPerItem.inMilliseconds, speed: ScrollSpeedTracker.instance.speed);

      Future.delayed(
        Duration(
          milliseconds: delayMs,
        ),
        _tryPlay,
      );
    }else{
      WidgetsBinding.instance.addPostFrameCallback((_) {
       final renderBox = context.findRenderObject() as RenderBox?;
       // first check if the widget is already visible on screen
       // avoid empty  page not playing animation issue
       if(renderBox != null && renderBox.hasSize){
         final size = renderBox.size;
         final pos = renderBox.localToGlobal(Offset.zero);
         final screenHeight = MediaQuery.of(context).size.height;
         final visible = pos.dy < screenHeight && pos.dy + size.height > 0;
         if(visible) {
           _tryPlay();
         }
       }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    VisibilityDetectorController.instance.forget(Key(_id));
    PageMotionDirection.instance.unregister(_controller);
    _syncSub.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryPlay();
  }

  // map speed to factor between 0.0 and 1.0
  double mapSpeedToFactor(double speed){
    const double minSpeed = 0.0;
    // if speed >= maxSpeed, return 0.0
    const double maxSpeed = 20000.0;
    double x = (1.0 - (speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);
    // use easeInCubic for better effect
    return (1.0 - Curves.easeInCubic.transform(x));
  }

  // try to play the animation
  void _tryPlay() {
    if (_played) return;
    _played = true;
    _playedKeys.add(_id);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final content =  AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget w = child!;
        if (widget.scale) {
          w = Transform.scale(scale: _scaleAnimation.value, child: w);
        }
        if (widget.slide) {
          w = Transform.translate(
            offset: Offset(0, _offsetAnimation.value),
            child: w,
          );
        }
        if (widget.fade) {
          w = Opacity(opacity: _opacityAnimation.value, child: w);
        }
        return w;
      },
      child: widget.child,
    );

    return widget.playWhenVisible ? VisibilityDetector(
        key: ValueKey('list-item-${widget.index}'),
        onVisibilityChanged: (info){
          if(!mounted) return;
          final visible = info.visibleFraction > 0.05;
          if(visible){
            _tryPlay();
          }else{
            if(_played && mounted && !_controller.isDismissed && widget.fadeOutWhenLeave){
             try {
               _controller.reverse();
             }catch (_){}
            }
          }
        },
        child: content,
    ) : content;
  }
}
