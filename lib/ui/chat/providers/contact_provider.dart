import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/chat/core/repositories/contact_repository.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';

import '../../../core/providers/socket_provider.dart';
import '../contact_list/contact_list_page.dart';
import '../models/conversation.dart';
import '../models/friend_request.dart';

part 'contact_provider.g.dart';

// ===========================================================================
// 1. Contact List Provider
// ===========================================================================
@Riverpod(keepAlive: true)
class ContactList extends _$ContactList {
  @override
  Future<List<ChatUser>> build() async {
    // 获取仓库实例
    final repo = ref.watch(contactRepositoryProvider);
    //  1. 立即触发一次异步同步（不 await）
    // 这允许 build 方法立刻继续执行，直接去读本地 DB
    _silentSync(repo);
    //  2. 直接返回本地数据，实现秒开
    return repo.getAllContacts();
  }

  Future<void> _silentSync(ContactRepository repo) async {
    try {
      await repo.syncContacts();
      // 同步成功后，手动更新 state，UI 会无感刷新
      state = AsyncValue.data(await repo.getAllContacts());
    } catch (e) {
      debugPrint("Silent sync failed: $e");
    }
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

@Riverpod(keepAlive: true)
Future<List<ContactEntity>> contactEntities(ContactEntitiesRef ref) async {
  // 1. 获取原始 ChatUser 列表
  final users = await ref.watch(contactListProvider.future);

  // 2. 在这里处理拼音转换和排序（只在数据变动时跑一次）
  return users.map((u) {
    String pinyin = PinyinHelper.getPinyinE(u.nickname);
    String tag = pinyin.substring(0, 1).toUpperCase();
    if (!RegExp("[A-Z]").hasMatch(tag)) tag = "#";
    return ContactEntity(user: u, tagIndex: tag);
  }).toList()
    ..sort((a, b) => a.tagIndex.compareTo(b.tagIndex));
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
  FutureOr<void> build(String userId) => null;

  Future<bool> execute({String? reason}) async {
    state = const AsyncLoading();
    // 使用 guard 自动捕获错误并转换状态
    state = await AsyncValue.guard(() => Api.addFriendApi(userId, reason: reason));
    return !state.hasError;
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