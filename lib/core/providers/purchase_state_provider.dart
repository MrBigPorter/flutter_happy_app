import 'dart:math' as math;
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/time/server_time_helper.dart';
import '../store/lucky_store.dart';

// ==========================================
// 1. State 改造：增加价格缓存和模式标记
// ==========================================
class PurchaseState {
  final int entries;

  // 🔥 unitAmount 现在表示“当前生效的单价” (可能是拼团价，也可能是单买价)
  // 用于计算 subtotal
  final double unitAmount;

  // 🔥 新增：分别缓存两种价格，以便切换
  final double baseGroupPrice;
  final double baseSoloPrice;
  final bool isGroupBuy; // 当前是否为拼团模式

  final double maxUnitCoins;
  final int maxPerBuyQuantity;
  final int minBuyQuantity;
  final int stockLeft;
  final bool useDiscountCoins;
  final bool isSubmitting;

  final int? salesStartAt;
  final int? salesEndAt;
  final int productState;

  PurchaseState({
    required this.entries,
    required this.unitAmount,
    required this.baseGroupPrice, // New
    required this.baseSoloPrice,  // New
    required this.isGroupBuy,     // New
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

  int get _maxEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final maxByLimit = maxPerBuyQuantity <= 0 ? stockLeft : maxPerBuyQuantity;
    return math.max(1, math.min(stockLeft, maxByLimit));
  }

  int get _minEntriesAllowed {
    if (stockLeft <= 0) return 0;
    final minByConfig = minBuyQuantity <= 0 ? 1 : minBuyQuantity;
    return math.min(minByConfig, stockLeft);
  }

  double get subtotal => unitAmount * entries;

  double get theoreticalMaxCoins {
    if (!useDiscountCoins) return 0;
    return maxUnitCoins * entries;
  }

  PurchaseState copyWith({
    int? entries,
    int? stockLeft,
    double? unitAmount,
    double? baseGroupPrice, // New
    double? baseSoloPrice,  // New
    bool? isGroupBuy,       // New
    bool? useDiscountCoins,
    bool? isSubmitting,
    int? maxPerBuyQuantity,
    int? minBuyQuantity,
    int? productState,
  }) {
    return PurchaseState(
      entries: entries ?? this.entries,
      unitAmount: unitAmount ?? this.unitAmount,
      baseGroupPrice: baseGroupPrice ?? this.baseGroupPrice,
      baseSoloPrice: baseSoloPrice ?? this.baseSoloPrice,
      isGroupBuy: isGroupBuy ?? this.isGroupBuy,
      maxUnitCoins: maxUnitCoins,
      maxPerBuyQuantity: maxPerBuyQuantity ?? this.maxPerBuyQuantity,
      minBuyQuantity: minBuyQuantity ?? this.minBuyQuantity,
      stockLeft: stockLeft ?? this.stockLeft,
      useDiscountCoins: useDiscountCoins ?? this.useDiscountCoins,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      salesStartAt: salesStartAt,
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
  preSaleNotStarted,
  salesEnded,
  productOffline,
  needKyc,
  noAddress,
}

class PurchaseSubmitResult {
  final bool ok;
  final PurchaseSubmitError error;
  final String? message;
  final OrderCheckoutResponse? data;

  const PurchaseSubmitResult._(this.ok, this.error, this.message, [this.data]);

  factory PurchaseSubmitResult.ok(data) =>
      PurchaseSubmitResult._(true, PurchaseSubmitError.none, null, data);

  factory PurchaseSubmitResult.error(
      PurchaseSubmitError error, {
        String? message,
      }) => PurchaseSubmitResult._(false, error, message);
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

  // ==========================================
  // 2. Notifier 改造：增加模式切换
  // ==========================================

  /// 设置购买模式 (下单页初始化时调用)
  void setGroupMode(bool isGroup) {
    // 根据模式选择基础价格
    // 如果单买价未配置(<=0)，兜底使用拼团价 (虽然业务上不应该发生)
    double targetPrice = isGroup ? state.baseGroupPrice : state.baseSoloPrice;
    if (targetPrice <= 0) targetPrice = state.baseGroupPrice;

    state = state.copyWith(
      isGroupBuy: isGroup,
      unitAmount: targetPrice,
    );
  }

  void _listenToProductUpdates() {
    // 1. 监听【实时状态】(Socket/轮询)
    ref.listen(productRealtimeStatusProvider(treasureId), (prev, next) {
      next.whenData((status) {
        final newStock = status.stock;
        final newState = status.state;

        // 获取最新的两种价格
        final newGroupPrice = status.price;
        // 如果实时流里没有 soloPrice (null)，就保留旧的
        final newSoloPrice = status.soloPrice ?? state.baseSoloPrice;

        // 计算当前应该使用的价格
        double newActivePrice = state.unitAmount;
        if (state.isGroupBuy) {
          newActivePrice = newGroupPrice;
        } else {
          // 如果当前是单买模式，且实时流里有有效的单买价，则更新
          // 否则保持当前价格 (避免变成 0)
          if (status.soloPrice != null && status.soloPrice! > 0) {
            newActivePrice = status.soloPrice!;
          }
        }

        if (newStock != state.stockLeft ||
            newState != state.productState ||
            newActivePrice != state.unitAmount ||
            newSoloPrice != state.baseSoloPrice) { // 只要有一个变了就更新

          final currentEntries = state.entries;
          final maxAllowed = math.min(
            newStock,
            state.maxPerBuyQuantity > 0 ? state.maxPerBuyQuantity : newStock,
          );
          final safeEntries = math.min(currentEntries, math.max(1, maxAllowed));

          state = state.copyWith(
            stockLeft: newStock,
            entries: safeEntries,
            unitAmount: newActivePrice,
            baseGroupPrice: newGroupPrice,
            baseSoloPrice: newSoloPrice,
            productState: newState,
          );
        }
      });
    });

    // 2. 监听【静态详情】(API 详情接口)
    //  关键修复：详情加载完成后，必须补充 baseSoloPrice 和 baseGroupPrice
    ref.listen(productDetailProvider(treasureId), (prev, next) {
      next.whenData((detail) {
        bool shouldUpdate = false;

        // 1. 更新限购配置
        final newMaxLimit = JsonNumConverter.toInt(detail.maxPerBuyQuantity ?? 0);
        final newMinLimit = detail.minBuyQuantity ?? 1;

        // 2.  更新基础价格 (防止初始化时 detail 还没回来导致价格为 0)
        double newBaseGroup = state.baseGroupPrice;
        double newBaseSolo = state.baseSoloPrice;

        // 如果当前缓存的价格是 0，且详情里有价格，则更新
        if (newBaseGroup <= 0 && (detail.unitAmount ?? 0) > 0) {
          newBaseGroup = detail.unitAmount!;
          shouldUpdate = true;
        }
        if (newBaseSolo <= 0 && (detail.soloAmount ?? 0) > 0) {
          newBaseSolo = detail.soloAmount!;
          shouldUpdate = true;
        }

        if (newMaxLimit != state.maxPerBuyQuantity ||
            newMinLimit != state.minBuyQuantity ||
            shouldUpdate) {

          final currentEntries = state.entries;
          final currentAuthoritativeStock = state.stockLeft;
          final maxAllowed = math.min(
            currentAuthoritativeStock,
            newMaxLimit > 0 ? newMaxLimit : currentAuthoritativeStock,
          );
          final safeEntries = math.min(currentEntries, math.max(1, maxAllowed));

          // 重新计算当前生效价格 (以防之前因为价格为0导致显示错误)
          double newActivePrice = state.unitAmount;
          if (state.isGroupBuy) {
            if (newBaseGroup > 0) newActivePrice = newBaseGroup;
          } else {
            if (newBaseSolo > 0) newActivePrice = newBaseSolo;
          }

          state = state.copyWith(
            entries: safeEntries,
            maxPerBuyQuantity: newMaxLimit,
            minBuyQuantity: newMinLimit,
            baseGroupPrice: newBaseGroup, // 更新缓存
            baseSoloPrice: newBaseSolo,   // 更新缓存
            unitAmount: newActivePrice,   // 修正当前价格
          );
        }
      });
    });
  }

  void resetEntries(int targetEntries) {
    final min = state._minEntriesAllowed;
    final max = state._maxEntriesAllowed;
    final next = targetEntries.clamp(min, max);
    state = state.copyWith(entries: next);
  }

  // Getters
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
    // 这里的 unitAmount 已经是根据 isGroupBuy 选对的价格了
    if (!state.useDiscountCoins) return state.subtotal;
    final raw = state.subtotal - coinAmount;
    return raw <= 0 ? 0.0 : raw;
  }

  Future<PurchaseSubmitResult> submitOrder({String? groupId}) async {
    if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);
    if (state.isSubmitting) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

    // 校验逻辑
    if (!_isAuthenticated) return PurchaseSubmitResult.error(PurchaseSubmitError.needLogin);
    if (state.stockLeft <= 0) return PurchaseSubmitResult.error(PurchaseSubmitError.soldOut);
    if (state.productState != 1) return PurchaseSubmitResult.error(PurchaseSubmitError.productOffline);

    final now = ServerTimeHelper.nowMilliseconds;
    if (state.salesStartAt != null && state.salesStartAt! > now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.preSaleNotStarted, message: 'Pre-sale has not started yet.');
    }
    if (state.salesEndAt != null && state.salesEndAt! < now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.salesEnded, message: 'Sales have ended.');
    }

    // KYC 校验
    final kycStatus = ref.read(luckyProvider.select((s) => s.userInfo?.kycStatus));
    if (KycStatusEnum.fromStatus(kycStatus ?? 0) != KycStatusEnum.approved) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
    }
    // 地址校验
    final address = await ref.read(selectedAddressProvider);
    if (address == null) return PurchaseSubmitResult.error(PurchaseSubmitError.noAddress);

    if (state.entries > state._maxEntriesAllowed) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.purchaseLimitExceeded);
    }
    if (_realBalance < payableAmount) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.insufficientBalance);
    }

    try {
      state = state.copyWith(isSubmitting: true);

      //  3. 下单改造：传递 isGroup 参数
      final orderCheckoutResult = await ref.read(
        orderCheckoutProvider(
          OrdersCheckoutParams(
            treasureId: treasureId,
            entries: state.entries,
            paymentMethod: state.useDiscountCoins ? 2 : 1,
            groupId: groupId,
            //  新增：告诉后端当前是拼团还是单买 (后端据此扣减不同金额)
            isGroup: state.isGroupBuy,
          ),
        ).future,
      );

      if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

      ref.read(luckyProvider.notifier).updateWalletBalance();
      ref.invalidate(productRealtimeStatusProvider(treasureId));

      return PurchaseSubmitResult.ok(orderCheckoutResult);
    } catch (e) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.unknown, message: e.toString());
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

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
    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    int n = int.tryParse(clean) ?? state.minBuyQuantity;
    n = n.clamp(state._minEntriesAllowed, state._maxEntriesAllowed);
    state = state.copyWith(entries: n);
  }

  void toggleUseDiscountCoins(bool use) {
    state = state.copyWith(useDiscountCoins: use);
  }
}

// ==========================================
// 4. Provider 初始化改造
// ==========================================
final purchaseProvider = StateNotifierProvider.family
    .autoDispose<PurchaseNotifier, PurchaseState, String>((ref, id) {

  //  [关键修复] 把 ref.watch 改为 ref.read
  // 我们不希望当 detail 更新时，Notifier 被销毁重建（那样会丢失用户选的单买模式）
  // 数据的实时更新由 Notifier 内部的 ref.listen 负责
  final detail = ref.read(productDetailProvider(id)).valueOrNull;
  final status = ref.read(productRealtimeStatusProvider(id)).valueOrNull;

  final stockLeft = status?.stock ?? ((detail?.seqShelvesQuantity ?? 0) - (detail?.seqBuyQuantity ?? 0));
  final productState = status?.state ?? (detail?.state ?? 1);
  final minBuy = detail?.minBuyQuantity ?? 1;

  // 提取两种价格
  final groupPrice = status?.price ?? (detail?.unitAmount ?? 0.0);
  final soloPrice = status?.soloPrice ?? (detail?.soloAmount ?? 0.0);

  final initialState = PurchaseState(
    entries: stockLeft > 0 ? minBuy : 0,

    // 默认为拼团价 (因为 isGroupBuy 默认为 true)
    unitAmount: groupPrice,
    baseGroupPrice: groupPrice,
    baseSoloPrice: soloPrice,
    isGroupBuy: true, // 默认模式

    maxUnitCoins: JsonNumConverter.toDouble(detail?.maxUnitCoins),
    maxPerBuyQuantity: JsonNumConverter.toInt(detail?.maxPerBuyQuantity ?? 0),
    minBuyQuantity: minBuy,
    stockLeft: stockLeft,
    useDiscountCoins: true,
    isSubmitting: false,
    salesStartAt: detail?.salesStartAt,
    salesEndAt: detail?.salesEndAt,
    productState: productState,
  );

  return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
});