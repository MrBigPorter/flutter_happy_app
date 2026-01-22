import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/coupon_threshold_data.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/models/region.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/core/models/index.dart';

import '../../ui/chat/models/chat_ui_model.dart';
import '../../utils/upload/global_upload_service.dart';
import '../models/fcm_notification.dart';
import '../models/kyc.dart';

class Api {
  /// 首页轮播图 type 1: banner 2: 广告 home banner
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

  // treasure hot groups
  static Future<List<HotGroupItem>> getTreasureHotGroups(int limit) async {
    final res = await Http.get(
      '/api/v1/treasure/hot-groups',
      query: {'limit': limit},
    );
    return parseList<HotGroupItem>(res, (e) => HotGroupItem.fromJson(e));
  }

  /// 首页宝藏推荐  home treasures
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

  /// 首页广告 type 1: banner 2: 广告 home ad
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

  /// 首页统计数据 home statistics
  static Future<IndexStatistics> indexStatisticsApi() async {
    final res = await Http.get("/homepageStatisticalData.json");
    return IndexStatistics.fromJson(res);
  }

  /// 用户信息 user info
  static Future<UserInfo> getUserInfo() async {
    final res = await Http.get("/api/v1/auth/profile");
    return UserInfo.fromJson(res);
  }

  /// 钱包余额 wallet balance
  static Future<Balance> getWalletBalanceApi() async {
    final res = await Http.post('/api/v1/wallet/balance');
    return Balance.fromJson(res);
  }

  /// 支付渠道列表 payment channels
  static Future<List<PaymentChannelConfigItem>>
  clientPaymentChannelsRecharge() async {
    final res = await Http.get('/api/v1/client/payment/channels/recharge');
    return parseList<PaymentChannelConfigItem>(
      res,
      (e) => PaymentChannelConfigItem.fromJson(e),
    );
  }

  // 取款支付渠道列表 payment channels
  static Future<List<PaymentChannelConfigItem>>
  clientPaymentChannelsWithdraw() async {
    final res = await Http.get('/api/v1/client/payment/channels/withdraw');
    return parseList<PaymentChannelConfigItem>(
      res,
      (e) => PaymentChannelConfigItem.fromJson(e),
    );
  }

  /// 创建充值订单 create recharge order
  static Future<RechargeResponse> walletRechargeCreateApi(
    CreateRechargeDto data,
  ) async {
    final res = await Http.post(
      '/api/v1/wallet/recharge/create',
      data: data.toJson(),
    );
    return RechargeResponse.fromJson(res);
  }

  /// 钱包交易记录 wallet transactions
  static Future<PageResult<WalletRechargeHistoryItem>> walletRechargeHistoryApi(
    WalletRechargeHistoryDto data,
  ) async {
    final res = await Http.get(
      '/api/v1/wallet/recharge/history',
      query: data.toJson(),
    );

    return parsePageResponse(res, (e) => WalletRechargeHistoryItem.fromJson(e));
  }

  /// 提现记录 withdraw history
  static Future<PageResult<WalletWithdrawHistoryItem>> walletWithdrawHistory(
    WalletWithdrawHistoryDto data,
  ) async {
    final res = await Http.get(
      '/api/v1/wallet/withdraw/history',
      query: data.toJson(),
    );

    return parsePageResponse(res, (e) => WalletWithdrawHistoryItem.fromJson(e));
  }

  /// apply withdraw
  static Future<WalletWithdrawResponse> walletWithdrawApply(
    WalletWithdrawApplyDto data,
  ) async {
    final res = await Http.post(
      '/api/v1/wallet/withdraw/apply',
      data: data.toJson(),
    );
    return WalletWithdrawResponse.fromJson(res);
  }

  /// checkout order
  static Future<OrderCheckoutResponse> ordersCheckOutApi(
    OrdersCheckoutParams params,
  ) async {
    final res = await Http.post(
      '/api/v1/orders/checkout',
      data: params.toJson(),
    );
    return OrderCheckoutResponse.fromJson(res);
  }

  /// 系统配置 sys config
  static Future<SysConfig> getSysConfig() async {
    final res = await Http.get('/sysConfigGet.json');
    return SysConfig.fromJson(res);
  }

  /// 商品分类 product category tabs
  static Future<List<ProductCategoryItem>> getProductCategoryList() async {
    final res = await Http.get('/api/v1/categories');
    return parseList<ProductCategoryItem>(
      res,
      (e) => ProductCategoryItem.fromJson(e),
    );
  }

  /// 商品列表 product list
  /// products_category_id 0: all
  /// products_category_id 1: hot
  /// products_category_id 2: tech
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

  /// 商品详情 product detail
  static Future<ProductListItem> getProductDetail(String productId) async {
    final res = await Http.get('/api/v1/treasure/$productId');
    return ProductListItem.fromJson(res);
  }

  // 获取实时价格
  static Future<TreasureStatusModel> getRealTimePriceApi(
    String treasureId,
  ) async {
    final res = await Http.get('/api/v1/treasure/status/$treasureId');
    return TreasureStatusModel.fromJson(res);
  }

  /// 中奖总人数 total winners quantity
  static Future<WinnersQuantity> winnersQuantityApi() async {
    final res = await Http.get('/actWinnersQuantity.json');
    return WinnersQuantity.fromJson(res);
  }

  /// 最新中奖名单 latest winners list
  static Future<List<WinnersLastsItem>> winnersLastsApi() async {
    final res = await Http.get('/actWinnersLasts.json');
    return parseList<WinnersLastsItem>(
      res,
      (e) => WinnersLastsItem.fromJson(e),
    );
  }

  /// 月度活动数据 monthly activity data
  static Future<List<int>> actMonthNumApi() async {
    final res = await Http.get('/actMonthNum.json');
    return (res as List).map((e) => e as int).toList();
  }

  /// 月度中奖名单 monthly winners list
  /// returns paginated result

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

  /// 优惠券门槛列表 coupon threshold list
  /// returns list of CouponThresholdData
  /// desc: description

  static Future<CouponThresholdResponse> thresholdListApi() async {
    final res = await Http.get('/userCouponThresholdList.json');
    final response = CouponThresholdResponse.fromJson(res);
    return response;
  }

  /// 订单各状态数量 order count by status
  static Future<OrderCount> orderCountApi() async {
    final res = await Http.get('/userOrderStateCount.json');
    return OrderCount.fromJson(res);
  }

  /// 订单列表 order list
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

  /// order detail
  static Future<OrderDetailItem> orderDetailApi(String orderId) async {
    final res = await Http.post(
      '/api/v1/orders/detail',
      data: {'orderId': orderId},
    );
    return OrderDetailItem.fromJson(res);
  }

  static Future<RefundOrderResp> orderRefundApply(RefundApplyReq params) async {
    final res = await Http.post(
      '/api/v1/orders/refund/apply',
      data: params.toJson(),
    );
    return RefundOrderResp.fromJson(res);
  }

  // otp request
  static Future<OtpRequest> otpRequestApi(String phone) async {
    final res = await Http.post('/api/v1/otp/request', data: {'phone': phone});
    return OtpRequest.fromJson(res);
  }

  // verify otp
  static Future<void> optVerifyApi({
    required String phone,
    required String code,
  }) async {
    return await Http.post(
      '/api/v1/otp/verify',
      data: {'phone': phone, 'code': code},
    );
  }

  // login with otp
  static Future<AuthLoginOtp> loginWithOtpApi({required phone}) async {
    final res = await Http.post(
      '/api/v1/auth/login/otp',
      data: {'phone': phone},
    );
    return AuthLoginOtp.fromJson(res);
  }

  // profile
  static Future<Profile> profileApi() async {
    final res = await Http.get('/api/v1/auth/profile');
    return Profile.fromJson(res);
  }

  // group list
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

  // group detail
  static Future<GroupDetailModel> getGroupDetailApi(String groupId) async {
    final res = await Http.get('/api/v1/client/groups/$groupId');
    return GroupDetailModel.fromJson(res);
  }

  // group member list
  static Future<PageResult<GroupMemberItem>> groupMemberListApi(
    GroupMemberListRequestParams params,
  ) async {
    final res = await Http.get(
      '/api/v1/groups/${params.groupId}/members',
      query: {'page': params.page, 'pageSize': params.pageSize},
    );

    return parsePageResponse(res, (e) => GroupMemberItem.fromJson(e));
  }

  //kyc session
  static Future<KycSession> kycSessionApi() async {
    final res = await Http.post('/api/v1/kyc/session');
    return KycSession.fromJson(res);
  }

  // kyc me
  static Future<KycMe> kycMeApi() async {
    final res = await Http.get('/api/v1/kyc/me');
    return KycMe.fromJson(res);
  }

  // kyc id types
  static Future<List<KycIdTypes>> kycIdTypesApi() async {
    final res = await Http.get('/api/v1/kyc/id-types');
    return parseList<KycIdTypes>(res, (e) => KycIdTypes.fromJson(e));
  }

  // kyc submit
  /// 这里的 dto 包含的是图片路径 String，我们在内部把它转成 File
  static Future<KycResponse> kycSubmitApi(SubmitKycDto dto) async {
    // 1. 把 DTO 转成 Map (获取纯文本数据)
    final Map<String, dynamic> bodyData = dto.toJson();

    // 否则后端会收到一个叫 "idCardFront" 的字符串文本，干扰文件上传
    bodyData.remove('idCardFront');
    bodyData.remove('idCardBack');

    // 3. 特殊处理：把 OCR 对象转成字符串 (因为 FormData 不支持嵌套 JSON 对象)
    if (bodyData['ocrRawData'] != null) {
      bodyData['ocrRawData'] = jsonEncode(bodyData['ocrRawData']);
    }

    // 它负责把你的本地路径 (String) 变成二进制文件流 (MultipartFile)
    final responseData = await GlobalUploadService().submitKyc(
      frontImage: XFile(dto.idCardFront!),
      backImage: dto.idCardBack != null ? XFile(dto.idCardBack!) : null,
      bodyData: bodyData,
    );

    // 5. 转成响应模型
    return KycResponse.fromJson(responseData);
  }

  static Future<List<Province>> provincesApi() async {
    final res = await Http.get('/api/v1/client/region/provinces');
    return parseList<Province>(res, (e) => Province.fromJson(e));
  }

  static Future<List<City>> cityApi(int provinceId) async {
    final res = await Http.get('/api/v1/client/region/cities/$provinceId');
    return parseList<City>(res, (e) => City.fromJson(e));
  }

  static Future<List<Barangay>> barangayApi(int cityId) async {
    final res = await Http.get('/api/v1/client/region/barangays/$cityId');
    return parseList<Barangay>(res, (e) => Barangay.fromJson(e));
  }

  // address list
  static Future<PageResult<AddressRes>> addressListApi() async {
    final res = await Http.get(
      '/api/v1/client/address/list',
      query: {'page': 1, 'pageSize': 100},
    );
    return parsePageResponse(res, (e) => AddressRes.fromJson(e));
  }

  static Future<AddressRes> addressCreateApi(AddressCreateDto data) async {
    final res = await Http.post('/api/v1/client/address/create', data: data);
    return AddressRes.fromJson(res);
  }

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

  static Future<dynamic> addressDeleteApi(String addressId) async {
    return await Http.delete('/api/v1/client/address/delete/$addressId');
  }

  static Future<AddressRes> addressDetailApi(String addressId) async {
    final res = await Http.get('/api/v1/client/address/address/$addressId');
    return AddressRes.fromJson(res);
  }

  static Future<void> fcmNotificationDeviceRegisterApi(
    FcmNotificationDeviceRegisterDto data,
  ) async {
    return await Http.post(
      '/api/v1/client/notifications/device/register',
      data: data.toJson(),
    );
  }

  // 获取聊天列表
  static Future<List<Conversation>> chatListApi({int page = 1}) async {
    final res = await Http.get('/api/v1/chat/list', query: {'page': page});
    return parseList(res, (e) => Conversation.fromJson(e));
  }

  // 创建商户聊天
  static Future<ConversationIdResponse> chatBusinessApi(
    String businessId,
  ) async {
    final res = await Http.get(
      '/api/v1/chat/business',
      query: {'businessId': businessId},
    );
    return ConversationIdResponse.fromJson(res);
  }

  // 创建私聊
  static Future<ConversationIdResponse> chatDirectApi(
    String targetUserId,
  ) async {
    final res = await Http.post(
      '/api/v1/chat/direct',
      data: {'targetUserId': targetUserId},
    );
    return ConversationIdResponse.fromJson(res);
  }

  // 创建群聊
  static Future<ConversationIdResponse> chatGroupApi(
    String name,
    List<String> memberIds,
  ) async {
    final res = await Http.post(
      '/api/v1/chat/group',
      data: {
        'name': name,
        'members': memberIds, // 注意这里是复数，且是数组
      },
    );
    return ConversationIdResponse.fromJson(res);
  }

  // 5. 获取详情 (进入 ChatPage 时调用)
  // 后端返回: ConversationDetailResponseDto
  static Future<ConversationDetail> chatDetailApi(String conversationId) async {
    final res = await Http.get('/api/v1/chat/detail/$conversationId');
    return ConversationDetail.fromJson(res);
  }

  // 6. 获取消息列表 (进入 ChatPage 时调用)
  static Future<MessageListResponse> chatMessagesApi(MessageHistoryRequest data) async {
    final res = await Http.get('/api/v1/chat/messages', query: data.toJson());
    return MessageListResponse.fromJson(res);
  }

  // 发送消息
  static Future<ChatMessage> sendMessage(String conversationId, String content, int type, String tempId) async {
    final res = await Http.post('/api/v1/chat/message', data: {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'tempId': tempId,
    });

    return ChatMessage.fromJson(res);
  }

  // 标记消息已读
  static Future<MessageMarkReadResponse> messageMarkAsReadApi(MessageMarkReadRequest data) async {
    final res = await Http.post('/api/v1/chat/message/mark-as-read', data: data.toJson());
    return MessageMarkReadResponse.fromJson(res);
  }

  // 撤回消息
  static Future<MessageRecallResponse> messageRecallApi(MessageRecallRequest data) async {
    final res = await Http.post('/api/v1/chat/message/recall', data: data.toJson());
    return MessageRecallResponse.fromJson(res);
  }

  // 删除消息
  static Future<MessageDeleteResponse> messageDeleteApi(MessageDeleteRequest data) async {
    final res = await Http.delete('/api/v1/chat/message/delete', data: data.toJson());
    return MessageDeleteResponse.fromJson(res);
  }

  // 6. 用户搜索
  static Future<List<ChatSender>> chatUsersSearchApi(String keyword) async {
    final res = await Http.get(
      '/api/v1/chat/users/search',
      query: {'keyword': keyword},
    );
    return parseList(res, (e) => ChatSender.fromJson(e));
  }
}
