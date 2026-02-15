import 'package:flutter_app/ui/chat/models/conversation.dart';
import '../../ui/chat/models/group_manage_req.dart';
import '../../utils/helper.dart';
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
    //  修正：使用 SetAdminReq 对象
    final request = SetAdminReq(
        conversationId: conversationId,
        targetUserId: targetUserId,
        isAdmin: isAdmin
    );

    final res = await Http.post(
      '/api/v1/chat/group/admin',
      data: request.toJson(),
    );
    return SetAdminRes.fromJson(res);
  }

  // =================================================================
  // 5. 搜索群组 (Search Groups)
  // URL: GET /api/v1/chat/group/search
  // =================================================================
  static Future<List<GroupSearchResult>> searchGroups(String keyword) async {
    final res = await Http.get(
      '/api/v1/chat/group/search',
      queryParameters: {'keyword': keyword},
    );

    // 假设 GroupSearchResult 定义在 conversation.dart 或 group_manage_req.dart 中
    return (res as List)
        .map((e) => GroupSearchResult.fromJson(e))
        .toList();
  }

  // =================================================================
  // 6. 转让群主 (Transfer Owner)
  // URL: POST /api/v1/chat/group/transfer-owner
  // =================================================================
  static Future<SimpleSuccessRes> transferOwner(
      String conversationId,
      String newOwnerId,
      ) async {
    //  修正：使用 TransferOwnerReq 对象
    final request = TransferOwnerReq(
        conversationId: conversationId,
        newOwnerId: newOwnerId
    );

    final res = await Http.post(
      '/api/v1/chat/group/transfer-owner',
      data: request.toJson(),
    );
    //  修正：返回 SimpleSuccessRes
    return SimpleSuccessRes.fromJson(res);
  }

  // =================================================================
  // 7. 主动退群 (Leave Group)
  // URL: DELETE /api/v1/chat/group/leave/:id
  // =================================================================
  static Future<SimpleSuccessRes> leaveGroup(String conversationId) async {
    final res = await Http.delete(
      '/api/v1/chat/group/leave/$conversationId',
    );
    //  修正：返回 SimpleSuccessRes
    return SimpleSuccessRes.fromJson(res);
  }

  // =================================================================
  // 8. 解散群 (Disband Group)
  // URL: DELETE /api/v1/chat/group/disband/:id
  // =================================================================
  static Future<SimpleSuccessRes> disbandGroup(String conversationId) async {
    final res = await Http.delete(
      '/api/v1/chat/group/disband/$conversationId',
    );
    //  修正：返回 SimpleSuccessRes
    return SimpleSuccessRes.fromJson(res);
  }

  // =================================================================
  // 9. 申请加入群组 (Apply to Group)
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
  // 10. 获取入群申请列表 (Get Join Requests)
  // URL: GET /api/v1/chat/group/requests/:conversationId
  // =================================================================
  //  修正：返回 List<GroupJoinRequestItem>
  static Future<List<GroupJoinRequestItem>> getJoinRequests(String conversationId) async {
    final res = await Http.get(
      '/api/v1/chat/group/requests/$conversationId',
    );
    return parseList(res, (e) => GroupJoinRequestItem.fromJson(e));
  }

  // =================================================================
  // 11. 处理入群申请 (Handle Join Request)
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

    return true;
  }
}