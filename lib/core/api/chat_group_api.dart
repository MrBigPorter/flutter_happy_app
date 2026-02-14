
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/models/group_manage_req.dart';
import 'http_client.dart';

class ChatGroupApi {
  // =================================================================
  // 1. 踢人 (Kick Member)
  // URL: POST /api/v1/chat/group/kick
  // =================================================================
  static Future<KickMemberRes> kickMember(
      String conversationId,
      String targetUserId,
      ) async {
    final request = KickMemberReq(
        conversationId: conversationId,
        targetUserId: targetUserId
    );

    final res = await Http.post(
      '/api/v1/chat/group/kick',
      data: request.toJson(),
    );
    return KickMemberRes.fromJson(res);
  }

  // =================================================================
  // 2. 禁言 (Mute Member)
  // URL: POST /api/v1/chat/group/mute
  // =================================================================
  static Future<MuteMemberRes> muteMember(
      String conversationId,
      String targetUserId,
      int duration, // 秒
      ) async {
    final request = MuteMemberReq(
      conversationId: conversationId,
      targetUserId: targetUserId,
      duration: duration,
    );

    final res = await Http.post(
      '/api/v1/chat/group/mute',
      data: request.toJson(),
    );
    return MuteMemberRes.fromJson(res);
  }

  // =================================================================
  // 3. 修改群信息 (Update Group Info)
  // URL: POST /api/v1/chat/group/update
  // =================================================================
  static Future<UpdateGroupRes> updateGroupInfo({
    required String conversationId,
    String? name,
    String? announcement,
    bool? isMuteAll,
    bool? joinNeedApproval,
    String? avatar,
  }) async {
    final request = UpdateGroupInfoReq(
      conversationId: conversationId,
      name: name,
      announcement: announcement,
      isMuteAll: isMuteAll,
      joinNeedApproval: joinNeedApproval,
      avatar: avatar,
    );

    final res = await Http.post(
      '/api/v1/chat/group/update',
      data: request.toJson(),
    );
    return UpdateGroupRes.fromJson(res);
  }

  // =================================================================
  // 4. 设置管理员 (Set Admin)
  // URL: POST /api/v1/chat/group/admin
  // =================================================================
  static Future<SetAdminRes> setAdmin(
      String conversationId,
      String targetUserId,
      bool isAdmin,
      ) async {
    // 假设您没有专门定义 Request DTO，直接传 Map 也可以
    // 但如果有 SetAdminReq 最好用对象
    final data = {
      'conversationId': conversationId,
      'targetUserId': targetUserId,
      'isAdmin': isAdmin,
    };

    final res = await Http.post(
      '/api/v1/chat/group/admin',
      data: data,
    );
    return SetAdminRes.fromJson(res);
  }

  static Future<List<GroupSearchResult>> searchGroups(String keyword) async {
    final res = await Http.get(
      '/api/v1/chat/group/search', // 对应后端的 Controller 路径
      queryParameters: {'keyword': keyword},
    );

    // 假设 Http.get 返回的是 List<dynamic>
    return (res as List)
        .map((e) => GroupSearchResult.fromJson(e))
        .toList();
  }

  // =================================================================
  // 5. 转让群主 (Transfer Owner)
  // URL: POST /api/v1/chat/group/transfer-owner
  // =================================================================
  static Future<TransferOwnerRes> transferOwner(
      String conversationId,
      String newOwnerId,
      ) async {
    final data = {
      'conversationId': conversationId,
      'newOwnerId': newOwnerId,
    };

    final res = await Http.post(
      '/api/v1/chat/group/transfer-owner',
      data: data,
    );
    return TransferOwnerRes.fromJson(res);
  }

  // =================================================================
  // 6. 主动退群 (Leave Group)
  // URL: DELETE /api/v1/chat/group/leave/:id
  // =================================================================
  static Future<LeaveGroupRes> leaveGroup(String conversationId) async {
    final res = await Http.delete(
      '/api/v1/chat/group/leave/$conversationId',
    );
    return LeaveGroupRes.fromJson(res);
  }

  // =================================================================
  // 7. 解散群 (Disband Group)
  // URL: DELETE /api/v1/chat/group/disband/:id
  // =================================================================
  static Future<DisbandGroupRes> disbandGroup(String conversationId) async {
    final res = await Http.delete(
      '/api/v1/chat/group/disband/$conversationId',
    );
    return DisbandGroupRes.fromJson(res);
  }

  // =================================================================
  // 8. 申请加入群组 (Apply to Group)
  // URL: POST /api/v1/chat/group/apply
  // =================================================================
  static Future<ApplyToGroupRes> applyToGroup({
    required String conversationId,
    String? reason,
  }) async {
    final request = ApplyToGroupReq(
      conversationId: conversationId,
      reason: reason,
    );

    final res = await Http.post(
      '/api/v1/chat/group/apply',
      data: request.toJson(),
    );
    return ApplyToGroupRes.fromJson(res);
  }

  // =================================================================
  // 9. 获取入群申请列表 (Get Join Requests)
  // URL: GET /api/v1/chat/group/requests/:conversationId
  // =================================================================
  static Future<List<GroupJoinRequest>> getJoinRequests(String conversationId) async {
    final res = await Http.get(
      '/api/v1/chat/group/requests/$conversationId',
    );

    // 使用通用解析逻辑处理列表数据
    if (res is List) {
      return res.map((e) => GroupJoinRequest.fromJson(e)).toList();
    }
    return [];
  }

  // =================================================================
  // 10. 处理入群申请 (Handle Join Request)
  // URL: POST /api/v1/chat/group/request/handle
  // =================================================================
  static Future<bool> handleJoinRequest({
    required String requestId,
    required bool isAccept,
  }) async {
    final request = HandleGroupJoinReq(
      requestId: requestId,
      action: isAccept ? 'accept' : 'reject',
    );

    await Http.post(
      '/api/v1/chat/group/request/handle',
      data: request.toJson(),
    );

    // 后端 handle 接口通常只返回成功标识
    return true;
  }
}