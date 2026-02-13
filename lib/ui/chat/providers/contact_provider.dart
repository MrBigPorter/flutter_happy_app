import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/chat/core/repositories/contact_repository.dart';
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
    // 获取仓库实例
    final repo = ref.watch(contactRepositoryProvider);
    // A. 尝试同步 (API -> 本地数据库 -> 建立拼音索引)
    try {
      //  关键点：这里会调用 syncContacts，它会将数据存入 DB 并建立索引
      // 这样"本地搜索"功能才有数据可查
      await repo.syncContacts();
    }catch(e){
      // 如果网络失败，打印日志，但不抛出异常，继续执行（因为我们要读取本地缓存）
      debugPrint("️ Contact sync failed: $e. Using local cache.");
    }
    // B. 从本地数据库读取 (这时候已经是带有索引的最新数据了)
    return repo.getAllContacts();
  }

  /// Silently refreshes the contact list state
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.watch(contactRepositoryProvider);
      // 强制触发同步
      await repo.syncContacts();
      // 同步完成后再读取本地数据，确保数据和索引都是最新的
      return repo.getAllContacts();
    });
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
  //  核心修复：调用 Repository 的 searchContacts
  // 它会利用 syncContacts 建立好的拼音索引进行毫秒级本地搜索
  final repo = ref.watch(contactRepositoryProvider);
  return repo.search(keyword);
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