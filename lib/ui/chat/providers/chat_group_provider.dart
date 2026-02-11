import 'package:flutter_app/ui/chat/repository/message_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import '../../../core/api/chat_group_api.dart';
import '../../../core/constants/socket_events.dart';
import '../models/conversation.dart';
import '../models/group_role.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

part 'chat_group_provider.g.dart';

@riverpod
class ChatGroup extends _$ChatGroup {

// 修正点 1：增加同步锁和挂载标记，解决崩溃
  bool _isSyncing = false;
  bool _mounted = true;


  @override
  Future<ConversationDetail> build(String conversationId) async {
    _mounted = true;

    ref.onDispose(() {
      _mounted = false;
    });

    // 1.  尝试从本地数据库加载 (实现秒开)
    final repo = ref.read(messageRepositoryProvider);
    final localData = await repo.getGroupDetail(conversationId);

    if (localData != null) {
      // 命中缓存：直接返回本地数据，跳过骨架屏
      // 同时在后台静默发起网络请求更新数据 (Stale-While-Revalidate 策略)
      // 注意：这里不 await，让它异步执行
     // Future.microtask(() => _fetchAndSync(conversationId));

      return localData;
    }

    //  无缓存（首次）：必须显示 Loading 骨架屏，等待网络
    return await _fetchAndSync(conversationId);
  }

  // ===========================================================================
  // 1. 被动响应 Socket 事件 (由 ChatEventProcessor 调用)
  // ===========================================================================
  void handleSocketEvent(SocketGroupEvent event) {
    // 只有当 ID 匹配且当前数据已加载时才处理
    if (event.groupId != conversationId) return;
    if (!_mounted || !state.hasValue || _isSyncing) return;

    final currentDetail = state.requireValue;
    ConversationDetail? newDetail;

    //  [Refactor] 使用强类型 Payload，不再手动解析 Map
    final payload = event.payload;

    switch (event.type) {
      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
        if (payload.targetId == null) return;

        // 使用 payload.targetId 过滤
        final newMembers = currentDetail.members
            .where((m) => m.userId != payload.targetId)
            .toList();

        newDetail = currentDetail.copyWith(
          members: newMembers,
          // 可选：更新人数
          // memberCount: (currentDetail.memberCount > 0) ? currentDetail.memberCount - 1 : 0
        );
        break;

      case SocketEvents.memberMuted:
        if (payload.targetId == null) return;

        // 直接使用 payload.mutedUntil (int?)
        final mutedUntil = payload.mutedUntil;

        final newMembers = currentDetail.members.map((m) {
          return m.userId == payload.targetId ? m.copyWith(mutedUntil: mutedUntil) : m;
        }).toList();
        newDetail = currentDetail.copyWith(members: newMembers);
        break;

      case SocketEvents.groupInfoUpdated:
      // 直接使用 payload.updates (Map<String, dynamic>)
        newDetail = currentDetail.copyWith(
          name: payload.updates['name'] ?? currentDetail.name,
          announcement: payload.updates['announcement'] ?? currentDetail.announcement,
          isMuteAll: payload.updates['isMuteAll'] ?? currentDetail.isMuteAll,
        );
        break;

    // 复杂事件依然推荐重新拉取以保证数据完整性
      case SocketEvents.memberRoleUpdated:
      case SocketEvents.ownerTransferred:
      case SocketEvents.memberJoined:
        _fetchAndSync(conversationId);
        break;
    }

    if (newDetail != null) {
      state = AsyncData(newDetail);
      // 可选：将更新后的状态也同步到本地数据库，保持一致性
      LocalDatabaseService().saveConversationDetail(newDetail);
    }
  }

  // ===========================================================================
  // 2. 主动操作 (无感刷新模式)
  // 核心原则：操作过程中不设置 state = loading
  // ===========================================================================

  /// 踢人
  Future<void> kickMember(String targetUserId) async {
    try {
      await ChatGroupApi.kickMember(conversationId, targetUserId);

      // 成功后，直接操作内存数据
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newMembers = currentDetail.members.where((m) => m.userId != targetUserId).toList();

        final newDetail = currentDetail.copyWith(
          members: newMembers,
        );
        state = AsyncData(newDetail);
        // 同步缓存
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  /// 禁言
  Future<void> muteMember(String targetUserId, int duration) async {
    try {
      final res = await ChatGroupApi.muteMember(conversationId, targetUserId, duration);

      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newMembers = [
          for (final m in currentDetail.members)
            if (m.userId == targetUserId) m.copyWith(mutedUntil: res.mutedUntil) else m
        ];

        final newDetail = currentDetail.copyWith(members: newMembers);
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  /// 邀请成员
  Future<bool> inviteMembers(List<String> memberIds) async {
    try {
      await Api.groupInviteApi(
        InviteToGroupRequest(groupId: conversationId, memberIds: memberIds),
      );
      // 邀请成功后，我们需要新成员的完整信息 (头像等)
      // 调用 _fetchAndSync 进行静默更新并入库
      await _fetchAndSync(conversationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 设置管理员
  Future<void> setAdmin(String targetUserId, bool isAdmin) async {
    try {
      await ChatGroupApi.setAdmin(conversationId, targetUserId, isAdmin);

      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newMembers = currentDetail.members.map((m) {
          if (m.userId == targetUserId) {
            return m.copyWith(role: isAdmin ? GroupRole.admin : GroupRole.member);
          }
          return m;
        }).toList();

        final newDetail = currentDetail.copyWith(members: newMembers);
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  /// 更新群信息 (名、公告、全员禁言)
  Future<void> updateInfo({
    String? name,
    String? announcement,
    bool? isMuteAll,
  }) async {
    try {
      final res = await ChatGroupApi.updateGroupInfo(
        conversationId: conversationId,
        name: name,
        announcement: announcement,
        isMuteAll: isMuteAll,
      );

      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          name: res.name,
          announcement: res.announcement,
          // 防止 null 覆盖 (如果后端不返 isMuteAll)
          isMuteAll: res.isMuteAll ?? currentDetail.isMuteAll,
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  // --- 3. 生命周期操作 ---

  /// 退群
  Future<bool> leaveGroup() async {
    try {
      final res = await ChatGroupApi.leaveGroup(conversationId);
      if (res.success) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 解散群
  Future<bool> disbandGroup() async {
    try {
      await ChatGroupApi.disbandGroup(conversationId);
      ref.invalidate(conversationListProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 4. 辅助方法 (核心同步逻辑) ---

  /// 拉取网络数据 -> 存入数据库 -> 更新 State
  /// 既用于 Build 时的后台刷新，也用于操作后的数据同步
  Future<ConversationDetail> _fetchAndSync(String id) async {
    try {
      // 1. 请求 API
      final networkData = await Api.chatDetailApi(id);

      // 2. 存入本地数据库 (为下次秒开做准备)
      await LocalDatabaseService().saveConversationDetail(networkData);

      // 3. 更新内存 State (如果当前已经有值，做无感替换)
      if (state.hasValue) {
        state = AsyncData(networkData);
      }

      return networkData;
    } catch (e) {
      // 如果网络失败：
      // 1. 如果当前已经显示了缓存 (state.hasValue)，那就静默失败，维持显示旧数据
      if (state.hasValue) {
        return state.value!;
      }
      // 2. 如果本来就没数据，抛出错误让 UI 显示 Error Widget
      rethrow;
    }
  }
}

// ===========================================================================
// 建群控制器 (保持不变)
// ===========================================================================
@riverpod
class GroupCreateController extends _$GroupCreateController {
  @override
  FutureOr<String?> build() => null;

  Future<String?> create({required String name, required List<String> memberIds}) async {
    state = const AsyncLoading();
    final newState = await AsyncValue.guard(() async {
      final res = await Api.createGroupApi(name, memberIds);
      return res.id;
    });
    state = newState;
    if (newState.hasValue) {
      ref.invalidate(conversationListProvider);
    }
    return newState.value;
  }
}