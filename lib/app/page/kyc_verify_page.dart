import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/kyc_information_confirm_page.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/upload_progress_dialog.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/core/providers/liveness_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/utils/camera/services/liveness_service.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/camera/services/unified_kyc_cuard.dart';

/// KYC Verify Page
class KycVerifyPage extends ConsumerStatefulWidget {
  const KycVerifyPage({super.key});

  @override
  ConsumerState<KycVerifyPage> createState() => _KycVerifyPageState();
}

class _KycVerifyPageState extends ConsumerState<KycVerifyPage> {
  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final kycTypeAsyncValue = ref.watch(kycIdTypeProvider);

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
              loading: kycTypeAsyncValue.isLoading,
              onPressed: () async {
                final options = await ref.read(kycIdTypeProvider.future);
                if (!mounted) return;

                _additionalInformation(context, KycOcrResult(
                    idType: 1,
                    country: "PH",
                    birthday: "1990-01-01",
                    gender: 'MALE',
                    rawText: 'Raw OCR Text',
                    firstName: 'Juan',
                    lastName: 'Dela Cruz',
                    idNumber: '123456789',
                  )
                );


                /*final option = await RadixSheet.show<KycIdTypes>(
                  builder: (_, close) => SelectIdType(options: options),
                );

                if (option != null && mounted) {
                  final result = await _scanAndUploadID();
                  if (result != null && mounted) {
                    // information confirm
                    print("Scanned ID Result: $result");
                    await _additionalInformation(context, result);
                  }
                }*/
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

  Future<KycOcrResult?> _scanAndUploadID() async {
    final kycNotifier = ref.read(kycNotifierProvider.notifier);

    // 0. 开启相机
    final imagePath = await LivenessService.scanDocument(context);

    //  2. 核心防御：相机返回后检查组件是否已被销毁
    if (imagePath == null || !mounted) return null;

    // 3. 锁定全局 UI 环境
    final globalContext = NavHub.key.currentContext;
    if (globalContext == null || !globalContext.mounted) return null;

    final messageNotifier = ValueNotifier<String>('1/3 ${'analyzing'.tr()}...');
    Object? errorReason;
    KycOcrResult? successResult;

    try {
      await UploadProgressDialog.show(
        globalContext,
        messageNotifier: messageNotifier,
        uploadTask: (updateProgress) async {
          // --- 步骤 1: 智能检测 ---
          await Future.delayed(const Duration(milliseconds: 300));
          final bool isPass = await UnifiedKycGuard().check(
            imagePath,
            KycDocType.idCard,
          );
          if (!isPass) throw 'GUARD_CHECK_FAILED';

          // --- 步骤 2: 上传 ---
          // 在异步闭包内依然检查 globalContext
          if (globalContext.mounted) {
            messageNotifier.value = '2/3 ${'uploading'.tr()}...';
          }

          final uploadResult = await GlobalUploadService().uploadFile(
            filePath: imagePath,
            module: UploadModule.kyc,
            cancelToken: CancelToken(),
            onProgress: updateProgress,
          );
          if (uploadResult == null) throw 'UPLOAD_FAILED';

          // --- 步骤 3: 提取信息 ---
          if (globalContext.mounted) {
            messageNotifier.value = '3/3 ${'processing'.tr()}...';
          }

          //  这里的 kycNotifier 是闭包捕获的，不触发 ref 检查
          final ocrResult = await kycNotifier.scanIdCard(uploadResult);

          await Future.delayed(const Duration(milliseconds: 500));
          return ocrResult;
        },
      ).then((result) {
        successResult = result;
      });
    } catch (e) {
      errorReason = e;
      debugPrint("Kyc Upload Error: $e");
    }

    // --- 失败处理 (使用全局环境) ---
    if (successResult != null) return successResult;

    if (globalContext.mounted) {
      _handleUploadError(globalContext, errorReason);
    }

    return null;
  }

  void _handleUploadError(BuildContext targetContext, Object? error) {
    if (error == 'GUARD_CHECK_FAILED') {
      RadixModal.show(
        title: 'check failed'.tr(),
        cancelText: '',
        builder: (_, __) => Text(
          'No valid ID detected.\nPlease align the front of your ID with the camera.',
          style: TextStyle(fontSize: 16.sp, color: const Color(0xFF1F2937)),
        ),
      );
    } else if (error != null) {
      final msg = error == 'UPLOAD_FAILED'
          ? 'Upload failed'.tr()
          : 'Error: $error';
      ScaffoldMessenger.of(targetContext).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _additionalInformation(context, data) async {
    // 后续补充信息逻辑
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KycInformationConfirmPage(kycOcrResult: data),
      ),
    );

    print("Information Confirm Result: $result");

    if (result == true && mounted) {
      _livenessDetection(context);
    }
  }

  void _livenessDetection(context) {
    // 后续活体检测逻辑
    ref.read(livenessNotifierProvider.notifier).startDetection(context);
  }
}

// --- 辅助 UI 组件 (Stateless 即可) ---

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
          detail: _buildStep1Detail(context),
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
          // 建议检查此处是否应为 Step 3
          subTitle: 'upload-selfie'.tr(),
          description: 'upload-verification'.tr(),
          completed: false,
          img: 'assets/images/verify/step3.png',
        ),
      ],
    );
  }

  Widget _buildStep1Detail(BuildContext context) {
    final items = ['full-name', 'id-photo', 'date-o'];
    return Column(
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
        ...items.map(
          (key) => Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: context.textBrandPrimary900,
                  size: 8.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  key.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
          subTitle ?? '',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.textSecondary700,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child:
                  detail ??
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                    ),
                  ),
            ),
            Image.asset(img, width: 112.w, height: 70.h, fit: BoxFit.contain),
          ],
        ),
      ],
    );
  }
}
