import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverlayProgressProvider extends StateNotifier<Map<String, double>> {
  // key: progress id, value: progress value (0.0 to 1.0)
  // initialize with empty map
  OverlayProgressProvider() : super({});

  void setProgress(String id, double value) {
    final v = value.clamp(0.0, 1.0);
    

    // If value is 0.0, remove the entry
    if (v == 0.0 && state.containsKey(id)) {
      final next = {...state}..remove(id);
      state = next;
      return;
    }
    state = {...state, id: v};
  }
  
  void removeProgress(String id) {
    if(state.containsKey(id)){
      final next = {...state}..remove(id);
      state = next;
    }
  }
}

// Global provider for overlay progress
final overProgressProvider = StateNotifierProvider<OverlayProgressProvider,Map<String,double>>((ref){
  return OverlayProgressProvider();
});

// Provider to get the effective progress (maximum value among all)
final overlayEffectiveProgressProvider = Provider<double>((ref){
  final m = ref.watch(overProgressProvider);
  var  p = 0.0;

  for(final v in m.values){
    if(v > p){
      p = v;
    }
  }

  return p;

});