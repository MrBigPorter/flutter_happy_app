import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/payment_components/insufficient_balance_sheet.dart';
import 'package:flutter_app/app/page/payment_components/payment_success_sheet.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final PagePaymentParams params;

  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin {
  bool _isInit = false;
  
  @override
  void initState() {
    super.initState();
    
      WidgetsBinding.instance.addPostFrameCallback((_){
        final isAuthenticated = ref.read(authProvider.select((state) => state.isAuthenticated));
        if(!isAuthenticated) return;
        // Refresh wallet balance on page load
        ref.read(luckyProvider.notifier).updateWalletBalance();
        // You can also refresh other necessary data here
        final treasureId = widget.params.treasureId;
        if(treasureId != null){
          ref.invalidate(productDetailProvider(treasureId));
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;

    if (params.treasureId == null) {
      // Handle null treasureId case
      return _PaymentSkeleton();
    }

    final detail = ref.watch(productDetailProvider(params.treasureId!));


    return detail.when(
      loading: () => _PaymentSkeleton(),
      error: (_, __) => _PaymentSkeleton(),
      data: (value) {
        if (!_isInit) {
          _isInit = true;
          Future.microtask(() {
            final action = ref.read(
              purchaseProvider(params.treasureId!).notifier,
            );
            final purchaseState = ref.read(
              purchaseProvider(params.treasureId!),
            );
            final entries =
                int.tryParse(params.entries ?? '') ??
                purchaseState.minBuyQuantity;
            action.resetEntries(entries);
          });
        }
        return BaseScaffold(
          title: 'checkout'.tr(),
          body: LayoutBuilder(
            builder: (context, constrains) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constrains.maxHeight),
                  child: Column(
                    children: [
                      _AddressSection(),
                      SizedBox(height: 8.w),
                      _ProductSection(detail: value),
                      SizedBox(height: 8.w),
                      _InfoSection(
                        detail: value,
                        treasureId: params.treasureId!,
                      ),
                      SizedBox(height: 8.w),
                      _VoucherSection(treasureId: params.treasureId!),
                      SizedBox(height: 8.w),
                      _PaymentMethodSection(treasureId: params.treasureId!),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: _BottomNavigationBar(
            treasureId: params.treasureId!,
            title: value.treasureName
          ),
        );
      },
    );
  }
}

class _AddressSection extends StatelessWidget {
  void _onAddressTap() {
    RadixSheet.show(
      builder: (context, close) {
        return Container(
          height: 300.w,
          child: Center(child: Text('Address Selection Page')), //todo
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () {
          // Navigate to address selection page
          _onAddressTap();
        },
        child: Container(
          width: double.infinity,
          height: 80.w,
          margin: EdgeInsets.only(top: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(context.radiusXl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.location_solid,
                color: context.bgPrimarySolid,
                size: 24.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'add-delivery-address-for-prize'.tr(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: context.textSecondary700,
                    fontSize: context.textSm,
                    height: context.leadingSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ProductSection extends StatelessWidget {

  final ProductListItem detail;
  const _ProductSection({required this.detail});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.all(Radius.circular(context.radiusXl)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(context.radiusLg),
                  child: CachedNetworkImage(
                    imageUrl: detail.treasureCoverImg!,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    // 内存缓存宽度设置，提升性能，避免每次都解码大图，需要80就只缓存80宽度的图，解码也是80宽度
                    memCacheWidth: (80.w * ViewUtils.dpr).toInt(),
                    memCacheHeight: (80.w * ViewUtils.dpr).toInt(),
                    errorWidget: (context, url, error) => Icon(
                      CupertinoIcons.photo,
                      size: 80.w,
                      color: context.bgSecondary,
                    ),
                    placeholder: (context, url) => Skeleton.react(
                      width: 80.w,
                      height: 80.w,
                      borderRadius: BorderRadius.circular(context.radiusLg),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 80.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.treasureName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimary900,
                            fontSize: context.textSm,
                            height: context.leadingLg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          detail.lotteryTime != null
                              ? '${'common.draw.date'.tr()}:${DateFormatHelper.formatFull(detail.lotteryTime)}'
                              : 'Draw once sold out',
                          style: TextStyle(
                            color: context.textSecondary700,
                            fontSize: context.textXs,
                            height: context.leadingXs,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  FormatHelper.formatCurrency(detail.unitAmount),
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textXs,
                    height: context.leadingLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            _QuantityControl(treasureId:detail.treasureId)
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends ConsumerStatefulWidget {
  final String treasureId;
  const _QuantityControl({required this.treasureId});

  @override
  ConsumerState<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends ConsumerState<_QuantityControl> {
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  void _updateEntries(int entries) {
    _textEditingController.text = entries.toString();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final action = ref.read(
        purchaseProvider(widget.treasureId).notifier,
      );
      action.setEntriesFromText(_textEditingController.text);
      final purchaseState = ref.read(
        purchaseProvider(widget.treasureId),
      );
      _updateEntries(purchaseState.entries);
    }
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){

    final purchase = ref.watch(purchaseProvider(widget.treasureId));
    final action = ref.read(
      purchaseProvider(widget.treasureId).notifier,
    );

    if (!_focusNode.hasFocus) {
      final text = purchase.entries.toString();
      if (_textEditingController.text != text) {
        _textEditingController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 38.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: context.borderSecondary,
              width: 1.w,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8.w)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Button(
                variant: ButtonVariant.text,
                width: 44.w,
                height: 38.w,
                paddingY: 0,
                onPressed: () {
                  action.dec((v) => _updateEntries(v));
                },
                child: Icon(
                  CupertinoIcons.minus,
                  color: context.textPrimary900,
                  size: 16.w,
                ),
              ),
              Container(
                height: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: context.borderSecondary,
                      width: 1.w,
                    ),
                    left: BorderSide(
                      color: context.borderSecondary,
                      width: 1.w,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textMd,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                      maxWidth: 80.w,
                    ),
                  ),
                  onChanged: (value) {
                    action.setEntriesFromText(value);
                  },
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              Button(
                variant: ButtonVariant.text,
                width: 44.w,
                height: 38.w,
                paddingY: 0,
                onPressed: () {
                  action.inc((v) => _updateEntries(v));
                },
                child: Icon(
                  CupertinoIcons.add,
                  color: context.textPrimary900,
                  size: 16.w,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends ConsumerWidget {
  final ProductListItem detail;
  final String treasureId;

  const _InfoSection({required this.detail, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(purchaseProvider(treasureId));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(context.radiusXl),
        ),
        child: Column(
          children: [
            _InfoRow(label: 'common.price.detail'.tr(), value: ''),
            SizedBox(height: 12.w),
            _InfoRow(
              label: 'common.ticket.price'.tr(),
              value: FormatHelper.formatCurrency(detail.unitAmount),
            ),
            SizedBox(height: 12.w),
            _InfoRow(
              label: 'common.tickets.number'.tr(),
              value: '${purchase.entries}',
            ),
            SizedBox(height: 12.w),
            _InfoRow(
              label: 'common.total.price'.tr(),
              value: FormatHelper.formatCurrency(
                detail.unitAmount * purchase.entries,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textPrimary900,
            fontSize: context.textSm,
            height: context.leadingSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary900,
            fontSize: context.textSm,
            height: context.leadingSm,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _VoucherSection extends ConsumerWidget {
  final String treasureId;

  const _VoucherSection({required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(purchaseProvider(treasureId));
    final action = ref.read(purchaseProvider(treasureId).notifier);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(context.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'coupon.coupon'.tr(),
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textSm,
                    height: context.leadingSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Button(
                  variant: ButtonVariant.text,
                  height: 20.w,
                  paddingX: 0,
                  gap: 2.w,
                  onPressed: () => {},
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    color: context.textPrimary900,
                    size: 16.w,
                  ),
                  child: Text(
                    'coupon.num.available'.tr(namedArgs: {'number': '0'}),
                    style: TextStyle(
                      color: context.textErrorPrimary600,
                      fontSize: context.textSm,
                      height: context.leadingSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'common.treasureCoins'.tr(),
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textSm,
                    height: context.leadingSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: purchase.useDiscountCoins
                            ? Text(
                                '(${purchase.coinsToUse} coins)=${FormatHelper.formatCurrency(purchase.coinAmount)}',
                                style: TextStyle(
                                  color: context.textErrorPrimary600,
                                  fontSize: context.textSm,
                                  height: context.leadingSm,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(
                        width: 40.w,
                        height: 20.w,
                        child: Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            padding: EdgeInsets.zero,
                            activeThumbColor: context.fgWhite,
                            activeTrackColor: context.bgBrandSolid,
                            inactiveTrackColor: context.bgQuaternary,
                            inactiveThumbColor: context.fgWhite,
                            trackOutlineColor: WidgetStateProperty.all(
                              context.borderSecondary,
                            ),
                            value: purchase.useDiscountCoins,
                            onChanged: (v) => action.toggleUseDiscountCoins(v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '${'common.balance'.tr()}: ${purchase.balanceCoins.toInt()} ${'common.coins'.tr()}',
              style: TextStyle(color: context.textQuaternary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSection extends ConsumerWidget {
  final String treasureId;

  const _PaymentMethodSection({required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(purchaseProvider(treasureId));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(context.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.select'.tr(),
              style: TextStyle(
                color: context.textPrimary900,
                fontSize: context.textSm,
                height: context.leadingSm,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12.w),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/payment/wallet-icon.svg',
                  width: 20.w,
                  height: 20.w,
                  colorFilter: ColorFilter.mode(
                    context.textPrimary900,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common.wallet'.tr(),
                      style: TextStyle(
                        color: context.textPrimary900,
                        fontSize: context.textSm,
                        height: context.leadingSm,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      '${'common.balance'.tr()}:${FormatHelper.formatCurrency(purchase.realBalance)}',
                      style: TextStyle(
                        color: context.textQuaternary500,
                        fontSize: context.textXs,
                        height: context.leadingXs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                RadioGroup(
                  groupValue: 'wallet',
                  onChanged: (v) => {},
                  child: Radio(
                    activeColor: context.borderBrand,
                    overlayColor: WidgetStateProperty.all(Colors.black),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    value: 'wallet',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends ConsumerStatefulWidget {
  final String treasureId;
  final String title;

  const _BottomNavigationBar({required this.treasureId, required this.title});

  @override
  ConsumerState<_BottomNavigationBar> createState() =>
      _BottomNavigationBarState();
}

class _BottomNavigationBarState extends ConsumerState<_BottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  void submitPayment() async {
    final action = ref.read(
      purchaseProvider(widget.treasureId).notifier,
    );
    final result = await action.submitOrder();

    if(!context.mounted) return;

    if(!result.ok){
      switch (result.error){
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
              return SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'common.modal.kyc.desc1'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textPrimary900,
                        fontSize: context.textLg,
                        height: context.leadingLg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12.w),
                    Text(
                      'common.modal.kyc.desc2'.tr(),
                      style: TextStyle(
                        color: context.textSecondary700,
                        fontSize: context.textMd,
                        height: context.leadingMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          break;
        case PurchaseSubmitError.noAddress:
           RadixToast.error('please.add.delivery.address'.tr());
          break;
        case PurchaseSubmitError.insufficientBalance:
          RadixSheet.show(
            config: ModalSheetConfig(
              enableHeader: false,
            ),
            builder: (context, close) {
              return InsufficientBalanceSheet(close: close);
            },
          );
          break;
        case PurchaseSubmitError.soldOut:
           RadixSheet.show(
             builder: (context,close){
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
                       onPressed: (){
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
             }
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

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut,reverseCurve: Curves.easeInOut)
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
    final purchase = ref.watch(purchaseProvider(widget.treasureId));

    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child){
          return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.w,
            bottom: ViewUtils.bottomBarHeight + (kIsWeb?16.w:0),
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
                          text: FormatHelper.formatCurrency(purchase.payableAmount),
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
                    '${'common.total.discount'.tr()} ${FormatHelper.formatCurrency(purchase.useDiscountCoins ? purchase.coinAmount : 0)}',
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
                height: 40.w,
                loading: purchase.isSubmitting,
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

class _PaymentSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'checkout',
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 20.w),
              _AddressSectionSkeleton(),
              SizedBox(height: 8.w),
              _ProductSectionSkeleton(),
              SizedBox(height: 8.w),
              _InfoSectionSkeleton(),
              SizedBox(height: 8.w),
              _VoucherSectionSkeleton(),
              SizedBox(height: 8.w),
              _PaymentMethodSectionSkeleton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigationBarSkeleton(),
    );
  }
}

class _AddressSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 16.w),
      width: double.infinity,
      height: 80.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Row(
        children: [
          SizedBox(width: 10.w),
          Skeleton.react(
            width: 24.w,
            height: 24.w,
            borderRadius: BorderRadius.circular(12.w),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton.react(
                  width: double.infinity,
                  height: 10.w,
                  borderRadius: BorderRadius.circular(12.w),
                ),
                SizedBox(height: 8.w),
                Skeleton.react(
                  width: double.infinity,
                  height: 10.w,
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(
                  width: 80.w,
                  height: 80.w,
                  borderRadius: BorderRadius.circular(context.radiusLg),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.w,
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      SizedBox(height: 8.w),
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.w,
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      SizedBox(height: 8.w),
                      Skeleton.react(
                        width: double.infinity,
                        height: 12.w,
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      SizedBox(height: 8.w),
                      Skeleton.react(
                        width: 80.w,
                        height: 12.w,
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Skeleton.react(
                  width: 20.w,
                  height: 12.w,
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(child: Container()),
                Skeleton.react(
                  width: 190.w,
                  height: 36.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 120.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
                SizedBox(height: 18.w),
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 50.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
                SizedBox(height: 18.w),
                Row(
                  children: [
                    Skeleton.react(
                      width: 130.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 30.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
                SizedBox(height: 18.w),
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 50.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
                SizedBox(height: 18.w),
                Row(
                  children: [
                    Skeleton.react(
                      width: 120.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    Expanded(child: Container()),
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    SizedBox(width: 10.w),
                    Skeleton.react(
                      width: 36.w,
                      height: 20.w,
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSectionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Skeleton.react(
                      width: 140.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
                SizedBox(height: 18.w),
                Row(
                  children: [
                    Skeleton.react(
                      width: 20.w,
                      height: 20.w,
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton.react(
                          width: 80.w,
                          height: 12.w,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        SizedBox(height: 8.w),
                        Skeleton.react(
                          width: 120.w,
                          height: 12.w,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ],
                    ),
                    Spacer(),
                    Skeleton.react(
                      width: 16.w,
                      height: 16.w,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationBarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      width: double.infinity,
      height: 80.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(context.radiusXl),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Skeleton.react(
                      width: 80.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    SizedBox(height: 8.w),
                    Skeleton.react(
                      width: 100.w,
                      height: 12.w,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ],
                ),
                SizedBox(width: 16.w),
                Skeleton.react(
                  width: 120.w,
                  height: 40.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
