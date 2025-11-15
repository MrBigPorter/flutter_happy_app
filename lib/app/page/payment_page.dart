import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';

import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/ui/empty.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/sheet/modal_sheet_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final PagePaymentParams params;

  const PaymentPage({super.key, required this.params});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final params = widget.params;

    if (params.treasureId == null) {
      // Handle null treasureId case
      return _EmptySection();
    }

    final detail = ref.read(productDetailProvider(params.treasureId!));
    print('PaymentPage params: ${widget.params}');

    return BaseScaffold(
      title: 'checkout',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddressSection(),
          _ProductSection(),
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

class _AddressSection extends StatelessWidget {
  void _onAddressTap() {
    RadixSheet.show(
      config: ModalSheetConfig(
        headerBuilder: (context,close) {
         return Text(
           'Delivery address',
           style: TextStyle(
             fontSize: context.textMd,
             fontWeight: FontWeight.bold,
              color: context.textPrimary900,
           ),
         );
        },
      ),
      builder: (context, close) {
        return Container(
          height: 300.w,
          child: Center(child: Text('Address Selection Page')),//todo
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
  @override
  Widget build(BuildContext context) {
    return Container(child: Text('Product Section'));
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
