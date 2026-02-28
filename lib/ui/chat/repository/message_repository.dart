import 'package:flutter_app/ui/chat/models/group_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';

/// Provider definition for global repository access
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

class MessageRepository {
  final LocalDatabaseService _db = LocalDatabaseService();

  // ==========================================
  //  1. Basic Queries (Read Operations)
  // ==========================================

  /// Retrieves a specific message by its unique identifier
  Future<ChatUiModel?> get(String id) async {
    return await _db.getMessageById(id);
  }

  /// Retrieves the maximum sequence ID of a conversation for incremental sync checkpoints
  Future<int> getMaxSeqId(String conversationId) async {
    return (await _db.getMaxSeqId(conversationId)) ?? 0;
  }

  /// Retrieves conversation summary, primarily used for unread count self-healing
  Future<Conversation?> getConversation(String id) async {
    return await _db.getConversation(id);
  }

  /// Retrieves cached group-specific details
  Future<ConversationDetail?> getGroupDetail(String id) async {
    return await _db.getConversationDetail(id);
  }

  /// Persists group detail information into the local cache
  Future<void> saveGroupDetail(ConversationDetail detail) async {
    await _db.saveConversationDetail(detail);
  }

  /// Deletes a conversation; typically used when leaving or disbanding a group
  Future<void> deleteConversation(String conversationId) async {
    await _db.deleteConversation(conversationId);
  }

  /// Updates top-level conversation metadata.
  /// Synchronizes both the list view (Conversation) and the detail view (ConversationDetail).
  Future<void> updateConversationInfo(
      String conversationId, {
        String? name,
        String? avatar,
        String? announcement,
      }) async {
    // 1. Update the Conversation table for list view display
    final Map<String, dynamic> listUpdates = {};
    if (name != null) listUpdates['name'] = name;
    if (avatar != null) listUpdates['avatar'] = avatar;

    if (listUpdates.isNotEmpty) {
      await _db.updateConversation(conversationId, listUpdates);
    }

    // 2. Synchronize the detail cache to prevent stale data in group settings
    final detail = await _db.getConversationDetail(conversationId);
    if (detail != null) {
      final newDetail = detail.copyWith(
        name: name,
        avatar: avatar,
        announcement: announcement,
      );
      await _db.saveConversationDetail(newDetail);
    }
  }

  // ==========================================
  //  2. Group Membership Management
  // ==========================================

  /// Updates the mute status of a specific member locally
  Future<void> updateMemberMuted(
      String groupId,
      String userId,
      int? mutedUntil,
      ) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;
    final updatedMembers = detail.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(mutedUntil: mutedUntil);
      }
      return m;
    }).toList();
    await _db.saveConversationDetail(detail.copyWith(members: updatedMembers));
  }

  /// Updates the role of a group member (e.g., promoting to Admin)
  Future<void> updateMemberRole(
      String groupId,
      String userId,
      String roleStr,
      ) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    final newRole = GroupRole.values.firstWhere(
          (r) => r.name == roleStr,
      orElse: () => GroupRole.member,
    );

    final updatedMembers = detail.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();

    await _db.saveConversationDetail(detail.copyWith(members: updatedMembers));
  }

  /// Handles group ownership transfer by updating both the member roles and the ownerId field
  Future<void> transferOwner(
      String groupId, {
        required String oldOwnerId,
        required String newOwnerId,
      }) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    final updatedMembers = detail.members.map((m) {
      if (m.userId == newOwnerId) {
        return m.copyWith(role: GroupRole.owner);
      }
      if (m.userId == oldOwnerId) {
        return m.copyWith(role: GroupRole.admin);
      }
      return m;
    }).toList();

    await _db.saveConversationDetail(
      detail.copyWith(ownerId: newOwnerId, members: updatedMembers),
    );
  }

  /// Removes a specific user from the local group cache (Kicked/Left)
  Future<void> removeMemberFromGroup(
      String groupId,
      String targetUserId,
      ) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    final updatedMembers = detail.members
        .where((m) => m.userId != targetUserId)
        .toList();

    if (updatedMembers.length != detail.members.length) {
      final newDetail = detail.copyWith(members: updatedMembers);
      await _db.saveConversationDetail(newDetail);
    }
  }

  /// Adds a new member to the group cache if they do not already exist
  Future<void> addMemberToGroup(String groupId, ChatMember member) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    final exists = detail.members.any((m) => m.userId == member.userId);
    if (exists) return;

    final updatedMembers = [...detail.members, member];
    await _db.saveConversationDetail(detail.copyWith(members: updatedMembers));
  }

  // ==========================================
  //  3. Data Persistence & Fetching
  // ==========================================

  /// Paginated historical message retrieval for infinite scrolling/pull-to-refresh
  Future<List<ChatUiModel>> getHistory({
    required String conversationId,
    int offset = 0,
    int limit = 50,
  }) async {
    return await _db.getHistoryMessages(
      conversationId: conversationId,
      offset: offset,
      limit: limit,
    );
  }

  /// Reactive stream for real-time message list updates in the chat bubble view
  Stream<List<ChatUiModel>> watchMessages(String conversationId) {
    return _db.watchMessages(conversationId);
  }

  /// Retrieves messages in 'failed' or 'sending' states for retry mechanisms
  Future<List<ChatUiModel>> getPendingMessages() async {
    return await _db.getPendingMessages();
  }

  /// Writes or updates a message with Merge Conflict Defense.
  /// Preserves local resource paths (localPath, previewBytes) when syncing from server.
  Future<void> saveOrUpdate(ChatUiModel msg) async {
    final old = await _db.getMessageById(msg.id);

    if (old == null) {
      await _db.saveMessage(msg);
    } else {
      final merged = old.merge(msg);
      await _db.saveMessage(merged);
    }
  }

  /// Batch persistence logic for initial sync or history loading
  Future<void> saveBatch(List<ChatUiModel> msgs) async {
    for (var msg in msgs) {
      await saveOrUpdate(msg);
    }
  }

  /// Incremental Field Patching (Update specific fields).
  /// Built-in protection to prevent nullifying local binary assets during synchronization.
  Future<void> patchFields(String msgId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;

    // Defense logic: Prevent accidental nullification of local binary resources
    if (updates.containsKey('previewBytes') && updates['previewBytes'] == null) {
      updates.remove('previewBytes');
    }
    if (updates.containsKey('localPath') && updates['localPath'] == null) {
      updates.remove('localPath');
    }

    // Deep merge metadata to preserve existing fields (e.g., dimensions, blurhash)
    if (updates.containsKey('meta')) {
      final oldMsg = await _db.getMessageById(msgId);
      if (oldMsg != null) {
        final oldMeta = oldMsg.meta ?? {};
        final newMeta = updates['meta'] as Map<String, dynamic>;
        updates['meta'] = {...oldMeta, ...newMeta};
      }
    }

    await _db.updateMessage(msgId, updates);
  }

  /// Fast status transition (e.g., Sending -> Success)
  Future<void> updateStatus(String msgId, MessageStatus status) async {
    await _db.updateMessageStatus(msgId, status);
  }

  // ==========================================
  //  4. Read State & Housekeeping
  // ==========================================

  /// Silent Read: Updates local database without triggering external API calls.
  /// Used for cold-start self-healing or clearing red dots.
  Future<void> markAsReadLocally(String conversationId, int targetSeqId) async {
    await _db.markMessagesAsRead(conversationId, targetSeqId);
  }

  /// Forcefully clears unread count for a conversation.
  Future<void> forceClearUnread(String conversationId) async {
    await _db.clearUnreadCount(conversationId);
  }

  /// Physically removes a message record from local storage.
  Future<void> delete(String msgId) async {
    await _db.deleteMessage(msgId);
  }

  /// Marks a message as recalled locally with a custom tip text.
  Future<void> recallMessage(String msgId, String tipText) async {
    await _db.doLocalRecall(msgId, tipText);
  }
}