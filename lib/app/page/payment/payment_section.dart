import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/address/address_list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_app/core/models/product_list_item.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/theme/leading_tokens.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/core/models/address_res.dart';

/// Section responsible for displaying and selecting the delivery address
class AddressSection extends ConsumerWidget {
  const AddressSection({super.key});

  /// Opens the address selection bottom sheet
  void _onAddressTap() async {
    RadixSheet.show(
      enableShrink: true,
      builder: (context, close) {
        return const AddressList();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the currently selected address and the overall address list loading state
    final address = ref.watch(selectedAddressProvider);
    final listAsync = ref.watch(addressListProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () {
          // Prevent tapping while the list is still loading
          if (!listAsync.isLoading) {
            _onAddressTap();
          }
        },
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 80.w),
          margin: EdgeInsets.only(top: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(context.radiusXl),
          ),
          // Dynamically build content based on loading/selected state
          child: _buildContent(context, listAsync, address),
        ),
      ),
    );
  }

  /// Determines which state UI to display (Loading, Selected, or Empty/Add)
  Widget _buildContent(
    BuildContext context,
    AsyncValue<dynamic> listAsync,
    AddressRes? address,
  ) {
    if (listAsync.isLoading && !listAsync.hasValue) {
      return _buildLoadingState(context);
    }

    if (address != null) {
      return _buildSelectedState(context, address);
    }

    return _buildEmptyState(context);
  }

  /// Skeleton loader for the address section
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Row(
        children: [
          Skeleton.react(
            width: 24.w,
            height: 24.w,
            borderRadius: BorderRadius.circular(12.w),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.react(
                width: 120.w,
                height: 16.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
              SizedBox(height: 8.h),
              Skeleton.react(
                width: 200.w,
                height: 14.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
          const Spacer(),
          Skeleton.react(
            width: 16.w,
            height: 16.w,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ],
      ),
    );
  }

  /// UI displayed when no address is selected
  Widget _buildEmptyState(BuildContext context) {
    return Row(
      children: [
        // Log/Ticket icons removed for cleaner look
        Icon(
          CupertinoIcons.location_solid,
          color: context.buttonPrimaryBg,
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
        Icon(
          CupertinoIcons.chevron_right,
          color: context.textQuaternary500,
          size: 16.w,
        ),
      ],
    );
  }

  /// UI displayed when an address is selected
  Widget _buildSelectedState(BuildContext context, AddressRes address) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.location_solid,
          color: context.textPrimary900,
          size: 24.w,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    address.contactName ?? '',
                    style: TextStyle(
                      color: context.textPrimary900,
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    address.phone,
                    style: TextStyle(
                      color: context.textSecondary700,
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.w),
              Text(
                address.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textSecondary700,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Icon(
          CupertinoIcons.chevron_right,
          color: context.textQuaternary500,
          size: 16.w,
        ),
      ],
    );
  }
}

/// Displays product details (Image, Name, Price) in the checkout flow
class ProductSection extends ConsumerWidget {
  final ProductListItem detail;

  const ProductSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 核心修复 2：监听动态价格，而不是写死的基础价
    final purchaseState = ref.watch(purchaseProvider(detail.treasureId ?? ''));

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
                  borderRadius: BorderRadius.circular(context.radiusLg),
                  child: AppCachedImage(
                    detail.treasureCoverImg,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 80.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.treasureName ?? '',
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
                  // 这里改为动态取价！如果是 Solo Buy，这里就会跟着变成 1000.00
                  FormatHelper.formatCurrency(purchaseState.unitAmount),
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            QuantityControl(treasureId: detail.treasureId ?? ''),
          ],
        ),
      ),
    );
  }
}

/// Stepper component to increase or decrease the purchase quantity
class QuantityControl extends ConsumerStatefulWidget {
  final String treasureId;

  const QuantityControl({super.key, required this.treasureId});

  @override
  ConsumerState<QuantityControl> createState() => QuantityControlState();
}

class QuantityControlState extends ConsumerState<QuantityControl> {
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(
      purchaseProvider(widget.treasureId).select((s) => s.entries),
    );
    final action = ref.read(purchaseProvider(widget.treasureId).notifier);

    // Sync provider state to text controller only when not focused to prevent cursor jumping
    if (!_focusNode.hasFocus) {
      final text = entries.toString();
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
          decoration: BoxDecoration(
            border: Border.all(color: context.borderSecondary, width: 1.w),
            borderRadius: BorderRadius.all(Radius.circular(8.w)),
          ),
          child: Row(
            children: [
              Button(
                variant: ButtonVariant.text,
                width: 44.w,
                height: 38.w,
                onPressed: () => action.dec(
                  (v) => _textEditingController.text = v.toString(),
                ),
                child: Icon(
                  CupertinoIcons.minus,
                  color: context.textPrimary900,
                  size: 16.w,
                ),
              ),
              Container(
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textMd,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    constraints: BoxConstraints(minWidth: 40.w, maxWidth: 80.w),
                  ),
                  onChanged: (v) => action.setEntriesFromText(v),
                ),
              ),
              Button(
                variant: ButtonVariant.text,
                width: 44.w,
                height: 38.w,
                onPressed: () => action.inc(
                  (v) => _textEditingController.text = v.toString(),
                ),
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

/// Breakdown of costs (Unit Price, Ticket Count, Subtotal)
class InfoSection extends ConsumerWidget {
  final ProductListItem detail;
  final String treasureId;

  const InfoSection({
    super.key,
    required this.detail,
    required this.treasureId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseProvider(treasureId));
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
            InfoRow(label: 'common.price.detail'.tr(), value: ''),
            SizedBox(height: 12.w),
            InfoRow(
              label: 'common.ticket.price'.tr(),
              value: FormatHelper.formatCurrency(purchaseState.unitAmount),
            ),
            SizedBox(height: 12.w),
            InfoRow(
              label: 'common.tickets.number'.tr(),
              value: '${purchaseState.entries}',
            ),
            SizedBox(height: 12.w),
            InfoRow(
              label: 'common.total.price'.tr(),
              value: FormatHelper.formatCurrency(purchaseState.subtotal),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

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
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary900,
            fontSize: context.textSm,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Section to manage Treasure Coin discounts and check availability
class VoucherSection extends ConsumerWidget {
  final String treasureId;

  const VoucherSection({super.key, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(purchaseProvider(treasureId));
    final notifier = ref.read(purchaseProvider(treasureId).notifier);
    final coinsBalance = ref.watch(walletProvider.select((s) => s.coinBalance));

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Voucher/Coupon label
            Text(
              'coupon.coupon'.tr(),
              style: TextStyle(
                color: context.textPrimary900,
                fontSize: context.textSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'common.treasureCoins'.tr(),
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (purchase.useDiscountCoins)
                      Text(
                        '(${FormatHelper.formatCompactDecimal(notifier.coinsCanUse)} coins)=${FormatHelper.formatCurrency(notifier.coinAmount)}',
                        style: TextStyle(
                          color: context.textErrorPrimary600,
                          fontSize: context.textSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: purchase.useDiscountCoins,
                        onChanged: (v) => notifier.toggleUseDiscountCoins(v),
                        activeTrackColor: context.bgBrandSolid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${'common.balance'.tr()}: ${FormatHelper.formatCompactDecimal(coinsBalance)} ${'common.coins'.tr()}',
              style: TextStyle(color: context.textQuaternary500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Final selection for Payment Method (Wallet/Balance)
class PaymentMethodSection extends ConsumerWidget {
  const PaymentMethodSection({super.key, required String treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realBalance = ref.watch(walletProvider.select((s) => s.realBalance));

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.select'.tr(),
              style: TextStyle(
                color: context.textPrimary900,
                fontSize: context.textSm,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12.w),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/payment/wallet-icon.svg',
                  width: 20.w,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${'common.balance'.tr()}:${FormatHelper.formatCurrency(realBalance)}',
                      style: TextStyle(
                        color: context.textQuaternary500,
                        fontSize: context.textXs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Radio(
                  groupValue: 'wallet',
                  value: 'wallet',
                  onChanged: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
