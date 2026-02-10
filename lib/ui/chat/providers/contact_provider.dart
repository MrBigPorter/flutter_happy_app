import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';

import '../../../core/providers/socket_provider.dart';
import '../models/conversation.dart';
import '../models/friend_request.dart';

part 'contact_provider.g.dart';

// ===========================================================================
// 1. Contact List Provider
// ===========================================================================
@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<ChatUser>> build() async {
    return await Api.getContactsApi();
  }

  /// Silently refreshes the contact list state
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Api.getContactsApi());
  }
}

// ===========================================================================
// 2. Friend Request List Provider (Restored and Enabled)
// ===========================================================================
@riverpod
class FriendRequestList extends _$FriendRequestList {
  @override
  Future<List<FriendRequest>> build() async {
    // Core Change: Listen to Socket events within the Provider
    final socket = ref.watch(socketServiceProvider);

    // Automatically refresh self when a new application signal is received
    final subscription = socket.contactApplyStream.listen((_) {
      ref.invalidateSelf();
    });

    // Cancel subscription when the provider is disposed
    ref.onDispose(() => subscription.cancel());

    return await Api.getFriendRequestsApi();
  }

  /// Manually refreshes the friend request list
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Api.getFriendRequestsApi());
  }
}

// ===========================================================================
// 3. User Search Providers (Unified with Annotation Syntax)
// ===========================================================================

/// General user search by keyword
@riverpod
Future<List<ChatUser>> userSearch(UserSearchRef ref, String keyword) async {
  if (keyword.trim().isEmpty) return [];
  return await Api.searchUserApi(keyword);
}

/// Search within existing chat contacts
@riverpod
Future<List<ChatUser>> chatContactsSearch(ChatContactsSearchRef ref, String keyword) async {
  if (keyword.trim().isEmpty) return [];
  return await Api.chatContactsSearch(keyword);
}

// ===========================================================================
// 4. Controller: Add Friend
// ===========================================================================
// Uses family so that each user's "Add" button state is independent (avoids shared loading states)
@riverpod
class AddFriendController extends _$AddFriendController {
  @override
  FutureOr<void> build(String userId) {
    return null;
  }

  /// Executes the friend request
  Future<bool> execute({String? reason}) async {
    // Keep the provider alive during the asynchronous operation
    final link = ref.keepAlive();

    state = const AsyncLoading();

    final newState = await AsyncValue.guard(() async {
      // userId comes from the family parameter (this.userId)
      await Api.addFriendApi(userId, reason: reason);
    });

    // Only update state if the Provider has not been disposed (Double-guarding)
    if(state.hasValue || state.isLoading || state.hasError) {
      state = newState;
    }

    // Release the keep-alive lock once the request is complete.
    // If the UI was destroyed during the request, this Provider will now dispose.
    link.close();

    return !newState.hasError;
  }
}

// ===========================================================================
// 5. Controller: Handle Friend Request
// ===========================================================================
@riverpod
class HandleRequestController extends _$HandleRequestController {
  @override
  FutureOr<void> build() => null;

  /// Executes request handling (Accept/Reject)
  Future<bool> execute({
    required String userId,
    required FriendRequestAction action,
  }) async {
    state = const AsyncLoading();

    final newState = await AsyncValue.guard(() async {
      await Api.handleFriendRequestApi(userId, action);
    });

    state = newState;

    if (!newState.hasError) {
      // Linked Logic on Success:

      // 1. Refresh the friend request list (Updates NewFriendPage list)
      ref.invalidate(friendRequestListProvider);

      // 2. If accepted, refresh the Contact List to include the new friend
      if (action == FriendRequestAction.accepted) {
        ref.invalidate(contactListProvider);
      }
      return true;
    }
    return false;
  }
}