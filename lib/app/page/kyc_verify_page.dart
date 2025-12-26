import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/id_scan_page.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/upload_progress_dialog.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/camera/camera_helper.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/select_id_type.dart';
import '../../utils/camera/services/unified_kyc_cuard.dart';

/// kyc verify page
/// Displays the KYC verification steps and allows users to start the verification process.
/// Uses a BaseScaffold for consistent layout and styling.
/// Includes a scrollable list of verification steps and a bottom navigation bar with a start button.

class KycVerifyPage extends ConsumerWidget {
  const KycVerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScaffold(
      title: 'kyc-verify'.tr(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                80.h,
          ),
          child: _StepList(),
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

/// bottom navigation bar
class _BottomNavigationBar extends ConsumerWidget {
  Future<void> showKycTypeSheet(
    BuildContext context,
    List<KycIdTypes> options,
    WidgetRef ref,
  ) async {
    final option = await RadixSheet.show<KycIdTypes>(
      builder: (context, close) {
        return SelectIdType(options: options);
      },
    );
    if (option != null) {
      // first step scan and upload id
      final url = await _scanAndUploadID(context, ref);
      if (url == null) {
        return;
      }
      // second step liveness detection
      _livenessDetection(context, ref);
    }
  }

  // first step scan and upload id
  Future<String?> _scanAndUploadID(BuildContext context, WidgetRef ref) async {
    final camera = await CameraHelper.pickBackCamera(context);
    if (camera == null) {
      return null;
    }
    final String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IDScanPage(cameraDescription: camera),
      ),
    );
    print('Scanned image path: $imagePath');
    // 用户没拍，返回了
    if (imagePath == null) return null;


    // 开始检测：传入 imagePath 和 证件类型(idCard)
    final bool isPass = await UnifiedKycGuard().check(
      imagePath,
      KycDocType.idCard,
    );
    
    print('KYC check result: $isPass');

    if (!isPass) {
       RadixModal.show(
        title: 'check failed',
        cancelText:'',
        builder: (context, close) => Text(
            '未检测到有效的证件信息。\n请确保证件正面对准镜头，且光线充足。',
            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900)
        ),
      );
       return null;
    }

    // 关闭 Loading
    if (context.mounted) Navigator.pop(context);

    final cancelToken = CancelToken();

    final uploadResult = await UploadProgressDialog.show(
      context,
      title: 'uploading...',
      uploadTask: (onProgress) {
        return GlobalUploadService().uploadFile(
          filePath: imagePath,
          module: UploadModule.kyc,
          onProgress: onProgress,
          cancelToken: cancelToken, // 传递取消令牌
        );
      },
    );

    return uploadResult;
  }

  void _livenessDetection(BuildContext context, WidgetRef ref) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycType = ref.watch(kycIdTypeProvider);

    return Container(
      color: context.bgPrimary,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: Button(
              onPressed: () {
                kycType.whenData((options) async {
                  showKycTypeSheet(context, options, ref);
                });
              },
              width: double.infinity,
              height: 40.h,
              child: Text(
                'start-now'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// kyc verify step list
class _StepList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        _StepItem(
          title: '${'common.step'.tr()} 1',
          subTitle: 'upload-id-photo'.tr(),
          description: '',
          detail: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'make-id'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.textPrimary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'full-name'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'id-photo'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 8.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'date-o'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          completed: false,
          img: 'assets/images/verify/step1.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'information-confirm'.tr(),
          description: 'double-id'.tr(),
          completed: false,
          img: 'assets/images/verify/step2.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'upload-selfie'.tr(),
          description: 'upload-verification'.tr(),
          completed: false,
          img: 'assets/images/verify/step3.png',
        ),
      ],
    );
  }
}

/// kyc verify step item
class _StepItem extends StatelessWidget {
  final String title;
  final String description;
  final String? subTitle;
  final bool completed;
  final String img;
  final Widget? detail;

  const _StepItem({
    required this.title,
    required this.description,
    this.completed = false,
    this.subTitle,
    required this.img,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              completed ? CupertinoIcons.check_mark_circled_solid : Icons.error,
              color: context.textBrandPrimary900,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.textBrandPrimary900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          subTitle!,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.textSecondary700,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            if (detail != null)
              Expanded(child: detail!)
            else
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ),
            Image.asset(
              img,
              width: 112.w,
              height: 70.h,
              fit: BoxFit.contain,
              cacheWidth: (112.w * MediaQuery.of(context).devicePixelRatio)
                  .round(),
            ),
          ],
        ),
      ],
    );
  }
}
