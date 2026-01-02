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
import 'package:flutter_app/components/kyc_modal.dart';

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

class PaymentPage extends ConsumerStatefulWidget {
  final PagePaymentParams params;

  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = ref.read(
        authProvider.select((state) => state.isAuthenticated),
      );
      if (!isAuthenticated) return;
      // Refresh wallet balance on page load
      ref.read(luckyProvider.notifier).updateWalletBalance();
      // You can also refresh other necessary data here
      final treasureId = widget.params.treasureId;
      if (treasureId != null) {
        // 1. 刷新静态详情
        ref.invalidate(productDetailProvider(treasureId));
        // 新增：强制刷新实时状态！
        // 确保用户进入下单页那一刻，库存和价格是最新的
        ref.refresh(productRealtimeStatusProvider(treasureId));

        //  优化: 将原本在 build 里的初始化份数逻辑移到这里
        // 这样避免了在 build 过程中产生副作用，也防止热重载时数据重置
        final action = ref.read(purchaseProvider(treasureId).notifier);

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

    if (params.treasureId == null) {
      // Handle null treasureId case
      return PaymentSkeleton();
    }

    final detail = ref.watch(productDetailProvider(params.treasureId!));

    return detail.when(
      loading: () => PaymentSkeleton(),
      error: (_, __) => PaymentSkeleton(),
      data: (value) {
        return BaseScaffold(
          title: 'checkout'.tr(),
          // 优化: 加上 GestureDetector，点击空白处收起键盘
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constrains) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constrains.maxHeight,
                    ),
                    child: Column(
                      children: [
                        AddressSection(),
                        SizedBox(height: 8.w),
                        ProductSection(detail: value),
                        SizedBox(height: 8.w),
                        InfoSection(
                          detail: value,
                          treasureId: params.treasureId!,
                        ),
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
            title: value.treasureName,
          ),
        );
      },
    );
  }
}

class _BottomNavigationBar extends ConsumerStatefulWidget {
  final String title;
  final PagePaymentParams params;

  const _BottomNavigationBar({required this.params, required this.title});

  @override
  ConsumerState<_BottomNavigationBar> createState() =>
      _BottomNavigationBarState();
}

class _BottomNavigationBarState extends ConsumerState<_BottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  void submitPayment() async {
    final treasureId = widget.params.treasureId ?? '';
    if (widget.params.treasureId.isNullOrEmpty) return;
    final action = ref.read(purchaseProvider(treasureId).notifier);
    final result = await action.submitOrder(groupId: widget.params.groupId);

    if (!context.mounted) return;

    if (!result.ok) {
      switch (result.error) {
        case PurchaseSubmitError.needLogin:
          appRouter.pushNamed('login');
          break;
        case PurchaseSubmitError.needKyc:
          RadixModal.show(
            title: 'common.modal.kyc.title'.tr(),
            confirmText: 'common.modal.kyc.button'.tr(),
            onConfirm: (_) {
              appRouter.push('/me/kyc/verify');
            },
            cancelText: '',
            builder: (context, close) {
              return KycModal();
            },
          );
          break;
        case PurchaseSubmitError.noAddress:
          RadixToast.error('please.add.delivery.address'.tr());
          break;
        case PurchaseSubmitError.insufficientBalance:
          RadixSheet.show(
            config: ModalSheetConfig(enableHeader: false),
            builder: (context, close) {
              return InsufficientBalanceSheet(close: close);
            },
          );
          break;
        case PurchaseSubmitError.soldOut:
          RadixSheet.show(
            builder: (context, close) {
              return Container(
                height: 180.w,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'treasure.sold.out'.tr(),
                      style: TextStyle(
                        color: context.textPrimary900,
                        fontSize: context.textLg,
                        height: context.leadingLg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12.w),
                    Text(
                      'sorry.this.treasure.is.sold.out'.tr(),
                      style: TextStyle(
                        color: context.textSecondary700,
                        fontSize: context.textMd,
                        height: context.leadingMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Button(
                      width: double.infinity,
                      onPressed: () {
                        close();
                        appRouter.pop();
                      },
                      child: Text(
                        'common.okay'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.textMd,
                          height: context.leadingMd,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          break;
        case PurchaseSubmitError.purchaseLimitExceeded:
          RadixToast.error('purchase.limit.exceeded'.tr());
          break;
        default:
          break;
      }
      return;
    }

    // On success, navigate to order confirmation page
    RadixSheet.show(
      builder: (context, close) {
        return PaymentSuccessSheet(
          title: widget.title,
          purchaseResponse: result.data!,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    /// Animation controller for any future animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      ),
    );

    // start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(
      purchaseProvider(widget.params.treasureId ?? '').notifier,
    );
    final purchase = ref.watch(
      purchaseProvider(widget.params.treasureId ?? ''),
    );

    //  监听地址的变化，以防用户在结算页更改了地址
    final addressListAsync = ref.watch(addressListProvider);
    final isBusy = purchase.isSubmitting || (addressListAsync.isLoading && !addressListAsync.hasValue);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.w,
          bottom: ViewUtils.bottomBarHeight + (kIsWeb ? 16.w : 0),
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bgPrimary,
          boxShadow: [
            BoxShadow(
              color: context.shadowMd01.withValues(alpha: 0.1),
              blurRadius: 10.w,
              offset: Offset(0, -1.w),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${'common.total'.tr()}: ',
                        style: TextStyle(
                          color: context.textPrimary900,
                          fontSize: context.textSm,
                          height: context.leadingSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: FormatHelper.formatCurrency(
                          notifier.payableAmount,
                        ),
                        style: TextStyle(
                          color: context.textErrorPrimary600,
                          fontSize: context.textLg,
                          height: context.leadingLg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.w),
                Text(
                  '${'common.total.discount'.tr()} ${FormatHelper.formatCurrency(purchase.useDiscountCoins ? notifier.coinAmount : 0)}',
                  style: TextStyle(
                    color: context.textErrorPrimary600,
                    fontSize: context.textSm,
                    height: context.leadingSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),
            Button(
              width: 120.w,
              height: 40.h,
              loading: isBusy,
              onPressed: submitPayment,
              child: Text(
                'common.checkout'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.textMd,
                  height: context.leadingMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
