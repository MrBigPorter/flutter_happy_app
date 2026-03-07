part of 'kyc_verify_page.dart';

/// 剥离所有业务逻辑到 Mixin 中
mixin KycVerifyLogic on ConsumerState<KycVerifyPage> {
  // 风险阈值配置
  static const double kFraudBlockScore = 60.0;
  static const double kFraudWarnScore = 30.0;

  KycOcrResult? scannedData;

  @override
  void initState() {
    super.initState();
    // 页面渲染完的一瞬间，检查状态并弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatusAndShowDialog();
    });
  }

  Future<void> _navigateToConfirm(KycOcrResult data) async {
    if (mounted) {
      setState(() {
        scannedData = data;
      });
    }
  }

  //  3. 新增：如果用户在确认页点“放弃”，让他回到扫码页
  void resetToScan() {
    if (mounted) {
      setState(() {
        scannedData = null;
      });
    }
  }

  void _checkStatusAndShowDialog() {
    final kycStatus = ref.read(userProvider.select((s) => s?.kycStatus));
    final statusEnum = KycStatusEnum.fromStatus(kycStatus ?? 0);

    if (statusEnum == KycStatusEnum.reviewing ||
        statusEnum == KycStatusEnum.approved) {
      final isPending = statusEnum == KycStatusEnum.reviewing;

      RadixModal.show(
        config: ModalDialogConfig(showCloseButton: false),
        clickBgToClose: false,
        title: isPending
            ? 'kyc.status.pending.title'.tr()
            : 'kyc.status.approved.title'.tr(),
        cancelText: '',
        confirmText: 'kyc.status.go_back'.tr(),
        onConfirm: (_) {
          appRouter.go('/home');
        },
        builder: (context, close) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPending
                    ? CupertinoIcons.time
                    : CupertinoIcons.checkmark_seal_fill,
                size: 60.w,
                color: isPending
                    ? context.utilityWarning500
                    : context.utilitySuccess500,
              ),
              SizedBox(height: 16.w),
              Text(
                isPending
                    ? 'kyc.status.pending.desc'.tr()
                    : 'kyc.status.approved.desc'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.textSecondary700,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _onStartKycPressed() async {
    debugPrint('KYC: Start button pressed');
    final options = await ref.read(kycIdTypeProvider.future);
    if (!mounted) return;

    final selectedType = await RadixSheet.show<KycIdTypes>(
      builder: (_, close) => SelectIdType(options: options),
    );

    if (!mounted || selectedType == null) return;

    try {
      final ocrResult = await _performScanAndUploadFlow(selectedType);
      if (ocrResult == null) return;

      final isSafe = await _validateRiskScore(ocrResult);
      if (!isSafe || !mounted) return;

      await _navigateToConfirm(ocrResult);
    } catch (e) {
      debugPrint("KYC Flow Error: $e");
      if (mounted) _handleGeneralError(e);
    }
  }

  Future<KycOcrResult?> _performScanAndUploadFlow(KycIdTypes type) async {
    final imagePath = await LivenessService.scanDocument(context);
    if (imagePath == null) return null;
    if (!mounted) return null;

    final globalContext = NavHub.key.currentContext;
    if (globalContext == null) throw 'UI_CONTEXT_LOST';

    final messageNotifier = ValueNotifier<String>('Preparing...');

    try {
      return await UploadProgressDialog.show<KycOcrResult>(
        globalContext,
        messageNotifier: messageNotifier,
        uploadTask: (updateProgress) async {
          messageNotifier.value = '1/3 Checking photo quality...';
          await Future.delayed(const Duration(milliseconds: 200));

          final bool isPass = await UnifiedKycGuard().check(
            imagePath,
            KycDocType.idCard,
          );
          if (!isPass) throw 'GUARD_CHECK_FAILED';

          messageNotifier.value = '2/3 Uploading securely...';
          var result = await GlobalUploadService().uploadOcrScan(
            file: XFile(imagePath),
            module: UploadModule.kyc,
            cancelToken: CancelToken(),
            onProgress: updateProgress,
          );

          messageNotifier.value = '3/3 Finalizing...';
          return result.copyWith(idCardFront: imagePath);
        },
      );
    } catch (e) {
      if (mounted) _handleUploadSpecificError(e);
      return null;
    }
  }

  Future<bool> _validateRiskScore(KycOcrResult r) async {
    final score = r.fraudScore;
    final suspicious = r.isSuspicious == true;

    if (suspicious || score >= kFraudBlockScore) {
      _showFraudBlockedDialog(r);
      return false;
    }
    if (score >= kFraudWarnScore) {
      return await _showFraudWarningDialog(r);
    }
    return true;
  }

  void _handleUploadSpecificError(Object error) {
    if (!mounted) return;
    if (error == 'GUARD_CHECK_FAILED') {
      RadixModal.show(
        title: 'Please retake photo',
        cancelText: 'OK',
        builder: (_, __) => const Text(
          'Make sure the ID is inside the frame and clearly visible.',
        ),
      );
    } else if (error is DioException && CancelToken.isCancel(error)) {
      // Ignore user cancellation
    } else {
      _toast('Upload failed. Please check connection.');
    }
  }

  void _handleGeneralError(Object error) {
    _toast('Something went wrong. Please try again.');
  }

  void _toast(String msg) {
    if (!mounted) return;
    RadixToast.error(msg);
  }

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
          const Text(
            'We cannot accept this ID photo due to security reasons.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text('Reason: $reason'),
          SizedBox(height: 8.h),
          const Text(
            'Please use the original physical ID card.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<bool> _showFraudWarningDialog(KycOcrResult r) async {
    if (!mounted) return false;
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Photo Quality Warning'),
        message: Text(
          'The ID photo looks a bit blurry or suspicious.\nRisk Score: ${r.fraudScore}',
        ),
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