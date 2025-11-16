import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/ui/empty.dart';
import 'package:flutter_app/ui/index.dart';
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
  Widget build(BuildContext context) {
    final params = widget.params;

    if (params.treasureId == null) {
      // Handle null treasureId case
      return _PaymentSkeleton();
    }

    final detail = ref.watch(productDetailProvider(params.treasureId!));

    if (!detail.isLoading || detail.hasValue) {
      return _PaymentSkeleton();
    }
    print('PaymentPage params: ${widget.params}');

    return BaseScaffold(
      title: 'checkout',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddressSection(),
          SizedBox(height: 8.w),
          _ProductSection(detail: detail.value!),
          _InfoSection(),
          _VoucherSection(),
          _PaymentMethodSection(),
        ],
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _EmptySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(body: Empty());
  }
}

class _PaymentSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'checkout',
      body: Padding(
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
      bottomNavigationBar: _BottomNavigationBarSkeleton()
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
            )
          ),
        ],
      ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: BorderRadius.circular(context.radiusLg),
              child: CachedNetworkImage(
                imageUrl: detail.treasureCoverImg!,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              ),
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
