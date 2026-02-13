
// 选中项管理器
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/selection_types.dart';

final selectionStateProvider = StateNotifierProvider.autoDispose<SelectionNotifier, Set<SelectionEntity>>((ref) {
  return SelectionNotifier();
});

class SelectionNotifier extends StateNotifier<Set<SelectionEntity>> {
  SelectionNotifier() : super({});

  void toggle(SelectionEntity item, SelectionMode mode){
    if(mode == SelectionMode.single){
      state = {item}; // 单选模式，直接替换为当前项
    } else {
      // 多选模式，切换当前项的选中状态
      if(state.contains(item)){
        state = {...state}..remove(item); // 已选中则取消选中
      } else {
        state = {...state, item}; // 未选中则添加到选中集合
      }
    }
  }

  bool isSelected(SelectionEntity item) {
    return state.contains(item);
  }

  int get selectedCount => state.length;
}