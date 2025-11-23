import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycModal extends StatelessWidget {

  const KycModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}