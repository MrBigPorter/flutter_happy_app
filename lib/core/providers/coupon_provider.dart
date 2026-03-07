import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/user_coupon.dart';

import '../store/auth/auth_provider.dart';

part 'coupon_provider.g.dart';

// =========================================================================
// 1. 数据查询层 (Queries) - 负责 Get 数据
// =========================================================================

/// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
@Riverpod(keepAlive: true)
Future<List<UserCoupon>> myCouponsByStatus(Ref ref, int status) async {

  //直接让底层数据源监听登录状态！
  final isAuthenticated = ref.watch(authProvider.select((s) => s.isAuthenticated));
  // 如果没登录，直接拦截！返回空数组，绝对不浪费网络请求去报错
  if (!isAuthenticated) return [];

  final res = await Api.myCouponsApi(status: status, page: 1, pageSize: 100);
  return res.list;
}

/// 魔法就在这里：它不自己发请求，而是去监听核心 Provider！
/// 这样既做到了 0 冗余代码，又让首页和独立管理页【共享同一个数据缓存】
@Riverpod(keepAlive: true)
Future<List<UserCoupon>> myValidCoupons(Ref ref) async {
  // 直接拿到 status = 0 的 future，底层只会触发一次 HTTP 请求
  return ref.watch(myCouponsByStatusProvider(0).future);
}

/// 结算页：获取当前订单【满足门槛】的可用优惠券
@riverpod
Future<List<UserCoupon>> availableCouponsForOrder(Ref ref, double orderAmount) async {
  if (orderAmount <= 0) return [];

  // 内存极速计算 + 官方防抖兜底
  try {
    // 1. 拿取用户所有的可用券（复用之前已经请求好的全量数据，只要进了页面基本就是秒回）
    final allValidCoupons = await ref.watch(myValidCouponsProvider.future);

    // 2. 本地直接判断门槛过滤！0 网络请求，告别菊花转！
    final availableList = allValidCoupons.where((coupon) {
      final minSpend = double.tryParse(coupon.minPurchase) ?? 0.0;
      return orderAmount >= minSpend;
    }).toList();

    return availableList;
  } catch (e) {
    // 3. 极速兜底方案：如果万一没拿到缓存，我们走标准的【Riverpod 防抖网络请求】

    // 设置防抖标志
    var didDispose = false;
    ref.onDispose(() => didDispose = true);

    // 拦截用户狂点，强制等待 500ms
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 如果 500ms 内用户又改了金额，直接丢弃本次废弃的请求，不浪费带宽
    if (didDispose) throw Exception('Request cancelled due to debounce');

    // 用户彻底停手后，才向后端发出唯一一次真实的请求
    final res = await Api.myCouponsApi(
        status: 0,
        orderAmount: orderAmount,
        page: 1,
        pageSize: 50
    );
    return res.list;
  }
}

/// 领券大厅：获取可以领取的券
@riverpod
Future<List<ClaimableCoupon>> claimableCoupons(Ref ref) async {
  return await Api.claimableCouponsApi();
}


// =========================================================================
// 2. 本地状态层 (Local State) - 负责 Apply
// =========================================================================

/// 结算页选中的优惠券 (Apply)
@riverpod
class SelectedCoupon extends _$SelectedCoupon {
  @override
  UserCoupon? build() {
    return null; // 默认没有选中任何券
  }

  void select(UserCoupon? coupon) {
    state = coupon;
  }
}


// =========================================================================
// 3. 动作交互层 (Mutations) - 负责 Claim & Redeem，控制 Loading 状态
// =========================================================================

@riverpod
class CouponAction extends _$CouponAction {
  @override
  FutureOr<void> build() {
    // 初始状态什么都不做
  }

  /// 手动领取优惠券 (Claim)
  Future<String> claim(String couponId) async {
    state = const AsyncValue.loading();
    try {
      final message = await Api.claimCouponApi(couponId);

      ref.invalidate(claimableCouponsProvider);

      ref.invalidate(myCouponsByStatusProvider(0));

      state = const AsyncValue.data(null);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 兑换码兑换 (Redeem)
  Future<String> redeem(String code) async {
    state = const AsyncValue.loading();

    try {
      final message = await Api.redeemCouponApi(code);

      Future.microtask(() => ref.invalidate(myCouponsByStatusProvider(0)));

      return message;
    } catch (e, st) {
      rethrow;
    }
  }
}