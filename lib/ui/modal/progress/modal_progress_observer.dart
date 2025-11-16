import 'package:flutter/cupertino.dart';
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
      ref.read(overlayProgressProvider.notifier).state = value;
    };
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