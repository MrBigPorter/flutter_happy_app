import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/payment/payment_section.dart';
import 'package:flutter_app/app/page/payment/payment_skeleton.dart';
import 'package:flutter_app/app/page/payment_components/insufficient_balance_sheet.dart';
import 'package:flutter_app/app/page/payment_components/payment_success_sheet.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/guards/kyc_guard.dart';

class _GroupTipsBar extends StatelessWidget {
  final bool isJoin;

  const _GroupTipsBar({required this.isJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7E6),
        border: Border(bottom: BorderSide(color: Color(0xFFFFD591))),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isJoin
                  ? "You are joining a group. Order will be confirmed after payment."
                  : "You are starting a group. Invite friends after payment.",
              style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentPage extends ConsumerStatefulWidget {
  final PagePaymentParams params;

  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = ref.read(authProvider.select((state) => state.isAuthenticated));
      if (!isAuthenticated) return;

      ref.read(luckyProvider.notifier).updateWalletBalance();

      final treasureId = widget.params.treasureId;
      if (treasureId != null) {
        ref.invalidate(productDetailProvider(treasureId));
        ref.refresh(productRealtimeStatusProvider(treasureId));

        final action = ref.read(purchaseProvider(treasureId).notifier);

        //  [关键修复] 解析参数并设置模式
        // 注意：URL 传过来的 bool 可能是字符串 'true'/'false'，需要兼容处理
        final rawIsGroup = widget.params.isGroupBuy;
        final bool isGroup = rawIsGroup == true || rawIsGroup.toString().toLowerCase() == 'true';

        // ️ 必须调用这个方法！否则 Provider 默认使用拼团价
        action.setGroupMode(isGroup);

        if (widget.params.entries != null) {
          final entries = int.tryParse(widget.params.entries!) ?? 1;
          action.resetEntries(entries);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;

    // 解析状态用于 UI 显示
    final rawIsGroup = params.isGroupBuy;
    final isGroupBuy = rawIsGroup == true || rawIsGroup.toString().toLowerCase() == 'true';
    final isJoinGroup = params.groupId != null && params.groupId!.isNotEmpty;

    if (params.treasureId == null) return const PaymentSkeleton();

    final detail = ref.watch(productDetailProvider(params.treasureId!));

    return detail.when(
      loading: () => const PaymentSkeleton(),
      error: (_, __) => const PaymentSkeleton(),
      data: (value) {
        return BaseScaffold(
          title: 'checkout'.tr(),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constrains) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constrains.maxHeight),
                    child: Column(
                      children: [
                        // 只有是拼团模式才显示提示条
                        if (isGroupBuy)
                          _GroupTipsBar(isJoin: isJoinGroup),

                        const AddressSection(),
                        SizedBox(height: 8.w),
                        ProductSection(detail: value),
                        SizedBox(height: 8.w),
                        InfoSection(detail: value, treasureId: params.treasureId!),
                        SizedBox(height: 8.w),
                        VoucherSection(treasureId: params.treasureId!),
                        SizedBox(height: 8.w),
                        PaymentMethodSection(treasureId: params.treasureId!),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: _BottomNavigationBar(
            params: params,
            title: value.treasureName ?? '',
            isGroupBuy: isGroupBuy,
          ),
        );
      },
    );
  }
}

// ... _BottomNavigationBar 保持不变 (记得确保 submitPayment 逻辑正确) ...
class _BottomNavigationBar extends ConsumerStatefulWidget {
  final String title;
  final PagePaymentParams params;
  final bool isGroupBuy;

  const _BottomNavigationBar({
    required this.params,
    required this.title,
    required this.isGroupBuy,
  });

  @override
  ConsumerState<_BottomNavigationBar> createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends ConsumerState<_BottomNavigationBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  void submitPayment() async {
    final treasureId = widget.params.treasureId ?? '';
    if (treasureId.isEmpty) return;

    final action = ref.read(purchaseProvider(treasureId).notifier);

    // 提交订单 (带上 groupId)
    // 注意：Provider 内部已经通过 setGroupMode 更新了 isGroupBuy 状态
    // submitOrder 会自动读取 state.isGroupBuy 传给后端
    final result = await action.submitOrder(groupId: widget.params.groupId);

    if (!mounted) return;

    if (!result.ok) {
      _handlePaymentError(result.error);
      return;
    }

    // 成功跳转
    if (widget.isGroupBuy) {
      final targetGroupId = result.data?.groupId ?? widget.params.groupId;
      if (targetGroupId != null) {
        appRouter.pushReplacement('/group-room?groupId=$targetGroupId');
        return;
      }
    }

    RadixSheet.show(
      builder: (context, close) {
        return PaymentSuccessSheet(
          title: widget.title,
          purchaseResponse: result.data!,
          onClose: () {
            close();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        );
      },
    );
  }

  void _handlePaymentError(PurchaseSubmitError? error) {
    // ... 保持原有错误处理 ...
    switch (error) {
      case PurchaseSubmitError.needLogin:
        appRouter.pushNamed('login');
        break;
      case PurchaseSubmitError.needKyc:
        KycGuard.ensure(context: context, ref: ref, onApproved: () {});
        break;
      case PurchaseSubmitError.noAddress:
        RadixToast.error('please.add.delivery.address'.tr());
        break;
      case PurchaseSubmitError.insufficientBalance:
        RadixSheet.show(
          config: const ModalSheetConfig(enableHeader: false),
          builder: (context, close) => InsufficientBalanceSheet(close: close),
        );
        break;
      case PurchaseSubmitError.soldOut:
        RadixToast.error('Sold Out');
        break;
      case PurchaseSubmitError.purchaseLimitExceeded:
        RadixToast.error('purchase.limit.exceeded'.tr());
        break;
      default:
        RadixToast.error('Unknown Error');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut, reverseCurve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 purchaseProvider 获取计算后的金额
    final notifier = ref.read(purchaseProvider(widget.params.treasureId ?? '').notifier);
    final purchase = ref.watch(purchaseProvider(widget.params.treasureId ?? ''));
    final addressListAsync = ref.watch(addressListProvider);

    final isBusy = purchase.isSubmitting || (addressListAsync.isLoading && !addressListAsync.hasValue);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: child)),
      child: Container(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w, bottom: ViewUtils.bottomBarHeight + (kIsWeb ? 16.w : 0)),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          boxShadow: [BoxShadow(color: context.shadowMd01.withValues(alpha: 0.1), blurRadius: 10.w, offset: Offset(0, -1.w))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${'common.total'.tr()}: ', style: TextStyle(color: context.textPrimary900, fontSize: context.textSm, fontWeight: FontWeight.w600)),
                    //  这里显示的是 notifier.payableAmount，它依赖于 setGroupMode 是否正确被调用
                    TextSpan(
                      text: FormatHelper.formatCurrency(notifier.payableAmount),
                      style: TextStyle(color: context.textErrorPrimary600, fontSize: context.textLg, fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
                SizedBox(height: 8.w),
                if (purchase.useDiscountCoins)
                  Text(
                    '${'common.total.discount'.tr()} ${FormatHelper.formatCurrency(notifier.coinAmount)}',
                    style: TextStyle(color: context.textErrorPrimary600, fontSize: context.textSm, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Button(
              width: 120.w,
              height: 40.h,
              loading: isBusy,
              onPressed: submitPayment,
              child: Text('common.checkout'.tr(), style: TextStyle(color: Colors.white, fontSize: context.textMd, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}