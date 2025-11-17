import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/ui/empty.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
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

  bool _isInit = false;

  PurchaseArgs _matchArgs (ProductListItem detail, bool isAuthenticated, double coinBalance, double exchangeRate) {
    final PurchaseArgs args = (
    unitPrice: detail.unitAmount ?? 0,
    maxUnitCoins: detail.maxUnitCoins ?? 0,
    exchangeRate: exchangeRate,
    maxPerBuy: detail.maxPerBuyQuantity ?? 999999,
    minPerBuy: detail.minBuyQuantity ?? 1,
    stockLeft:
    (detail.seqShelvesQuantity ?? 0) -
        (detail.seqBuyQuantity ?? 0),
    isLoggedIn: isAuthenticated,
    balanceCoins: coinBalance,
    coinAmountCap: null,
    );
    return args;
  }

  @override
  void initState() {
    super.initState();

    final id = widget.params.treasureId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //ref.refresh(productDetailProvider(id));
      });
    }
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
        if(!_isInit){
          _isInit = true;
          Future.microtask((){
            final action = ref.read(purchaseProvider(params.treasureId!).notifier);
           final purchaseState = ref.read(purchaseProvider(params.treasureId!));
           final entries = int.tryParse(params.entries ?? '') ?? purchaseState.minBuyQuantity;
           action.resetEntries(entries);
          });
        }
        return BaseScaffold(
          title: 'checkout'.tr(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _AddressSection(),
                SizedBox(height: 8.w),
                _ProductSection(detail: value),
                SizedBox(height: 8.w),
                _InfoSection(),
                SizedBox(height: 8.w),
                _VoucherSection(),
                SizedBox(height: 8.w),
                _PaymentMethodSection(),
              ],
            ),
          ),
          bottomNavigationBar: _BottomNavigationBar(),
        );
      },
    );
  }
}

class _EmptySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(body: Empty());
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

class _ProductSection extends ConsumerStatefulWidget {
  final ProductListItem detail;

  const _ProductSection({required this.detail});

  @override
  ConsumerState<_ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends ConsumerState<_ProductSection> {
  
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  void _updateEntries(int entries){
     _textEditingController.text = entries.toString();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final action = ref.read(purchaseProvider(widget.detail.treasureId).notifier);
      action.setEntriesFromText(_textEditingController.text);
      final purchaseState = ref.read(purchaseProvider(widget.detail.treasureId));
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
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final purchase = ref.watch(purchaseProvider(widget.detail.treasureId));
    final action = ref.read(purchaseProvider(widget.detail.treasureId).notifier);

    if(!_focusNode.hasFocus){
      final text = purchase.entries.toString();
      if(_textEditingController.text != text){
        _textEditingController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

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
            Row(
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
                         action.dec((v)=> _updateEntries(v));
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
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              maxWidth: 80.w,
                            ),
                          ),
                          onChanged: (value) {
                            action.setEntriesFromText(value);
                          },
                          onTapOutside:(_){
                            FocusScope.of(context).unfocus();
                          },
                          onEditingComplete:(){
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
                          action.inc((v)=> _updateEntries(v));
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
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text('Info Section'));
  }
}

class _VoucherSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text('Voucher Section'));
  }
}

class _PaymentMethodSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text('Payment Method Section'));
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: CupertinoColors.systemGrey5,
      child: Center(child: Text('Bottom Navigation Bar')),
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