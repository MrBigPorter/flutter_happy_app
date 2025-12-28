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
  // 风险阈值配置
  static const double kFraudBlockScore = 60.0;
  static const double kFraudWarnScore = 30.0;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'kyc-verify'.tr(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 140.h,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Button(
            loading: kycTypeAsyncValue.isLoading,
            onPressed: _onStartKycPressed,
            child: Text(
              'start-now'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 核心流程控制 (Main Flow)
  // =========================================================

  Future<void> _onStartKycPressed() async {
    // 1. 获取证件类型配置
    final options = await ref.read(kycIdTypeProvider.future);
    if (!mounted) return;

    // 2. 弹出选择框
    final selectedType = await RadixSheet.show<KycIdTypes>(
      builder: (_, close) => SelectIdType(options: options),
    );

    if (!mounted) return;
    if (selectedType == null) {
      // 用户主动取消，不需要报错
      return;
    }

    // 3. 执行核心任务：拍照 -> 上传 -> OCR
    // 捕获所有可能的异常，防止按钮卡死
    try {
      final ocrResult = await _performScanAndUploadFlow(selectedType);

      if (ocrResult == null) return; // 过程中失败或取消

      // 4. 风控检查
      final isSafe = await _validateRiskScore(ocrResult);
      if (!isSafe || !mounted) return;

      // 5. 跳转确认页
      await _navigateToConfirm(ocrResult);

    } catch (e) {
      debugPrint("KYC Flow Error: $e");
      if (mounted) _handleGeneralError(e);
    }
  }

  // =========================================================
  // 子任务模块 (Sub-tasks)
  // =========================================================

  /// 任务：拍照 + 上传 (返回 OCR 结果，如果失败返回 null)
  Future<KycOcrResult?> _performScanAndUploadFlow(KycIdTypes type) async {
    // A. 打开相机
    final imagePath = await LivenessService.scanDocument(context);
    if (imagePath == null) {
      // 用户取消拍照
      return null;
    }

    if (!mounted) return null;

    // 获取全局 Context 用于弹窗 (防止当前页面 pop 后 dialog 消失)
    final globalContext = NavHub.key.currentContext;
    if (globalContext == null) throw 'UI_CONTEXT_LOST';

    final messageNotifier = ValueNotifier<String>('Preparing...');

    // B. 显示进度条并执行上传
    try {
      return await UploadProgressDialog.show<KycOcrResult>(
        globalContext,
        messageNotifier: messageNotifier,
        uploadTask: (updateProgress) async {
          // --- 子步骤 1: 本地 Guard 检测 ---
          messageNotifier.value = '1/3 Checking photo quality...';
          await Future.delayed(const Duration(milliseconds: 200));

          final bool isPass = await UnifiedKycGuard().check(imagePath, KycDocType.idCard);
          if (!isPass) throw 'GUARD_CHECK_FAILED';

          // --- 子步骤 2: 上传 OCR ---
          messageNotifier.value = '2/3 Uploading securely...';

          // 调用 Service 上传
          var result = await GlobalUploadService().uploadOcrScan(
            filePath: imagePath,
            module: UploadModule.kyc,
            // 传入 CancelToken 允许用户取消上传
            cancelToken: CancelToken(),
            onProgress: updateProgress,
          );

          // --- 子步骤 3: 结果处理 ---
          messageNotifier.value = '3/3 Finalizing...';

          // 补全本地图片路径 (因为后端 OCR 不会返回本地路径)
          return result.copyWith(idCardFront: imagePath);
        },
      );
    } catch (e) {
      // 在这里捕获上传过程中的特定错误
      if (mounted) _handleUploadSpecificError(e);
      return null; // 返回空表示流程中断
    }
  }

  /// 任务：风控检查 (返回 true=通过, false=拦截)
  Future<bool> _validateRiskScore(KycOcrResult r) async {
    final score = r.fraudScore;
    final suspicious = r.isSuspicious == true;

    // 情况 A: 高风险 -> 直接拦截
    if (suspicious || score >= kFraudBlockScore) {
      _showFraudBlockedDialog(r);
      return false;
    }

    // 情况 B: 中风险 -> 警告但允许继续
    if (score >= kFraudWarnScore) {
      final userWantsToContinue = await _showFraudWarningDialog(r);
      return userWantsToContinue;
    }

    // 情况 C: 低风险 -> 自动通过
    return true;
  }

  /// 任务：跳转
  Future<void> _navigateToConfirm(KycOcrResult data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KycInformationConfirmPage(kycOcrResult: data),
      ),
    );

    if (result == true && mounted) {
      // 如果确认页返回 true，说明提交成功，可以做活体或者结束
      // _startLiveness();
    }
  }

  // =========================================================
  // 错误处理模块 (Error Handling)
  // =========================================================

  void _handleUploadSpecificError(Object error) {
    if (!mounted) return;

    if (error == 'GUARD_CHECK_FAILED') {
      RadixModal.show(
        title: 'Please retake photo',
        cancelText: 'OK',
        builder: (_, __) => const Text('Make sure the ID is inside the frame and clearly visible.'),
      );
    } else if (error is DioException && CancelToken.isCancel(error)) {
      // 用户取消，忽略
    } else {
      // 其他网络错误
      _toast('Upload failed. Please check connection.');
    }
  }

  void _handleGeneralError(Object error) {
    // 处理未预料到的异常
    _toast('Something went wrong. Please try again.');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =========================================================
  // 弹窗 UI 模块 (Dialogs)
  // =========================================================

  void _showFraudBlockedDialog(KycOcrResult r) {
    if (!mounted) return;
    final reason = r.fraudReason ?? 'Potential screen capture or editing detected.';

    RadixModal.show(
      title: 'ID Verification Failed',
      cancelText: 'Close',
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('We cannot accept this ID photo due to security reasons.', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('Reason: $reason'),
          SizedBox(height: 8.h),
          Text('Please use the original physical ID card.', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Future<bool> _showFraudWarningDialog(KycOcrResult r) async {
    if (!mounted) return false;
    // 使用 iOS 风格 ActionSheet 或 Material Dialog 让用户选
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Photo Quality Warning'),
        message: Text('The ID photo looks a bit blurry or suspicious.\nRisk Score: ${r.fraudScore}'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Continue Anyway'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Retake Photo'),
        ),
      ),
    );
    return result ?? false;
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