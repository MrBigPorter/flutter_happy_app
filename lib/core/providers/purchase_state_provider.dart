import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/api/lucky_api.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/config_store.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/time/server_time_helper.dart';

import 'package:flutter_app/core/providers/coupon_provider.dart';

// ==========================================
// 0. 初始化提示存储（非 Riverpod，initState 安全写入）
// ==========================================
/// Payment 页面在 initState 中同步写入 isGroupBuy，purchaseProvider factory 读取，
/// 确保 Provider 首次创建时就使用正确的 isGroupBuy，避免首帧价格闪烁。
/// 这只是一个普通 Dart Map，不触发 Riverpod 的 build 阶段检查。
class PurchaseInitConfig {
  PurchaseInitConfig._();
  static final Map<String, bool> _groupMode = {};
  static void setGroupMode(String id, bool isGroup) => _groupMode[id] = isGroup;
  static bool getGroupMode(String id) => _groupMode[id] ?? true;
}

// ==========================================
// 1. State 改造：使用 Getter 派生价格，杜绝数据不同步
// ==========================================
class PurchaseState {
  final int entries;

  // 分别缓存两种价格，作为底层数据源
  final double baseGroupPrice;
  final double baseSoloPrice;

  final bool isGroupBuy; // 当前模式：拼团 (true) / 单买 (false)

  final double maxUnitCoins;
  final int maxPerBuyQuantity;
  final int minBuyQuantity;
  final int stockLeft;
  final bool useDiscountCoins;
  final bool isSubmitting;

  final int? salesStartAt;
  final int? salesEndAt;
  final int productState;

  /// True when this purchase is for a flash sale (price has been overridden)
  final bool isFlashSale;

  PurchaseState({
    required this.entries,
    required this.baseGroupPrice,
    required this.baseSoloPrice,
    required this.isGroupBuy,
    required this.maxUnitCoins,
    required this.maxPerBuyQuantity,
    required this.minBuyQuantity,
    required this.stockLeft,
    required this.useDiscountCoins,
    required this.isSubmitting,
    this.salesStartAt,
    this.salesEndAt,
    this.productState = 1,
    this.isFlashSale = false,
  });

  //  核心修复 1：将 unitAmount 变成动态计算的 Getter
  // 无论后台接口什么时候回来，或者怎么切模式，当前单价永远正确！
  double get unitAmount {
    if (isGroupBuy) return baseGroupPrice;

    // 如果是单买：优先用后端的单买价，如果没有，强制兜底为拼团价的 1.5 倍
    if (baseSoloPrice > 0) return baseSoloPrice;
    return baseGroupPrice * 1.5;
  }

  //  核心修复 2：小计自动使用上面算出的绝对正确单价
  double get subtotal => unitAmount * entries;

  /// UI 用：- 按钮是否可点击（entries > min 时才能减）
  bool get canDecrement => entries > _minEntriesAllowed;

  /// UI 用：+ 按钮是否可点击（entries < max 时才能加）
  bool get canIncrement => entries < _maxEntriesAllowed;

  int get _maxEntriesAllowed {
    if (!isStockLoaded) {
      // 库存未确认（哨兵 999）：不用 stockLeft 作为 max，避免显示或允许输入 999
      // 如果 maxPerBuyQuantity 已从 detail 加载则使用，否则用合理默认值 99
      return maxPerBuyQuantity > 0 ? maxPerBuyQuantity : 99;
    }
    if (stockLeft <= 0) return 0;
    final maxByLimit = maxPerBuyQuantity <= 0 ? stockLeft : maxPerBuyQuantity;
    return math.max(1, math.min(stockLeft, maxByLimit));
  }

  int get _minEntriesAllowed {
    if (!isStockLoaded) {
      // 库存未确认时：最小值为 1，不强制 minBuyQuantity（等数据加载后 _clampEntries 自动修正）
      return 1;
    }
    if (stockLeft <= 0) return 0;
    final minByConfig = minBuyQuantity <= 0 ? 1 : minBuyQuantity;
    return math.min(minByConfig, stockLeft);
  }

  double get theoreticalMaxCoins {
    if (!useDiscountCoins) return 0;
    return maxUnitCoins * entries;
  }

  /// true = productRealtimeStatusProvider 已加载，stockLeft 是真实值
  /// false = 仍是哨兵值 999（未确认），前端不应据此判断售罄
  bool get isStockLoaded => stockLeft < 999;

  PurchaseState copyWith({
    int? entries,
    int? stockLeft,
    double? baseGroupPrice,
    double? baseSoloPrice,
    bool? isGroupBuy,
    bool? useDiscountCoins,
    bool? isSubmitting,
    int? maxPerBuyQuantity,
    int? minBuyQuantity,
    int? productState,
    bool? isFlashSale,
  }) {
    return PurchaseState(
      entries: entries ?? this.entries,
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
      isFlashSale: isFlashSale ?? this.isFlashSale,
    );
  }
}

enum PurchaseSubmitError {
  none, needLogin, insufficientBalance, insufficientStock,
  purchaseLimitExceeded, soldOut, unknown, preSaleNotStarted,
  salesEnded, productOffline, needKyc, noAddress,
}

class PurchaseSubmitResult {
  final bool ok;
  final PurchaseSubmitError error;
  final String? message;
  final OrderCheckoutResponse? data;

  const PurchaseSubmitResult._(this.ok, this.error, this.message, [this.data]);

  factory PurchaseSubmitResult.ok(data) => PurchaseSubmitResult._(true, PurchaseSubmitError.none, null, data);
  factory PurchaseSubmitResult.error(PurchaseSubmitError error, {String? message}) => PurchaseSubmitResult._(false, error, message);
}

// ==========================================
// 2. Notifier：彻底清爽，只管改模式和存数据
// ==========================================
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

  //  核心修复 3：切模式时，只需要改 isGroupBuy 标识，不用再手动算价了！
  void setGroupMode(bool isGroup) {
    if (state.isGroupBuy == isGroup) return; // 同值无需更新，避免多余 rebuild
    state = state.copyWith(isGroupBuy: isGroup);
    _clampEntries();
  }

  /// Override price for flash sale: sets both group/solo prices to flash price,
  /// forces solo mode, and marks state as flash sale so UI can render accordingly.
  void overrideWithFlashPrice(double flashPrice) {
    state = state.copyWith(
      baseGroupPrice: flashPrice,
      baseSoloPrice: flashPrice,
      isGroupBuy: false,
      isFlashSale: true,
    );
    _clampEntries();
  }

  void _listenToProductUpdates() {
    // ── 实时状态（权威来源：库存 + 上架状态）──────────────────────────────
    // ⚠️ 注意：productRealtimeStatusProvider.price 是「商品市场价」（如 8500），
    //         不是「彩票单价」（如 58）。彩票单价只来自 productDetailProvider.unitAmount。
    //         所以这里 ** 绝对不能 ** 更新 baseGroupPrice / baseSoloPrice！
    ref.listen(productRealtimeStatusProvider(treasureId), (prev, next) {
      next.whenData((status) {
        state = state.copyWith(
          stockLeft: status.stock,
          productState: status.state,
          // 价格字段意图保留：保持 Flash Sale override 不变
        );
        _clampEntries();
      });
    });

    // ── 商品详情（价格权威来源：unitAmount = 拼团彩票单价，soloAmount = 单买彩票单价）
    ref.listen(productDetailProvider(treasureId), (prev, next) {
      next.whenData((detail) {
        if (state.isFlashSale) return; // Flash sale override 期间禁止被详情覆盖
        final newGroupPrice = detail.unitAmount ?? 0.0;
        final newSoloPrice = detail.soloAmount ?? (newGroupPrice * 1.5);

        state = state.copyWith(
          // 只在当前值为 0（未初始化）时才写入，避免重复 re-fetch 时覆盖已正确的值
          baseGroupPrice: state.baseGroupPrice > 0 ? state.baseGroupPrice : newGroupPrice,
          baseSoloPrice: state.baseSoloPrice > 0 ? state.baseSoloPrice : newSoloPrice,
          maxPerBuyQuantity: JsonNumConverter.toInt(detail.maxPerBuyQuantity ?? 0),
          minBuyQuantity: detail.minBuyQuantity ?? 1,
        );
        // 只有实时库存已确认（非哨兵值 999）时才 clamp，避免用旧 stock=0 把 entries 清零
        if (state.stockLeft < 999) {
          _clampEntries();
        }
      });
    });
  }

  void _clampEntries() {
    final min = state._minEntriesAllowed;
    final max = state._maxEntriesAllowed;
    final safeEntries = state.entries.clamp(min, max);
    if (safeEntries != state.entries) {
      state = state.copyWith(entries: safeEntries);
    }
  }

  void resetEntries(int targetEntries) {
    state = state.copyWith(entries: targetEntries);
    _clampEntries();
  }

  // Getters
  double get _balanceCoins => ref.read(walletProvider).coinBalance;
  double get _realBalance => ref.read(walletProvider).realBalance;
  double get _exchangeRate => ref.read(configProvider).exchangeRate;
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
    double currentSubtotal = state.subtotal;

    final selectedCoupon = ref.read(selectedCouponProvider);
    if (selectedCoupon != null) {
      final discount = double.tryParse(selectedCoupon.discountValue) ?? 0.0;
      currentSubtotal = (currentSubtotal - discount).clamp(0.0, double.infinity);
    }

    if (!state.useDiscountCoins) return currentSubtotal;
    final raw = currentSubtotal - coinAmount;
    return raw <= 0 ? 0.0 : raw;
  }

  Future<PurchaseSubmitResult> submitOrder({
    String? groupId,
    String? couponId,
    String? flashSaleProductId,
  }) async {
    if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);
    if (state.isSubmitting) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

    if (!_isAuthenticated) return PurchaseSubmitResult.error(PurchaseSubmitError.needLogin);
    // ✅ 只有库存已从实时状态确认（非哨兵 999）才做前端售罄拦截
    //    若库存未加载，放行让后端校验，避免误判 soldOut → "Payment Failed"
    if (state.isStockLoaded && state.stockLeft <= 0) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.soldOut);
    }
    if (state.productState != 1) return PurchaseSubmitResult.error(PurchaseSubmitError.productOffline);

    final now = ServerTimeHelper.nowMilliseconds;
    if (state.salesStartAt != null && state.salesStartAt! > now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.preSaleNotStarted, message: 'Pre-sale has not started yet.');
    }
    if (state.salesEndAt != null && state.salesEndAt! < now) {
      return PurchaseSubmitResult.error(PurchaseSubmitError.salesEnded, message: 'Sales have ended.');
    }

    // ── KYC Check: local cache first, refresh from backend if stale ──
    final localKycStatus = ref.read(userProvider.select((s) => s?.kycStatus));
    if (KycStatusEnum.fromStatus(localKycStatus ?? 0) == KycStatusEnum.approved) {
      // Local cache says approved — skip API call
    } else {
      // Local cache is stale — fetch fresh status from backend
      try {
        final freshKyc = await Api.kycMeApi();
        if (freshKyc.kycStatus != KycStatusEnum.approved.status) {
          return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
        }
        // Backend says approved — fire-and-forget profile refresh to update local cache
        ref.read(userProvider.notifier).fetchProfile();
      } catch (_) {
        // API failed — safe fallback: show verify prompt
        return PurchaseSubmitResult.error(PurchaseSubmitError.needKyc);
      }
    }
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

      final orderCheckoutResult = await ref.read(
        orderCheckoutProvider(
          OrdersCheckoutParams(
            treasureId: treasureId,
            entries: state.entries,
            paymentMethod: state.useDiscountCoins ? 2 : 1,
            groupId: groupId,
            flashSaleProductId: flashSaleProductId,
            isGroup: state.isGroupBuy, // 这里取的值现在永远是对的！
            couponId: couponId,
          ),
        ).future,
      );

      if (!mounted) return PurchaseSubmitResult.error(PurchaseSubmitError.unknown);

      ref.read(selectedCouponProvider.notifier).select(null);
      ref.read(walletProvider.notifier).fetchBalance();
      ref.invalidate(productRealtimeStatusProvider(treasureId));

      return PurchaseSubmitResult.ok(orderCheckoutResult);
    } catch (e) {
      // 提取后端返回的真实错误信息（DioException.message 由 UnifiedInterceptor 注入）
      String msg = 'Payment Failed';
      if (e is DioException && (e.message?.isNotEmpty ?? false)) {
        msg = e.message!;
      }
      debugPrint('[Purchase] submitOrder error: $e');
      return PurchaseSubmitResult.error(PurchaseSubmitError.unknown, message: msg);
    } finally {
      if (mounted) state = state.copyWith(isSubmitting: false);
    }
  }

  void inc(Function(int)? onChanged) {
    final max = state._maxEntriesAllowed;
    if (state.entries >= max) return;
    state = state.copyWith(entries: state.entries + 1);
    onChanged?.call(state.entries);
  }

  void dec(Function(int)? onChanged) {
    final min = state._minEntriesAllowed;
    if (state.entries <= min) return;
    state = state.copyWith(entries: state.entries - 1);
    onChanged?.call(state.entries);
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

  final detail = ref.read(productDetailProvider(id)).valueOrNull;
  final status = ref.read(productRealtimeStatusProvider(id)).valueOrNull;

  // ✅ 价格只来自商品详情（productDetailProvider.unitAmount = 彩票单价 58）
  //    绝不使用 status.price（它是商品市场价 8500，不是彩票票价）
  final groupPrice = detail?.unitAmount ?? 0.0;
  final soloPrice = detail?.soloAmount ?? (groupPrice * 1.5);

  // ✅ 库存只来自实时状态。detail 的 seqShelvesQuantity/seqBuyQuantity 通常为 0
  //    （API 不返回或字段含义不同），用它们会误判"已售罄"，导致 Payment Failed
  //    未加载时用哨兵值 999，submitOrder 检测到 999 时跳过前端校验，由后端兜底
  final int? confirmedStock = status?.stock;

  final productState = status?.state ?? (detail?.state ?? 1);
  final minBuy = detail?.minBuyQuantity ?? 1;

  // ✅ 默认 1 份，不使用 minBuyQuantity 作为初始值
  // 理由：minBuyQuantity 是"最少购买"约束，不是"默认显示"值
  //       若用 minBuy 初始化，当 minBuyQuantity=50 时用户一进来就看到 50，体验差
  // 正确做法：始终从 1 开始，实时状态加载后 _clampEntries 会自动修正到 [min, max] 范围
  // 若 URL 携带 entries 参数，addPostFrameCallback 里的 resetEntries() 会覆盖此初始值
  const initialEntries = 1;

  final initialState = PurchaseState(
    entries: initialEntries,
    baseGroupPrice: groupPrice,
    baseSoloPrice: soloPrice,
    isGroupBuy: PurchaseInitConfig.getGroupMode(id),
    maxUnitCoins: JsonNumConverter.toDouble(detail?.maxUnitCoins),
    maxPerBuyQuantity: JsonNumConverter.toInt(detail?.maxPerBuyQuantity ?? 0),
    minBuyQuantity: minBuy,
    stockLeft: confirmedStock ?? 999, // 999 = 哨兵，表示"库存未确认"
    useDiscountCoins: false,
    isSubmitting: false,
    salesStartAt: detail?.salesStartAt,
    salesEndAt: detail?.salesEndAt,
    productState: productState,
  );

  return PurchaseNotifier(ref: ref, treasureId: id, state: initialState);
});