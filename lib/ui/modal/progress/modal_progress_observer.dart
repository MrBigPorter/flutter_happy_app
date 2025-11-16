import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/modal/progress/overlay_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModalProgressObserver extends ConsumerStatefulWidget {
   final String id;
    final Widget child;

  const ModalProgressObserver({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  ConsumerState<ModalProgressObserver> createState() => _ModalProgressObserverState();
}

class _ModalProgressObserverState extends ConsumerState<ModalProgressObserver> {
  Animation<double>? _animation;

  void _onTick(){
    final value = _animation?.value;
    final notifier = ref.read(overProgressProvider.notifier);
    if(value != null){
      if(value <= 0.001){
        notifier.removeProgress(widget.id);
      }else{
        notifier.setProgress(widget.id, value);
      }
    };
  }

  // only init once after first build with id, then reattach on dependency changes
  void _attachAnimation(){
    // Detach from previous animation if any
     final route = ModalRoute.of(context);
     final animation = route?.animation;

     // Remove listener from old animation
     if(animation != null) {
       animation.removeListener(_onTick);
     }

     // Attach to new animation
     _animation = animation;

     // Add listener to new animation
     if(_animation != null){
        _animation!.addListener(_onTick);
     }else {
       Future.microtask((){
         if(!mounted) return;
          ref.read(overProgressProvider.notifier).setProgress(widget.id, 1.0);
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