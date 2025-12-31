import 'dart:math' as math;
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart'; // productDetailProvider
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/time/server_time_helper.dart';
import '../store/lucky_store.dart';

class PurchaseState {
  final int entries; // 用户当前选择的份数
  final double unitAmount; // 单价 (可能是秒杀价)
  final double maxUnitCoins; // 单份最大可用金币
  final int maxPerBuyQuantity; // 限购
  final int minBuyQuantity; // 起购
  final int stockLeft; // 剩余库存
  final bool useDiscountCoins; // 是否使用金币抵扣
  final bool isSubmitting; // 提交中状态

  // ✨ 新增：时间控制字段，用于提交时校验
  final int? salesStartAt;
  final int? salesEndAt;
  final int productState; // 1=上架



  PurchaseState({
    required this.entries,
    required this.unitAmount,
    required this.maxUnitCoins,
    required this.maxPerBuyQuantity,
    required this.minBuyQuantity,
    required this.stockLeft,
    required this.useDiscountCoins,
    required this.isSubmitting,
    this.salesStartAt,
    this.salesEndAt,
    this.productState = 1,
  });

  /// 最大可买份数
  int get _maxEntriesAllowed {
    if (stockLeft <= 0) return 0;
    // 如果限购为0或空，则以库存为准
    final maxByLimit = maxPerBuyQuantity <= 0 ? stockLeft : maxPerBuyQuantity;
    return math.max(1, math.min(stockLeft, maxByLimit));
  }

  /// 最小可买份数
  int get _minEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final minByConfig = minBuyQuantity <= 0 ? 1 : minBuyQuantity;
    return math.min(minByConfig, stockLeft);
  }

  /// 小计金额（PHP）
  double get subtotal => unitAmount * entries;

  /// 理论最大可用金币
  double get theoreticalMaxCoins {
    if (!useDiscountCoins) return 0;
    return maxUnitCoins * entries;
  }

  PurchaseState copyWith({
    int? entries,
    int? stockLeft,
    double? unitAmount,
    bool? useDiscountCoins,
    bool? isSubmitting,
    // 允许更新配置
    int? maxPerBuyQuantity,
    int? minBuyQuantity,
    int? productState,
  }) {
    return PurchaseState(
      entries: entries ?? this.entries,
      unitAmount: unitAmount ?? this.unitAmount,
      maxUnitCoins: maxUnitCoins, // 通常不变
      maxPerBuyQuantity: maxPerBuyQuantity ?? this.maxPerBuyQuantity,
      minBuyQuantity: minBuyQuantity ?? this.minBuyQuantity,
      stockLeft: stockLeft ?? this.stockLeft,
      useDiscountCoins: useDiscountCoins ?? this.useDiscountCoins,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      salesStartAt: salesStartAt, // 这种字段通常初始化后很少变，暂不开放 copyWith
      salesEndAt: salesEndAt,
      productState: productState ?? this.productState,
    );
  }
}

enum PurchaseSubmitError {
  none,
  needLogin,
  insufficientBalance,
  insufficientStock,
  purchaseLimitExceeded,
  soldOut,
  unknown,
  // ✨ 新增错误类型
  preSaleNotStarted,
  salesEnded,
  productOffline,

  // 🚨 补回这两个业务错误
  needKyc,      // 需要 KYC 认证
  noAddress,    // 需要收货地址 (之前你的注释里也有这个，建议一起补上)
}

class PurchaseSubmitResult {
  final bool ok;
  final PurchaseSubmitError error;
  final String? message;
  final OrderCheckoutResponse? data;

  const PurchaseSubmitResult._(this.ok, this.error, this.message, [this.data]);

  factory PurchaseSubmitResult.ok(data) =>
      PurchaseSubmitResult._(true, PurchaseSubmitError.none, null, data);

  factory PurchaseSubmitResult.error(PurchaseSubmitError error, {String? message}) =>
      PurchaseSubmitResult._(false, error, message);
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final Ref ref;
  final String treasureId;

  PurchaseNotifier({
    required this.ref,
    required this.treasureId,
    required PurchaseState state,
  }) : super(state) {
    _listenToProductUpdates();
  }

  /// 场景：用户停留在详情页，此时库存变动，或者商品下架
  void _listenToProductUpdates() {
    // 使用 listen 而不是 read，确保后续更新能收到
    ref.listen(productDetailProvider(treasureId), (prev, next) {
      next.whenData((detail) {
        if (detail == null) return;

        final newStock = (detail.seqShelvesQuantity ?? 0) - (detail.seqBuyQuantity ?? 0);

        // 只有当关键数据变化时才更新 state，避免不必要的重绘
        if (newStock != state.stockLeft ||
            detail.state != state.productState ||
            detail.unitAmount != state.unitAmount) {

          // 智能处理 entries：如果当前选的份数超过了新库存，才强制调小
          // 否则保持用户输入的份数不变
          final currentEntries = state.entries;
          final maxAllowed = math.min(newStock, state.maxPerBuyQuantity > 0 ? state.maxPerBuyQuantity : newStock);
          final safeEntries = math.min(currentEntries, math.max(1, maxAllowed));

          state = state.copyWith(
            stockLeft: newStock,
            entries: safeEntries,
            unitAmount: detail.unitAmount, // 支持秒杀价格变动
            productState: detail.state,
          );
        }
      });
    });
  }

  /// 手动重置份数
  void resetEntries(int targetEntries) {
    // 1. 获取当前允许的最小和最大值
    final min = state._minEntriesAllowed;
    final max = state._maxEntriesAllowed;

    // 2. 确保目标值在合法范围内 (clamp)
    final next = targetEntries.clamp(min, max);

    // 3. 更新状态
    state = state.copyWith(entries: next);
  }

  // Getters 保持不变
  double get _balanceCoins => ref.read(luckyProvider).balance.coinBalance;
  double get _realBalance => ref.read(luckyProvider).balance.realBalance;
  double get _exchangeRate => ref.read(luckyProvider).sysConfig.exChangeRate;
  bool get _isAuthenticated => ref.read(authProvider).isAuthenticated;

  double get coinsCanUse {
    if (!state.useDiscountCoins) return 0.0;
    final maxByRule = state.theoreticalMaxCoins;
    if (!_isAuthenticated) return maxByRule;
    return math.max(0.0, math.min(maxByRule, _balanceCoins));
  }

  double get coinAmount {
    final rate = _exchangeRate;
    if (!state.useDiscountCoins || rate <= 0) return 0.0;
    return coinsCanUse / rate;
  }

  double get payableAmount {
    if (!state.useDiscountCoins) return state.subtotal;
    final raw = state.subtotal - coinAmount;
    return raw <= 0 ? 0.0 : raw;
  }

  Future<PurchaseSubmitResult> submitOrder({String? groupId}) async {
    if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

    // 1. 基础校验
    if (!_isAuthenticated) return PurchaseSubmitResult.error(PurchaseSubmitError.needLogin);
    if (state.stockLeft <= 0) return PurchaseSubmitResult.error(PurchaseSubmitError.soldOut);
    if (state.productState != 1) return PurchaseSubmitResult.error(PurchaseSubmitError.productOffline);

    // 2. ✨ 时间/状态校验 (核心防御)
    final now = ServerTimeHelper.nowMilliseconds;

    // 预售拦截
    if (state.salesStartAt != null && state.salesStartAt! > now) {
      return PurchaseSubmitResult.error(
          PurchaseSubmitError.preSaleNotStarted,
          message: 'Pre-sale has not started yet.'
      );
    }

    // 过期拦截
    if (state.salesEndAt != null && state.salesEndAt! < now) {
      return PurchaseSubmitResult.error(
          PurchaseSubmitError.salesEnded,
          message: 'Sales have ended.'
      );
    }

    // ---------------------------------------------------------
    // 🚨 4. 补回 KYC 和 地址 校验 (关键业务风控)
    // ---------------------------------------------------------
    final luckyStore = ref.read(luckyProvider);
    final sysConfig = luckyStore.sysConfig;
    final user = luckyStore.userInfo;

    // 检查是否开启了强制 KYC (假设配置值为 '1' 代表开启)
    if (sysConfig.kycAndPhoneVerification == '1') {
      // 根据你的 Prisma Schema，4 代表已认证 (0-未认证, 1-审核中, 2-失败, 3-补充, 4-已通过)
      if (user?.kycStatus != 4) {
        return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
      }
    }

    // (可选) 检查是否需要收货地址 - 如果你的业务要求下单前必须有地址
    /*if (sysConfig.forceAddressBeforeOrder == '1') {
       // 这里可能需要去 addressProvider 查一下列表，或者 userInfo 里有 defaultAddressId
       if (user?.deliveryAddressId == null) {
          return PurchaseSubmitResult.error(PurchaseSubmitError.noAddress);
       }
    }*/


    // 3. 限购校验
    if (state.entries > state._maxEntriesAllowed) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.purchaseLimitExceeded);
    }

    // 4. 余额校验
    if (_realBalance < payableAmount) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.insufficientBalance);
    }

    try {
      state = state.copyWith(isSubmitting: true);

      final orderCheckoutResult = await ref.read(
        orderCheckoutProvider(
          OrdersCheckoutParams(
            treasureId: treasureId,
            entries: state.entries,
            paymentMethod: state.useDiscountCoins ? 2 : 1, // 1=Cash, 2=Hybrid/Coin
            groupId: groupId,
          ),
        ).future,
      );

      if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

      // 成功后刷新余额
      ref.read(luckyProvider.notifier).updateWalletBalance();
      // 成功后最好也刷新一下当前商品详情，确保库存显示最新
      ref.invalidate(productDetailProvider(treasureId));

      return PurchaseSubmitResult.ok(orderCheckoutResult);
    } catch (e) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.unknown, message: e.toString());
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

  // 步进器逻辑保持不变
  void inc(Function(int)? onChanged) {
    final max = state._maxEntriesAllowed;
    if (state.entries >= max) return;

    final next = state.entries + 1;
    state = state.copyWith(entries: next);
    onChanged?.call(next);
  }

  void dec(Function(int)? onChanged) {
    final min = state._minEntriesAllowed;
    if (state.entries <= min) return;

    final next = state.entries - 1;
    state = state.copyWith(entries: next);
    onChanged?.call(next);
  }

  void setEntriesFromText(String v) {
    // 过滤非数字
    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;

    int n = int.tryParse(clean) ?? state.minBuyQuantity;

    // 限制范围
    n = n.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);

    state = state.copyWith(entries: n);
  }

  void toggleUseDiscountCoins(bool use) {
    state = state.copyWith(useDiscountCoins: use);
  }
}

// ✨ 优化 Provider 定义：使用 autoDispose 并在初始化时处理异步数据
final purchaseProvider = StateNotifierProvider.family.autoDispose<PurchaseNotifier, PurchaseState, String>((ref, id) {

  // 1. 这里使用 watch，确保如果详情页 ID 变了，或者 Provider 重置了，能拿到最新数据
  // 注意：我们这里拿的是 valueOrNull，因为详情页 UI 肯定会由外层的 AsyncValue.when 包裹
  // 所以当代码执行到这里时，数据通常已经有了。
  final detail = ref.watch(productDetailProvider(id)).valueOrNull;

  final stockLeft = (detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0);
  final minBuy = detail?.minBuyQuantity ?? 1;

  // 2. 初始化状态
  final initialState = PurchaseState(
    entries: stockLeft > 0 ? minBuy : 0,
    unitAmount: detail?.unitAmount ?? 0.0,
    maxUnitCoins: JsonNumConverter.toDouble(detail?.maxUnitCoins),
    maxPerBuyQuantity: JsonNumConverter.toInt(detail?.maxPerBuyQuantity ?? 0), // 0代表不限
    minBuyQuantity: minBuy,
    stockLeft: stockLeft,
    useDiscountCoins: true,
    isSubmitting: false,
    // 注入时间字段
    salesStartAt: detail?.salesStartAt,
    salesEndAt: detail?.salesEndAt,
    productState: detail?.state ?? 1,
  );

  return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
});