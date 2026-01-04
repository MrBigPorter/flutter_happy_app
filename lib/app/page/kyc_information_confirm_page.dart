import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/ui/form/fields/lf_wheel_select.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/form/kyc_forms/kyc_information_confirm_forms.dart';

// 记得引入 API
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/models/region_providers.dart';
import '../../core/providers/liveness_provider.dart';
import '../../utils/form/validation/k_kyc_validation_messages.dart';
import 'kyc_status_page.dart';

class KycInformationConfirmPage extends ConsumerStatefulWidget {
  final KycOcrResult kycOcrResult;

  const KycInformationConfirmPage({super.key, required this.kycOcrResult});

  @override
  ConsumerState<KycInformationConfirmPage> createState() =>
      _KycInformationConfirmPageState();
}

class _KycInformationConfirmPageState
    extends ConsumerState<KycInformationConfirmPage> {
  // 1. Loading 锁
  bool _isSubmitting = false;

  late final KycInformationConfirmModelForm kycForm =
      KycInformationConfirmModelForm(
        KycInformationConfirmModelForm.formElements(
          const KycInformationConfirmModel(),
        ),
        null,
      );

  @override
  void initState() {
    super.initState();
    _setupResetListeners();
    // 稍后执行回填，避免构建未完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromOcr(widget.kycOcrResult);
    });
    _setupRealNameAutoFill();
  }

  // ----------------------------------------------------------
  // 数据回填
  // ----------------------------------------------------------
  void _prefillFromOcr(KycOcrResult ocr) {
    final cc = _mapCountryToCode(ocr.country);

    kycForm.form.patchValue({
      // 关键：同时回填 type (int) 和 typeText (String)
      'type': ocr.type,
      'typeText': ocr.typeText ,

      'firstName': ocr.firstName,
      'middleName': ocr.middleName,
      'lastName': ocr.lastName,
      'fullName': ocr.realName,
      'idNumber': ocr.idNumber ?? '',
      'gender': (ocr.gender ?? 'UNKNOWN'),
      'countryCode': cc,
      'birthday': _safeFormatDate(ocr.birthday),
      'expiryDate': _safeFormatDate(ocr.expiryDate),
    });
  }

  String _safeFormatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      // 兼容 int (时间戳) 或 String (日期字符串)
      if (rawDate is int) {
        return DateFormatHelper.format(rawDate, 'yyyy-MM-dd');
      } else if (rawDate is String && rawDate.isNotEmpty) {
        // 如果已经是 yyyy-MM-dd 格式，直接返回，或者尝试解析
        return rawDate;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  int _mapCountryToCode(String country) {
    final c = country.trim().toUpperCase();
    if (c == 'PH') return 63;
    if (c == 'CN') return 86;
    if (c == 'VN') return 84;
    return 63;
  }

  // ----------------------------------------------------------
  // 联动逻辑
  // ----------------------------------------------------------
  String _joinName(String first, String? middle, String last) {
    final parts = <String>[
      first.trim(),
      (middle ?? '').trim(),
      last.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' ');
  }

  void _setupRealNameAutoFill() {
    void sync() {
      final first = kycForm.firstNameControl.value ?? '';
      final middle = kycForm.middleNameControl.value;
      final last = kycForm.lastNameControl.value ?? '';
      final rn = _joinName(first, middle, last);
      if ((kycForm.realNameControl.value ?? '') != rn) {
        kycForm.realNameControl.updateValue(rn);
      }
    }

    kycForm.firstNameControl.valueChanges.listen((_) => sync());
    kycForm.middleNameControl.valueChanges.listen((_) => sync());
    kycForm.lastNameControl.valueChanges.listen((_) => sync());
  }

  void _setupResetListeners() {
    kycForm.provinceControl.valueChanges.listen((_) {
      kycForm.cityControl.reset();
      kycForm.barangayControl.reset();
    });
    kycForm.cityControl.valueChanges.listen((_) {
      kycForm.barangayControl.reset();
    });
  }

  // ----------------------------------------------------------
  // 提交逻辑
  // ----------------------------------------------------------
  Future<void> submit() async {
    kycForm.form.markAllAsTouched();
    if (!kycForm.form.valid) {
      // 打印错误日志，方便调试哪个字段没填
      debugPrint("Form Invalid Errors: ${kycForm.form.errors}");
      kycForm.form.controls.forEach((key, value) {
        if (value.invalid) {
          debugPrint("Invalid Field: $key, Errors: ${value.errors}");
        }
      });
      _showToast('Please check the highlighted fields.');
      return;
    }

    if (_isSubmitting) return;

    final confirmGo = await _showFinalConfirmDialog();
    if (!confirmGo) return;

    try {
      // 1. 活体检测
      final sessionId = await ref
          .read(livenessNotifierProvider.notifier)
          .startDetection(context);

      if (sessionId == null || sessionId.isEmpty) return;

      setState(() => _isSubmitting = true);

      final confirmed = kycForm.model;

      // 2. 构造 DTO
      final dto = SubmitKycDto(
        sessionId: sessionId,
        // 这里确保 confirmed.type 有值，或者 fallback 到 widget.kycOcrResult.type
        idType: confirmed.type,
        idNumber: confirmed.idNumber,
        realName: confirmed.realName,
        firstName: confirmed.firstName,
        middleName: confirmed.middleName,
        lastName: confirmed.lastName,
        birthday: confirmed.birthday,
        gender: confirmed.gender,
        countryCode: confirmed.countryCode,
        expiryDate: confirmed.expiryDate,
        provinceId: confirmed.province!,
        cityId: confirmed.city!,
        barangayId: confirmed.barangay!,
        address: confirmed.address,
        postalCode: confirmed.postalCode!,
        // 文件路径
        idCardFront: widget.kycOcrResult.idCardFront!,
        idCardBack: widget.kycOcrResult.idCardBack,
        ocrRawData: widget.kycOcrResult.toJson(),
      );

      // 3. API 调用
      await Api.kycSubmitApi(dto);

      if (!mounted) return;

      // 4. 跳转
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const KycStatusPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("KYC Submit Error: $e");
      if (mounted) {
        _showErrorDialog('Submission Failed', 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ----------------------------------------------------------
  // UI 辅助
  // ----------------------------------------------------------
  Future<void> _onWillPop(bool didPop) async {
    if (didPop || _isSubmitting) return;
    RadixModal.show(
      title: 'Discard Changes?',
      builder: (_, __) =>
          const Text('If you go back now, you will lose all information.'),
      cancelText: 'Cancel',
      confirmText: 'Discard',
      onConfirm: (close) {
        Navigator.pop(context);
      },
    );
  }

  void _handlePopInvocation(bool didPop, dynamic result) {
    // 如果 didPop 为 true，说明页面已经被 pop 了（比如你手动调用了 Navigator.pop）
    // 此时直接 return，避免重复弹窗或逻辑死循环
    if (didPop || _isSubmitting) return;

    // 这里的逻辑是：用户触发了物理返回/手势，但被 PopScope 拦截了
    RadixModal.show(
      title: 'Discard Changes?',
      builder: (_, __) =>
      const Text('If you go back now, you will lose all information.'),
      cancelText: 'Cancel',
      confirmText: 'Discard',
      onConfirm: (close) {
        close(); // 关闭弹窗
        // 关键：手动调用 Navigator.pop，此时由于 pop 是你主动触发的，
        // 页面会真正退出。
        Navigator.of(context).pop();
      },
    );
  }

  Future<bool> _showFinalConfirmDialog() async {
    return await RadixModal.show<bool>(
          title: 'Confirm Submission',
          builder: (_, __) =>
              const Text('Ensure all details match your ID exactly.'),
          cancelText: 'Review',
          confirmText: 'Submit',
          onConfirm: (close) {
            close(true);
          },
        ) ??
        false;
  }

  void _showErrorDialog(String title, String msg) {
    RadixModal.show(
      title: title,
      builder: (_, __) => Text(msg),
      cancelText: 'Close',
    );
  }

  void _showToast(String msg) {
    RadixToast.error(msg);
  }

  // ----------------------------------------------------------
  // 完整 Build 方法 (补全了所有字段)
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provinceProvider);
    final liveness = ref.watch(livenessNotifierProvider);

    return PopScope(
      canPop: false,
      child: BaseScaffold(
        title: 'Information Confirm', // 暂时硬编码避免 key not found
        showBack: false, // 隐藏 LuckyAppBar 那个不听话的返回键
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => _handlePopInvocation(false, null),
          )
        ],
        resizeToAvoidBottomInset: true, // 关键：键盘弹出时允许页面上顶
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: ReactiveFormConfig(
            validationMessages: kKycValidationMessages,
            child: ReactiveForm(
              formGroup: kycForm.form,
              child: IgnorePointer(
                ignoring: _isSubmitting,
                child: Column(
                  children: [
                    // 1. 证件类型 (只读)
                    LfInput(name: 'typeText', label: 'ID Type', readOnly: true),
                    SizedBox(height: 16.h),

                    // 2. 证件号码
                    LfInput(
                      name: 'idNumber',
                      label: 'ID Number',
                      required: true,
                    ),
                    SizedBox(height: 16.h),

                    // 3. 姓名部分
                    Row(
                      children: [
                        Expanded(
                          child: LfInput(
                            name: 'firstName',
                            label: 'First Name',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: LfInput(name: 'lastName', label: 'Last Name'),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    LfInput(
                      name: 'middleName',
                      label: 'Middle Name (Optional)',
                    ),
                    SizedBox(height: 16.h),

                    // 全名预览 (只读)
                    LfInput(
                      name: 'realName',
                      label: 'Full Name Preview',
                      readOnly: true,
                    ),
                    SizedBox(height: 16.h),

                    // 4. 生日与性别
                    LfInput(
                      name: 'birthday',
                      label: 'Birthday (YYYY-MM-DD)',
                      readOnly: true, // 建议只读，点开选日期，或者允许手输但要校验
                    ),
                    SizedBox(height: 16.h),
                    LfInput(name: 'gender', label: 'Gender', readOnly: true),
                    SizedBox(height: 16.h),

                    LfWheelSelect(
                      name: 'province',
                      label: 'Province',
                      placeholder: 'Select Province',
                      required: true,
                      isLoading: provincesAsync.isLoading,
                      options: provincesAsync.when(
                        data: (list) => list,
                        error: (_, __) => [],
                        loading: () => [],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    ReactiveValueListenableBuilder<int>(
                      formControlName: 'province',
                      builder: (context, control, child) {
                        final provinceId = control.value;
                        // 如果没选省，就传 -1 或不加载
                        final citiesAsync = ref.watch(
                          cityProvider(provinceId ?? -1),
                        );
                        return LfWheelSelect(
                          name: 'city',
                          label: 'City',
                          placeholder: 'Select City',
                          required: true,
                          // 只有选了省才启用
                          isLoading: citiesAsync.isLoading,
                          options: citiesAsync.when(
                            data: (list) => list,
                            error: (_, __) => [],
                            loading: () => [],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    ReactiveValueListenableBuilder<int>(
                      formControlName: 'city',
                      builder: (context, control, child) {
                        final cityId = control.value;
                        final barangaysAsync = ref.watch(
                          barangaysProvider(cityId ?? -1),
                        );
                        return LfWheelSelect(
                          name: 'barangay',
                          label: 'Barangay',
                          placeholder: 'Select Barangay',
                          required: true,
                          isLoading: barangaysAsync.isLoading,
                          options: barangaysAsync.when(
                            data: (list) => list,
                            error: (_, __) => [],
                            loading: () => [],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    // 6. 详细地址与邮编
                    LfInput(
                      name: 'address',
                      label: 'Detailed Address',
                      required: true,
                    ),
                    SizedBox(height: 16.h),
                    LfInput(
                      name: 'postalCode',
                      label: 'Postal Code',
                      required: true,
                    ),

                    // 底部留白，防止被按钮遮挡
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: context.bgPrimary,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SafeArea(
            top: false,
            child: Button(
              height: 48.h,
              loading: liveness.isLoading || _isSubmitting,
              onPressed: (_isSubmitting || liveness.isLoading) ? null : submit,
              child: Text(
                'Confirm',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
