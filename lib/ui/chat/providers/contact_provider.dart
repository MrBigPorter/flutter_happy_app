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
    final repo = ref.watch(contactRepositoryProvider);

    // Trigger an asynchronous background synchronization without awaiting.
    // This allows the build method to return the local database content immediately.
    _silentSync(repo);

    // Fetch from local repository for instant UI rendering (Offline-first)
    return repo.getAllContacts();
  }

  /// Performs a background sync and updates the state upon completion
  Future<void> _silentSync(ContactRepository repo) async {
    try {
      await repo.syncContacts();
      // Silently update the state once sync finishes to refresh the UI
      state = AsyncValue.data(await repo.getAllContacts());
    } catch (e) {
      debugPrint("[ContactList] Silent sync failed: $e");
    }
  }

  /// Forces a complete refresh of the contact list and synchronization
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(contactRepositoryProvider);
      await repo.syncContacts();
      return repo.getAllContacts();
    });
  }
}

/// Computes Pinyin mapping and sorting for the contact list
@Riverpod(keepAlive: true)
Future<List<ContactEntity>> contactEntities(ContactEntitiesRef ref) async {
  // 1. Listen to the raw ChatUser list
  final users = await ref.watch(contactListProvider.future);

  // 2. Perform Pinyin conversion and grouping (Executed only on list changes)
  return users.map((u) {
    String pinyin = PinyinHelper.getPinyinE(u.nickname);
    String tag = pinyin.substring(0, 1).toUpperCase();
    if (!RegExp("[A-Z]").hasMatch(tag)) tag = "#";
    return ContactEntity(user: u, tagIndex: tag);
  }).toList()
    ..sort((a, b) => a.tagIndex.compareTo(b.tagIndex));
}

// ===========================================================================
// 2. Friend Request List Provider
// ===========================================================================

@riverpod
class FriendRequestList extends _$FriendRequestList {
  @override
  Future<List<FriendRequest>> build() async {
    // Reactive binding: Listen to Socket service for real-time updates
    final socket = ref.watch(socketServiceProvider);

    // Automatically invalidate and re-fetch when a new contact application signal arrives
    final subscription = socket.contactApplyStream.listen((_) {
      ref.invalidateSelf();
    });

    ref.onDispose(() => subscription.cancel());

    return await Api.getFriendRequestsApi();
  }

  /// Manually refreshes the friend request list state
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Api.getFriendRequestsApi());
  }
}

// ===========================================================================
// 3. User Search Providers
// ===========================================================================

/// Executes a local search using the indexed Pinyin repository
@riverpod
Future<List<ChatUser>> userSearch(UserSearchRef ref, String keyword) async {
  if (keyword.trim().isEmpty) return [];
  final repo = ref.watch(contactRepositoryProvider);
  return repo.search(keyword);
}

/// Performs a remote search within existing chat contacts
@riverpod
Future<List<ChatUser>> chatContactsSearch(ChatContactsSearchRef ref, String keyword) async {
  if (keyword.trim().isEmpty) return [];
  return await Api.chatContactsSearch(keyword);
}

// ===========================================================================
// 4. Controller: Add Friend
// ===========================================================================

@riverpod
class AddFriendController extends _$AddFriendController {
  @override
  FutureOr<void> build(String userId) => null;

  /// Sends a friend request to a specific user
  Future<bool> execute({String? reason}) async {
    state = const AsyncLoading();
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

  /// Responds to a friend request (Accept/Reject) and triggers downstream refreshes
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
      // 1. Refresh the friend request list to update the 'New Friends' page
      ref.invalidate(friendRequestListProvider);

      // 2. Refresh the primary Contact List if the request was accepted
      if (action == FriendRequestAction.accepted) {
        ref.invalidate(contactListProvider);
      }
      return true;
    }
    return false;
  }
}