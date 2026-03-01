import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/coupon_threshold_data.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/models/region.dart';
import 'package:flutter_app/ui/chat/models/call_ice_server.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../ui/chat/models/chat_settings_request.dart';
import '../../ui/chat/models/friend_request.dart';
import '../../utils/upload/global_upload_service.dart';
import '../models/fcm_notification.dart';
import '../models/kyc.dart';

class Api {
  /// Home banner carousel - type 1: banner, 2: advertisement
  static Future<List<Banners>> bannersApi({
    required int bannerCate,
    int? position,
    int? state,
    int? validState,
    int? limit = 10,
  }) async {
    final query = {
      'bannerCate': bannerCate,
      'limit': limit,
      'state': state,
      'validState': validState,
      'position': position,
    }..removeWhere((key, value) => value == null);

    final res = await Http.get("/api/v1/banners", query: query);
    return parseList<Banners>(res, (e) => Banners.fromJson(e));
  }

  /// Treasure hot groups
  static Future<List<HotGroupItem>> getTreasureHotGroups(int limit) async {
    final res = await Http.get(
      '/api/v1/treasure/hot-groups',
      query: {'limit': limit},
    );
    return parseList<HotGroupItem>(res, (e) => HotGroupItem.fromJson(e));
  }

  /// Home treasure recommendations
  static Future<List<IndexTreasureItem>> indexTreasuresApi() async {
    try {
      final res = await Http.get("/api/v1/home/sections", query: {'limit': 10});

      final data = parseList<IndexTreasureItem>(
        res,
            (e) => IndexTreasureItem.fromJson(e),
      );

      return data;
    } catch (e) {
      return [];
    }
  }

  /// Home advertisements - type 1: banner, 2: advertisement
  static Future<List<AdRes>> indexAdApi({
    required int adPosition,
    int? status,
    int? limit = 2,
  }) async {
    final query = {'adPosition': adPosition, 'status': status, 'limit': limit}
      ..removeWhere((key, value) => value == null);
    final res = await Http.get("/api/v1/ads", query: query);
    return parseList<AdRes>(res, (e) => AdRes.fromJson(e));
  }

  /// Home statistics data
  static Future<IndexStatistics> indexStatisticsApi() async {
    final res = await Http.get("/homepageStatisticalData.json");
    return IndexStatistics.fromJson(res);
  }

  /// User profile info
  static Future<UserInfo> getUserInfo() async {
    final res = await Http.get("/api/v1/auth/profile");
    return UserInfo.fromJson(res);
  }

  /// Wallet balance
  static Future<Balance> getWalletBalanceApi() async {
    final res = await Http.post('/api/v1/wallet/balance');
    return Balance.fromJson(res);
  }

  /// Payment channel list for recharge
  static Future<List<PaymentChannelConfigItem>>
  clientPaymentChannelsRecharge() async {
    final res = await Http.get('/api/v1/client/payment/channels/recharge');
    return parseList<PaymentChannelConfigItem>(
      res,
          (e) => PaymentChannelConfigItem.fromJson(e),
    );
  }

  /// Payment channel list for withdrawal
  static Future<List<PaymentChannelConfigItem>>
  clientPaymentChannelsWithdraw() async {
    final res = await Http.get('/api/v1/client/payment/channels/withdraw');
    return parseList<PaymentChannelConfigItem>(
      res,
          (e) => PaymentChannelConfigItem.fromJson(e),
    );
  }

  /// Create recharge order
  static Future<RechargeResponse> walletRechargeCreateApi(
      CreateRechargeDto data,
      ) async {
    final res = await Http.post(
      '/api/v1/wallet/recharge/create',
      data: data.toJson(),
    );
    return RechargeResponse.fromJson(res);
  }

  /// Wallet transaction history
  static Future<PageResult<WalletRechargeHistoryItem>> walletRechargeHistoryApi(
      WalletRechargeHistoryDto data,
      ) async {
    final res = await Http.get(
      '/api/v1/wallet/recharge/history',
      query: data.toJson(),
    );

    return parsePageResponse(res, (e) => WalletRechargeHistoryItem.fromJson(e));
  }

  /// Withdrawal history
  static Future<PageResult<WalletWithdrawHistoryItem>> walletWithdrawHistory(
      WalletWithdrawHistoryDto data,
      ) async {
    final res = await Http.get(
      '/api/v1/wallet/withdraw/history',
      query: data.toJson(),
    );

    return parsePageResponse(res, (e) => WalletWithdrawHistoryItem.fromJson(e));
  }

  /// Apply for withdrawal
  static Future<WalletWithdrawResponse> walletWithdrawApply(
      WalletWithdrawApplyDto data,
      ) async {
    final res = await Http.post(
      '/api/v1/wallet/withdraw/apply',
      data: data.toJson(),
    );
    return WalletWithdrawResponse.fromJson(res);
  }

  /// Order checkout
  static Future<OrderCheckoutResponse> ordersCheckOutApi(
      OrdersCheckoutParams params,
      ) async {
    final res = await Http.post(
      '/api/v1/orders/checkout',
      data: params.toJson(),
    );
    return OrderCheckoutResponse.fromJson(res);
  }

  /// System configuration
  static Future<SysConfig> getSysConfig() async {
    final res = await Http.get('/sysConfigGet.json');
    return SysConfig.fromJson(res);
  }

  /// Product category tabs
  static Future<List<ProductCategoryItem>> getProductCategoryList() async {
    final res = await Http.get('/api/v1/categories');
    return parseList<ProductCategoryItem>(
      res,
          (e) => ProductCategoryItem.fromJson(e),
    );
  }

  /// Product list
  /// categoryId 0: all, 1: hot, 2: tech
  static Future<PageResult<ProductListItem>> getProductList(
      ProductListParams params,
      ) async {
    final res = await Http.get(
      '/api/v1/treasure',
      queryParameters: {
        'page': params.page,
        'pageSize': params.pageSize,
        "categoryId": params.categoryId,
      },
    );
    return parsePageResponse(res, (e) => ProductListItem.fromJson(e));
  }

  /// Product detail
  static Future<ProductListItem> getProductDetail(String productId) async {
    final res = await Http.get('/api/v1/treasure/$productId');
    return ProductListItem.fromJson(res);
  }

  /// Get real-time price
  static Future<TreasureStatusModel> getRealTimePriceApi(
      String treasureId,
      ) async {
    final res = await Http.get('/api/v1/treasure/status/$treasureId');
    return TreasureStatusModel.fromJson(res);
  }

  /// Total winners quantity
  static Future<WinnersQuantity> winnersQuantityApi() async {
    final res = await Http.get('/actWinnersQuantity.json');
    return WinnersQuantity.fromJson(res);
  }

  /// Latest winners list
  static Future<List<WinnersLastsItem>> winnersLastsApi() async {
    final res = await Http.get('/actWinnersLasts.json');
    return parseList<WinnersLastsItem>(
      res,
          (e) => WinnersLastsItem.fromJson(e),
    );
  }

  /// Monthly activity data
  static Future<List<int>> actMonthNumApi() async {
    final res = await Http.get('/actMonthNum.json');
    return (res as List).map((e) => e as int).toList();
  }

  /// Monthly winners list (paginated)
  static Future<PageResult<ActWinnersMonth>> winnersMonthApi(
      ActWinnersMonthParams params,
      ) async {
    final res = await Http.get(
      '/actWinnersMonth.json',
      queryParameters: {
        "month": params.month,
        "page": params.page,
        "size": params.size,
      },
    );

    final result = parsePageResponse(res, (e) => ActWinnersMonth.fromJson(e));

    final now = DateTime.now();
    final target = DateTime(now.year, now.month - (params.month - 1), 1);

    final filteredList = result.list.where((item) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        item.lotteryTime * 1000,
      ).toLocal();
      return dt.month == target.month;
    }).toList();

    result.list
      ..clear()
      ..addAll(filteredList);

    int randomMs([int max = 3000]) => Random().nextInt(max);
    await Future.delayed(Duration(milliseconds: randomMs()));
    return result;
  }

  /// Coupon threshold list
  static Future<CouponThresholdResponse> thresholdListApi() async {
    final res = await Http.get('/userCouponThresholdList.json');
    final response = CouponThresholdResponse.fromJson(res);
    return response;
  }

  /// Order count by status
  static Future<OrderCount> orderCountApi() async {
    final res = await Http.get('/userOrderStateCount.json');
    return OrderCount.fromJson(res);
  }

  /// Order list
  static Future<PageResult<OrderItem>> orderListApi(
      OrderListParams params,
      ) async {
    final res = await Http.post(
      '/api/v1/orders/list',
      data: {
        "status": params.status,
        "treasureId": params.treasureId,
        "page": params.page,
        "pageSize": params.pageSize,
      },
    );
    final result = parsePageResponse(res, (e) => OrderItem.fromJson(e));
    return result;
  }

  /// Order detail
  static Future<OrderDetailItem> orderDetailApi(String orderId) async {
    final res = await Http.post(
      '/api/v1/orders/detail',
      data: {'orderId': orderId},
    );
    return OrderDetailItem.fromJson(res);
  }

  /// Apply for order refund
  static Future<RefundOrderResp> orderRefundApply(RefundApplyReq params) async {
    final res = await Http.post(
      '/api/v1/orders/refund/apply',
      data: params.toJson(),
    );
    return RefundOrderResp.fromJson(res);
  }

  /// Request OTP
  static Future<OtpRequest> otpRequestApi(String phone) async {
    final res = await Http.post('/api/v1/otp/request', data: {'phone': phone});
    return OtpRequest.fromJson(res);
  }

  /// Verify OTP
  static Future<void> optVerifyApi({
    required String phone,
    required String code,
  }) async {
    return await Http.post(
      '/api/v1/otp/verify',
      data: {'phone': phone, 'code': code},
    );
  }

  /// Login with OTP
  static Future<AuthLoginOtp> loginWithOtpApi({required phone}) async {
    final res = await Http.post(
      '/api/v1/auth/login/otp',
      data: {'phone': phone},
    );
    return AuthLoginOtp.fromJson(res);
  }

  /// Get user profile
  static Future<Profile> profileApi() async {
    final res = await Http.get('/api/v1/auth/profile');
    return Profile.fromJson(res);
  }

  /// Group list for treasure
  static Future<PageResult<GroupForTreasureItem>> groupsListApi(
      GroupsListRequestParams params,
      ) async {
    final res = await Http.get(
      '/api/v1/client/groups/list',
      query: {
        'page': params.page,
        'pageSize': params.pageSize,
        'treasureId': params.treasureId,
      },
    );
    return parsePageResponse(res, (e) => GroupForTreasureItem.fromJson(e));
  }

  /// Group detail
  static Future<GroupDetailModel> getGroupDetailApi(String groupId) async {
    final res = await Http.get('/api/v1/client/groups/$groupId');
    return GroupDetailModel.fromJson(res);
  }

  /// Group member list
  static Future<PageResult<GroupMemberItem>> groupMemberListApi(
      GroupMemberListRequestParams params,
      ) async {
    final res = await Http.get(
      '/api/v1/groups/${params.groupId}/members',
      query: {'page': params.page, 'pageSize': params.pageSize},
    );

    return parsePageResponse(res, (e) => GroupMemberItem.fromJson(e));
  }

  /// Start KYC session
  static Future<KycSession> kycSessionApi() async {
    final res = await Http.post('/api/v1/kyc/session');
    return KycSession.fromJson(res);
  }

  /// Get personal KYC status
  static Future<KycMe> kycMeApi() async {
    final res = await Http.get('/api/v1/kyc/me');
    return KycMe.fromJson(res);
  }

  /// Get supported KYC ID types
  static Future<List<KycIdTypes>> kycIdTypesApi() async {
    final res = await Http.get('/api/v1/kyc/id-types');
    return parseList<KycIdTypes>(res, (e) => KycIdTypes.fromJson(e));
  }

  /// Submit KYC application
  /// The DTO contains local file paths which are converted to files internally
  static Future<KycResponse> kycSubmitApi(SubmitKycDto dto) async {
    // 1. Convert DTO to Map for plain text data
    final Map<String, dynamic> bodyData = dto.toJson();

    // Remove path strings to prevent interference with file upload
    bodyData.remove('idCardFront');
    bodyData.remove('idCardBack');

    // 3. Special handling: encode OCR object as string (FormData doesn't support nested JSON)
    if (bodyData['ocrRawData'] != null) {
      bodyData['ocrRawData'] = jsonEncode(bodyData['ocrRawData']);
    }

    // This service handles converting local paths to binary streams (MultipartFile)
    final responseData = await GlobalUploadService().submitKyc(
      frontImage: XFile(dto.idCardFront!),
      backImage: dto.idCardBack != null ? XFile(dto.idCardBack!) : null,
      bodyData: bodyData,
    );

    // 5. Convert to response model
    return KycResponse.fromJson(responseData);
  }

  /// Get list of provinces
  static Future<List<Province>> provincesApi() async {
    final res = await Http.get('/api/v1/client/region/provinces');
    return parseList<Province>(res, (e) => Province.fromJson(e));
  }

  /// Get list of cities by province
  static Future<List<City>> cityApi(int provinceId) async {
    final res = await Http.get('/api/v1/client/region/cities/$provinceId');
    return parseList<City>(res, (e) => City.fromJson(e));
  }

  /// Get list of barangays by city
  static Future<List<Barangay>> barangayApi(int cityId) async {
    final res = await Http.get('/api/v1/client/region/barangays/$cityId');
    return parseList<Barangay>(res, (e) => Barangay.fromJson(e));
  }

  /// Get user address list
  static Future<PageResult<AddressRes>> addressListApi() async {
    final res = await Http.get(
      '/api/v1/client/address/list',
      query: {'page': 1, 'pageSize': 100},
    );
    return parsePageResponse(res, (e) => AddressRes.fromJson(e));
  }

  /// Create new address
  static Future<AddressRes> addressCreateApi(AddressCreateDto data) async {
    final res = await Http.post('/api/v1/client/address/create', data: data);
    return AddressRes.fromJson(res);
  }

  /// Update existing address
  static Future<AddressRes> addressUpdateApi(
      String addressId,
      AddressCreateDto data,
      ) async {
    final res = await Http.post(
      '/api/v1/client/address/update/$addressId',
      data: data,
    );
    return AddressRes.fromJson(res);
  }

  /// Delete an address
  static Future<dynamic> addressDeleteApi(String addressId) async {
    return await Http.delete('/api/v1/client/address/delete/$addressId');
  }

  /// Get address detail
  static Future<AddressRes> addressDetailApi(String addressId) async {
    final res = await Http.get('/api/v1/client/address/address/$addressId');
    return AddressRes.fromJson(res);
  }

  /// Register device for FCM notifications
  static Future<void> fcmNotificationDeviceRegisterApi(
      FcmNotificationDeviceRegisterDto data,
      ) async {
    return await Http.post(
      '/api/v1/client/notifications/device/register',
      data: data.toJson(),
    );
  }

  /// Get conversation list
  static Future<List<Conversation>> chatListApi({int page = 1}) async {
    final res = await Http.get('/api/v1/chat/list', query: {'page': page});
    return parseList(res, (e) => Conversation.fromJson(e));
  }

  /// Create business chat
  static Future<ConversationIdResponse> chatBusinessApi(
      String businessId,
      ) async {
    final res = await Http.get(
      '/api/v1/chat/business',
      query: {'businessId': businessId},
    );
    return ConversationIdResponse.fromJson(res);
  }

  /// Create direct chat
  static Future<ConversationIdResponse> chatDirectApi(
      String targetUserId,
      ) async {
    final res = await Http.post(
      '/api/v1/chat/direct',
      data: {'targetUserId': targetUserId},
    );
    return ConversationIdResponse.fromJson(res);
  }

  /// Invite members to group (Strongly typed version)
  static Future<InviteToGroupResponse> groupInviteApi(
      InviteToGroupRequest req,
      ) async {
    final res = await Http.post(
      '/api/v1/chat/group/invite',
      data: req.toJson(),
    );

    return InviteToGroupResponse.fromJson(res);
  }

  /// Leave group (Strongly typed version)
  static Future<LeaveGroupResponse> groupLeaveApi(LeaveGroupRequest req) async {
    final res = await Http.post('/api/v1/chat/group/leave', data: req.toJson());

    return LeaveGroupResponse.fromJson(res);
  }

  /// Get conversation detail (called when entering ChatPage)
  static Future<ConversationDetail> chatDetailApi(String conversationId) async {
    final res = await Http.get('/api/v1/chat/detail/$conversationId');
    return ConversationDetail.fromJson(res);
  }

  /// Get message history (called when entering ChatPage)
  static Future<MessageListResponse> chatMessagesApi(
      MessageHistoryRequest data,
      ) async {
    final res = await Http.get('/api/v1/chat/messages', query: data.toJson());
    return MessageListResponse.fromJson(res);
  }

  /// Get contact/friend list
  static Future<List<ChatUser>> getContactsApi() async {
    final res = await Http.get('/api/v1/users/contacts');
    return parseList(res, (e) => ChatUser.fromJson(e));
  }

  /// Search for users
  static Future<List<ChatUser>> searchUserApi(String keyword) async {
    final res = await Http.get(
      '/api/v1/chat/users/search',
      query: {'keyword': keyword},
    );
    return parseList(res, (e) => ChatUser.fromJson(e));
  }

  /// Create a group chat
  static Future<CreateGroupResponse> createGroupApi(
      String name,
      List<String> memberIds,
      ) async {
    final request = CreateGroupRequest(name: name, memberIds: memberIds);
    final res = await Http.post(
      '/api/v1/chat/create-group',
      data: request.toJson(),
    );
    return CreateGroupResponse.fromJson(res);
  }

  /// Send a message
  static Future<ChatMessage> sendMessage({
    required String id,
    required String conversationId,
    required String content,
    required int type,
    Map<String, dynamic>? meta,
  }) async {
    final res = await Http.post(
      '/api/v1/chat/message',
      data: {
        'id': id,
        'conversationId': conversationId,
        'content': content,
        'type': type,
        if (meta != null) 'meta': meta,
      },
    );
    return ChatMessage.fromJson(res);
  }

  /// Mark messages as read
  static Future<MessageMarkReadResponse> messageMarkAsReadApi(
      MessageMarkReadRequest data,
      ) async {
    final res = await Http.post(
      '/api/v1/chat/message/mark-as-read',
      data: data.toJson(),
    );
    return MessageMarkReadResponse.fromJson(res);
  }

  /// Recall a message
  static Future<MessageRecallResponse> messageRecallApi(
      MessageRecallRequest data,
      ) async {
    final res = await Http.post(
      '/api/v1/chat/message/recall',
      data: data.toJson(),
    );
    return MessageRecallResponse.fromJson(res);
  }

  /// Delete a message
  static Future<MessageDeleteResponse> messageDeleteApi(
      MessageDeleteRequest data,
      ) async {
    final res = await Http.delete(
      '/api/v1/chat/message/delete',
      data: data.toJson(),
    );
    return MessageDeleteResponse.fromJson(res);
  }

  /// Forward a message
  static Future<void> messageForwardApi({
    required String originalMessageId,
    required List<String> targetConversationIds,
  }) async {
    await Http.post(
      '/api/v1/chat/message/forward',
      data: {
        'originalMsgId': originalMessageId,
        'targetConversationIds': targetConversationIds,
      },
    );
  }

  /// Search in chat contacts
  static Future<List<ChatUser>> chatContactsSearch(String keyword) async {
    final res = await Http.get(
      '/api/v1/chat/contacts/search',
      query: {'keyword': keyword},
    );
    return parseList(res, (e) => ChatUser.fromJson(e));
  }

  /// Get friend request list
  static Future<List<FriendRequest>> getFriendRequestsApi() async {
    final res = await Http.get('/api/v1/chat/contacts/requests');
    return parseList(res, (e) => FriendRequest.fromJson(e));
  }

  /// Send a friend request
  static Future<bool> addFriendApi(String friendId, {String? reason}) async {
    final req = AddFriendRequest(friendId: friendId, reason: reason);
    await Http.post('/api/v1/chat/contacts/add', data: req.toJson());
    return true;
  }

  /// Handle a friend request (Accept/Reject)
  static Future<bool> handleFriendRequestApi(String targetId, FriendRequestAction action) async {
    final req = HandleFriendRequest(targetId: targetId, action: action);
    await Http.post('/api/v1/chat/contacts/handle', data: req.toJson());
    return true;
  }

  /// Get ICE server list for WebRTC
  static Future<List<CallIceServer>> chatIceServers() async {
    final res = await Http.get('/api/v1/chat/ice-servers');
    return parseList(res, (e) => CallIceServer.fromJson(e));
  }

  /// Set "Mute Notifications" for a conversation
  static Future<ChatSettingsResponse> setConversationMute(String conversationId, bool isMuted) async {
    final req = SetMuteRequest(conversationId: conversationId, isMuted: isMuted);
    final res = await Http.post('/api/v1/chat/settings/mute', data: req.toJson());
    return ChatSettingsResponse.fromJson(res);
  }

  /// Set "Pin to Top" for a conversation
  static Future<ChatSettingsResponse> setConversationPin(String conversationId, bool isPinned) async {
    final req = SetPinRequest(conversationId: conversationId, isPinned: isPinned);
    final res = await Http.post('/api/v1/chat/settings/pin', data: req.toJson());
    return ChatSettingsResponse.fromJson(res);
  }

  /// Clear chat history (cloud-side soft delete)
  static Future<bool> clearConversationHistory(String conversationId) async {
    final req = ClearHistoryRequest(conversationId: conversationId);
    await Http.post('/api/v1/chat/settings/clear-history', data: req.toJson());
    return true;
  }
}