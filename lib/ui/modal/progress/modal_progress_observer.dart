import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/ui/modal/progress/overlay_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModalProgressObserver extends ConsumerStatefulWidget {
    final Widget child;

  const ModalProgressObserver({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ModalProgressObserver> createState() => _ModalProgressObserverState();
}

class _ModalProgressObserverState extends ConsumerState<ModalProgressObserver> {
  Animation<double>? _animation;


  void _onTick(){
    final value = _animation?.value;

    if(value != null){
      // 如果当前处于 idle (空闲) 状态，直接改。
      // 如果当前处于 transientCallbacks (动画回调中) 或 midFrame (构建中)，则推迟。
      if(SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle){
        // 推迟到这一帧绘制结束
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // 再次检查 mounted 防止组件已销毁
          if(!mounted) return;
          ref.read(overlayProgressProvider.notifier).state = value;
        });
      }else{
        // 直接设置状态
        ref.read(overlayProgressProvider.notifier).state = value;
      }
    }
  }

  // only init once after first build with id, then reattach on dependency changes
  void _attachAnimation(){
    // Detach from previous animation if any
     final route = ModalRoute.of(context);
     final animation = route?.animation;

     // Remove listener from old animation
     if(_animation != null) {
       _animation!.removeListener(_onTick);
     }

     // Attach to new animation
     _animation = animation;

     // Add listener to new animation
     if(_animation != null){
        _animation!.addListener(_onTick);
     }else {
       Future.microtask((){
         if(!mounted) return;
          ref.read(overlayProgressProvider.notifier).state = 1.0;
       });
     }
  }


  @override
  void dispose() {
    // Remove listener when disposing
    if(_animation != null){
      _animation!.removeListener(_onTick);
    }
    
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}