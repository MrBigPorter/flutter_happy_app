import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/selection_types.dart';

/// Auto-disposable provider for managing current selection states.
final selectionStateProvider = StateNotifierProvider.autoDispose<SelectionNotifier, Set<SelectionEntity>>((ref) {
  return SelectionNotifier();
});

class SelectionNotifier extends StateNotifier<Set<SelectionEntity>> {
  SelectionNotifier() : super({});

  /// Toggles the selection status of a given item based on the selection mode.
  /// [item]: The target entity to be selected or deselected.
  /// [mode]: Determines if the UI allows single or multiple selections.
  void toggle(SelectionEntity item, SelectionMode mode){
    if(mode == SelectionMode.single){
      // Single Selection Mode: Replace the entire set with the current item.
      state = {item};
    } else {
      // Multiple Selection Mode: Toggle the item's presence in the set.
      if(state.contains(item)){
        // Remove item if it already exists in the selection set.
        state = {...state}..remove(item);
      } else {
        // Add item to the selection set if not already present.
        state = {...state, item};
      }
    }
  }

  /// Utility to check if a specific item is currently selected.
  bool isSelected(SelectionEntity item) {
    return state.contains(item);
  }

  /// Returns the total number of currently selected items.
  int get selectedCount => state.length;
}