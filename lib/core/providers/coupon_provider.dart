import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/user_coupon.dart';

part 'coupon_provider.g.dart';

// =========================================================================
// 1. 数据查询层 (Queries) - 负责 Get 数据
// =========================================================================

/// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
@Riverpod(keepAlive: true)
Future<List<UserCoupon>> myCouponsByStatus(Ref ref, int status) async {
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
  final res = await Api.myCouponsApi(status: 0, orderAmount: orderAmount, page: 1, pageSize: 50);
  return res.list;
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