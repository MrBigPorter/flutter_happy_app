import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/address/address_list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_app/core/models/product_list_item.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_app/theme/leading_tokens.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'package:flutter_app/core/providers/address_provider.dart';

import 'package:flutter_app/core/models/address_res.dart';


class AddressSection extends ConsumerWidget {
  const AddressSection({super.key});

  void _onAddressTap() async {
    RadixSheet.show(
      enableShrink: true,
      builder: (context, close) {
        return AddressList();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听选中项
    final address = ref.watch(selectedAddressProvider);
    // 2. 关键：同时监听列表的请求状态
    final listAsync = ref.watch(addressListProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () {
          // 只有加载完了才能点，或者你允许加载中点进去看 Skeleton
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
          // 3. 根据状态决定显示什么
          child: _buildContent(context, listAsync, address),
        ),
      ),
    );
  }

  /// 核心内容构建逻辑
  Widget _buildContent(
      BuildContext context,
      AsyncValue<dynamic> listAsync,
      AddressRes? address
      ) {
    // 优先级 A: 正在初次加载，且没有数据
    // (!listAsync.hasValue 保证了下拉刷新时不会突然变成转圈，只有第一次会)
    if (listAsync.isLoading && !listAsync.hasValue) {
      return _buildLoadingState(context);
    }

    // 优先级 B: 有选中的地址
    if (address != null) {
      return _buildSelectedState(context, address);
    }

    // 优先级 C: 加载完了，但没有选中地址 (或者列表为空) -> 显示“去添加”
    return _buildEmptyState(context);
  }

  // --- 状态组件 ---
  // 1. Loading 状态
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
          Spacer(),
          Skeleton.react(
            width: 16.w,
            height: 16.w,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ],
      ),
    );
  }

  // 2. 空状态 (去添加)
  Widget _buildEmptyState(BuildContext context) {
    return Row(
      children: [
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

  // 3. 选中状态
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
                    address.phone ?? '',
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
                address.fullAddress ?? '',
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

class ProductSection extends StatelessWidget {
  final ProductListItem detail;

  const ProductSection({super.key, required this.detail});

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
            QuantityControl(treasureId: detail.treasureId),
          ],
        ),
      ),
    );
  }
}

class QuantityControl extends ConsumerStatefulWidget {
  final String treasureId;

  const QuantityControl({super.key, required this.treasureId});

  @override
  ConsumerState<QuantityControl> createState() => QuantityControlState();
}

class QuantityControlState extends ConsumerState<QuantityControl> {
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  void _updateEntries(int entries) {
    _textEditingController.text = entries.toString();
  }

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
      purchaseProvider(widget.treasureId).select((select) => select.entries),
    );
    final action = ref.read(purchaseProvider(widget.treasureId).notifier);

    // 只有当没有焦点时，才同步 Provider 的值到输入框
    // 避免用户正在输入时输入框内容跳变
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: context.borderSecondary, width: 1.w),
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    constraints: BoxConstraints(minWidth: 40.w, maxWidth: 80.w),
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

class InfoSection extends ConsumerWidget {
  final ProductListItem detail;
  final String treasureId;

  const InfoSection({super.key, required this.detail, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      purchaseProvider(treasureId).select((select) => select.entries),
    );
    //  优化: 从 notifier 获取计算好的总价，比手动计算更可靠
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
            InfoRow(label: 'common.tickets.number'.tr(), value: '$entries'),
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

class VoucherSection extends ConsumerWidget {
  final String treasureId;

  const VoucherSection({super.key, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(purchaseProvider(treasureId));
    final notifier = ref.read(purchaseProvider(treasureId).notifier);
    final coinsBalance = ref.watch(
      luckyProvider.select((state) => state.balance.coinBalance),
    );

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
                                '(${FormatHelper.formatCompactDecimal(notifier.coinsCanUse)} coins)=${FormatHelper.formatCurrency(notifier.coinAmount)}',
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
                            onChanged: (v) =>
                                notifier.toggleUseDiscountCoins(v),
                          ),
                        ),
                      ),
                    ],
                  ),
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

class PaymentMethodSection extends ConsumerWidget {
  final String treasureId;

  const PaymentMethodSection({super.key, required this.treasureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realBalance = ref.watch(
      luckyProvider.select((select) => select.balance.realBalance),
    );

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
                      '${'common.balance'.tr()}:${FormatHelper.formatCurrency(realBalance)}',
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
