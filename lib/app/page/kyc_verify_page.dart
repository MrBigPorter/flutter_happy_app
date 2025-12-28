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

import '../../components/select_id_type.dart';
import '../../utils/camera/services/unified_kyc_cuard.dart';

class KycVerifyPage extends ConsumerStatefulWidget {
  const KycVerifyPage({super.key});

  @override
  ConsumerState<KycVerifyPage> createState() => _KycVerifyPageState();
}

class _KycVerifyPageState extends ConsumerState<KycVerifyPage> {
  /// 风险阈值：>=60 直接拦截；30~59 警告；<30 放行
  static const double kFraudBlockScore = 60.0;
  static const double kFraudWarnScore = 30.0;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'kyc-verify'.tr(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                80.h,
          ),
          child: const _StepList(),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: Button(
              loading: kycTypeAsyncValue.isLoading,
              onPressed: () async {
                // 1) 选择证件类型
                final options = await ref.read(kycIdTypeProvider.future);
                if (!mounted) return;

                final selected = await RadixSheet.show<KycIdTypes>(
                  builder: (_, close) => SelectIdType(options: options),
                );

                if (!mounted) return;

                if (selected == null) {
                  _toast(context, 'Cancelled. No changes were made.');
                  return;
                }

                // 2) 扫描 + Guard + 上传 + OCR
                final ocr = await _scanAndUploadID(selected);
                if (!mounted || ocr == null) return;

                // 3) 信息确认
                await _additionalInformation(context, ocr);
              },
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

  void _toast(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 扫描 + Guard 检测 + 上传 OCR +
  Future<KycOcrResult?> _scanAndUploadID(KycIdTypes selectedType) async {
    // 0) 打开相机扫描
    final imagePath = await LivenessService.scanDocument(context);

    if (!mounted) return null;
    if (imagePath == null) {
      _toast(context, 'Scan cancelled. Please try again.');
      return null;
    }

    // 1) 锁定全局 UI 环境（弹窗/进度）
    final globalContext = NavHub.key.currentContext;
    if (globalContext == null || !globalContext.mounted) {
      _toast(context, 'UI not ready. Please try again.');
      return null;
    }

    final messageNotifier = ValueNotifier<String>('Preparing...');
    Object? errorReason;
    KycOcrResult? successResult;

    try {
      await UploadProgressDialog.show(
        globalContext,
        messageNotifier: messageNotifier,
        uploadTask: (updateProgress) async {
          // Step 1/4: Guard 检测
          messageNotifier.value = '1/4 Checking photo quality...';
          await Future.delayed(const Duration(milliseconds: 150));

          final bool isPass = await UnifiedKycGuard().check(
            imagePath,
            KycDocType.idCard,
          );
          if (!isPass) throw 'GUARD_CHECK_FAILED';

          // Step 2/4: 上传
          messageNotifier.value = '2/4 Uploading securely...';

          final ocrResult = await GlobalUploadService().uploadOcrScan(
            filePath: imagePath,
            module: UploadModule.kyc,
            cancelToken: CancelToken(),
            onProgress: updateProgress,
          );

          // Step 3/4: AI 解析
          messageNotifier.value = '3/3 Extracting info (AI)...';
          await Future.delayed(const Duration(milliseconds: 200));

          ocrResult.copyWith(
            idCardFront: imagePath
          );

          return ocrResult;
        },
      ).then((result) {
        successResult = result;
      });
    } catch (e) {
      errorReason = e;
      debugPrint("Kyc Upload Error: $e");
    }

    // ---- 如果 OCR 成功，先做风控拦截 ----
    if (successResult != null) {
      var r = successResult!;
      try {
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
       // r = r.copyWith(selectedTypeId: selectedType.typeId);
      } catch (_) {
        // TODO: 如果你暂时没有 copyWith/selectedTypeId，
        // 你可以在确认页里另外传 selectedType.typeId
      }

      final score = r.fraudScore;
      final suspicious = r.isSuspicious == true;

      // 1) 高风险：直接拦截，不进入确认页
      if (suspicious || score >= kFraudBlockScore) {
        if (mounted) {
          //_showFraudBlockedDialog(context, r);
        }
        return null;
      }

      // 2) 中风险：警告 + 用户选择继续/重拍
      if (score >= kFraudWarnScore) {
        final goOn = await _showFraudWarningDialog(context, r);
        if (!goOn) return null;
      }

      return r;
    }

    // ---- 失败处理 ----
    if (globalContext.mounted) {
      _handleUploadError(globalContext, errorReason);
    }
    return null;
  }

  void _handleUploadError(BuildContext targetContext, Object? error) {
    if (error == 'GUARD_CHECK_FAILED') {
      RadixModal.show(
        title: 'No valid ID detected',
        cancelText: 'Close',
        builder: (_, __) => Text(
          'Please make sure:\n'
              '• The ID is inside the frame\n'
              '• Text is clear and not blurry\n'
              '• No strong glare / reflection\n'
              '• Use the original physical ID (no screenshots)',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1F2937)),
        ),
      );
      return;
    }

    if (error is DioException && CancelToken.isCancel(error)) {
      _toast(targetContext, 'Upload cancelled.');
      return;
    }

    if (error != null) {
      final msg = (error == 'UPLOAD_FAILED')
          ? 'Upload failed. Please check your network and try again.'
          : 'Something went wrong: $error';
      ScaffoldMessenger.of(targetContext).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _toast(targetContext, 'Failed to process. Please try again.');
  }

  Future<void>
  _additionalInformation(BuildContext context, KycOcrResult data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KycInformationConfirmPage(kycOcrResult: data),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _livenessDetection(context);
    } else if (result == false) {
      _toast(context, 'Cancelled confirmation.');
    }
  }

  void _livenessDetection(BuildContext context) {
    ref.read(livenessNotifierProvider.notifier).startDetection(context);
  }

  // -----------------------
  //  Fake interception UI
  // -----------------------

  void _showFraudBlockedDialog(BuildContext context, KycOcrResult r) {
    final reason = (r.fraudReason != null && r.fraudReason!.trim().isNotEmpty)
        ? r.fraudReason!.trim()
        : 'We detected signs of screenshot / glare / edited image.';

    RadixModal.show(
      title: 'ID photo not accepted',
      cancelText: 'Close',
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'For security reasons, we can’t accept this ID photo.\n\n'
                'Risk score: ${r.fraudScore.toStringAsFixed(0)}\n\n'
                'Reason:\n$reason\n\n'
                'Please retake the photo and make sure:',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1F2937)),
          ),
          SizedBox(height: 12.h),
          _bullet('Use the original physical ID (no screenshots)'),
          _bullet('Avoid glare / reflections'),
          _bullet('Keep the whole ID inside the frame'),
          _bullet('Ensure text is readable and not blurry'),
        ],
      ),
    );
  }

  Future<bool> _showFraudWarningDialog(BuildContext context, KycOcrResult r) async {
    final reason = (r.fraudReason != null && r.fraudReason!.trim().isNotEmpty)
        ? r.fraudReason!.trim()
        : 'We detected something unusual in the photo.';

    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('Photo quality warning'),
        message: Text(
          'Risk score: ${r.fraudScore.toStringAsFixed(0)}\n\n'
              '$reason\n\n'
              'You can retake the photo, or continue (it may be rejected later).',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx, true),
            child: const Text('Continue'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx, false),
          isDestructiveAction: true,
          child: const Text('Retake photo'),
        ),
      ),
    );
    return ok == true;
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Icon(
              Icons.circle,
              size: 6.w,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF374151),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------
// UI Steps
// -----------------------

class _StepList extends StatelessWidget {
  const _StepList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        _StepItem(
          title: '${'common.step'.tr()} 1',
          subTitle: 'Scan your ID',
          description: 'Use the camera to scan your ID. Make sure it is clear and not blurry.',
          detail: _buildStep1Detail(context),
          completed: false,
          img: 'assets/images/verify/step1.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'Confirm your information',
          description: 'We will extract your name and ID number automatically. Please check carefully before submitting.',
          completed: false,
          img: 'assets/images/verify/step2.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 3',
          subTitle: 'Take a selfie (Liveness)',
          description: 'We will do a quick selfie check to confirm you are the real owner of the ID.',
          completed: false,
          img: 'assets/images/verify/step3.png',
        ),
      ],
    );
  }

  Widget _buildStep1Detail(BuildContext context) {
    final tips = [
      'Use the original physical ID (no screenshots)',
      'Avoid glare / reflection',
      'Keep the whole ID inside the frame',
      'Ensure text is readable',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14.h),
        Text(
          'Tips',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.textPrimary900,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        ...tips.map(
              (t) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textSecondary700,
                      height: 1.35,
                    ),
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
              completed
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
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
            color: context.textPrimary900,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: detail ??
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                      height: 1.35,
                    ),
                  ),
            ),
            SizedBox(width: 8.w),
            Image.asset(img, width: 112.w, height: 70.h, fit: BoxFit.contain),
          ],
        ),
      ],
    );
  }
}