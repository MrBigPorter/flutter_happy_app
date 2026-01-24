import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/ui/form/fields/lf_wheel_select.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/form/kyc_forms/kyc_information_confirm_forms.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromOcr(widget.kycOcrResult);
    });
    _setupRealNameAutoFill();
  }

  void _prefillFromOcr(KycOcrResult ocr) {
    final cc = _mapCountryToCode(ocr.country);

    kycForm.form.patchValue({
      'type': ocr.type,
      'typeText': ocr.typeText,
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
      if (rawDate is int) {
        return DateFormatHelper.format(rawDate, 'yyyy-MM-dd');
      } else if (rawDate is String && rawDate.isNotEmpty) {
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
      final middle = kycForm.middleNameControl?.value;
      final last = kycForm.lastNameControl.value ?? '';
      final rn = _joinName(first, middle, last);
      if ((kycForm.realNameControl.value ?? '') != rn) {
        kycForm.realNameControl.updateValue(rn);
      }
    }

    kycForm.firstNameControl.valueChanges.listen((_) => sync());
    kycForm.middleNameControl?.valueChanges.listen((_) => sync());
    kycForm.lastNameControl.valueChanges.listen((_) => sync());
  }

  void _setupResetListeners() {
    kycForm.provinceControl?.valueChanges.listen((_) {
      kycForm.cityControl?.reset();
      kycForm.barangayControl?.reset();
    });
    kycForm.cityControl?.valueChanges.listen((_) {
      kycForm.barangayControl?.reset();
    });
  }

  Future<void> submit() async {
    kycForm.form.markAllAsTouched();
    if (!kycForm.form.valid) {
      debugPrint("Form Invalid Errors: ${kycForm.form.errors}");
      _showToast('Please check the highlighted fields.');
      return;
    }

    if (_isSubmitting) return;

    final confirmGo = await _showFinalConfirmDialog();
    if (!confirmGo) return;

    try {
      final sessionId = await ref
          .read(livenessNotifierProvider.notifier)
          .startDetection(context);

      if (sessionId == null || sessionId.isEmpty) return;

      setState(() => _isSubmitting = true);

      // 获取当前表单值模型
      final confirmed = kycForm.model;

      final dto = SubmitKycDto(
        sessionId: sessionId,
        // 🛠️ 关键修复：全部加上强转 (as 类型?)，解决 Object 报错
        idType: (confirmed.type as int?) ?? widget.kycOcrResult.type,
        idNumber: (confirmed.idNumber as String?) ?? '',
        realName: (confirmed.realName as String?) ?? '',
        firstName: (confirmed.firstName as String?) ?? '',
        middleName: confirmed.middleName ?? '',
        lastName: (confirmed.lastName as String?) ?? '',
        birthday: (confirmed.birthday as String?) ?? '',
        gender: (confirmed.gender as String?) ?? '',
        countryCode: (confirmed.countryCode as int?) ?? 63,
        expiryDate: confirmed.expiryDate ?? '',

        // 🛠️ 修复报错的核心位置
        provinceId: confirmed.province ?? 0,
        cityId: confirmed.city ?? 0,
        barangayId: confirmed.barangay ?? 0,

        address: (confirmed.address as String?) ?? '',
        postalCode: confirmed.postalCode ?? null,

        idCardFront: widget.kycOcrResult.idCardFront!,
        idCardBack: widget.kycOcrResult.idCardBack,
        ocrRawData: widget.kycOcrResult.toJson(),
      );

      await Api.kycSubmitApi(dto);

      if (!mounted) return;

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

  void _handlePopInvocation(bool didPop, dynamic result) {
    if (didPop || _isSubmitting) return;
    RadixModal.show(
      title: 'Discard Changes?',
      builder: (_, __) =>
      const Text('If you go back now, you will lose all information.'),
      cancelText: 'Cancel',
      confirmText: 'Discard',
      onConfirm: (close) {
        close();
        Navigator.of(context).pop();
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provinceProvider);
    final liveness = ref.watch(livenessNotifierProvider);

    return PopScope(
      canPop: false,
      child: BaseScaffold(
        title: 'Information Confirm',
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => _handlePopInvocation(false, null),
          )
        ],
        resizeToAvoidBottomInset: true,
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
                    LfInput(name: 'typeText', label: 'ID Type', readOnly: true),
                    SizedBox(height: 16.h),
                    LfInput(
                      name: 'idNumber',
                      label: 'ID Number',
                      required: true,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: LfInput(
                            name: 'firstName',
                            label: 'First Name',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(child: LfInput(name: 'lastName', label: 'Last Name')),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    LfInput(
                      name: 'middleName',
                      label: 'Middle Name (Optional)',
                    ),
                    SizedBox(height: 16.h),
                    LfInput(
                      name: 'realName',
                      label: 'Full Name Preview',
                      readOnly: true,
                    ),
                    SizedBox(height: 16.h),
                    LfInput(
                      name: 'birthday',
                      label: 'Birthday (YYYY-MM-DD)',
                      readOnly: true,
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
                        final citiesAsync = ref.watch(
                          cityProvider(provinceId ?? -1),
                        );
                        return LfWheelSelect(
                          name: 'city',
                          label: 'City',
                          placeholder: 'Select City',
                          required: true,
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