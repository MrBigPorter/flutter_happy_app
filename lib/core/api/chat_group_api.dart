
import '../../ui/chat/models/group_manage_req.dart';
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
}