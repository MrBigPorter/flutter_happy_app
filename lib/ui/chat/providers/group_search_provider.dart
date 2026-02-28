import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/core/api/chat_group_api.dart';

part 'group_search_provider.g.dart';

@riverpod
class GroupSearchController extends _$GroupSearchController {
  @override
  FutureOr<List<GroupSearchResult>> build() {
    // Architectural Defense: Persistence Mechanism
    // Prevents the Provider from being prematurely disposed during
    // an active asynchronous search request.
    final link = ref.keepAlive();

    // Note: To optimize memory management, you can implement a timer
    // to close the link after a specific duration of inactivity.
    // ref.onDispose(() => timer?.cancel());

    // Initialize with an empty result list
    return [];
  }

  /// Executes a group search by keyword and updates the reactive state
  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    // Transition to loading state for UI feedback
    state = const AsyncLoading();

    try {
      // Dispatch API request to the backend search service
      final result = await ChatGroupApi.searchGroups(keyword);

      // Update state with successful results
      state = AsyncData(result);
    } catch (e, st) {
      // Capture and propagate errors to the UI layer
      state = AsyncError(e, st);
    }
  }
}