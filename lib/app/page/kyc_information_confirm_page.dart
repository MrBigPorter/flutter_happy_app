import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/form/fields/lf_input.dart';
import 'package:flutter_app/ui/form/fields/lf_wheel_select.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/form/kyc_forms/kyc_information_confirm_forms.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/models/region_providers.dart';
import '../../core/providers/liveness_provider.dart';
import '../../utils/form/validation/kKycValidationMessages.dart';

class KycInformationConfirmPage extends ConsumerStatefulWidget {
  final KycOcrResult kycOcrResult;

  const KycInformationConfirmPage({super.key, required this.kycOcrResult});

  @override
  ConsumerState<KycInformationConfirmPage> createState() =>
      _KycInformationConfirmPageState();
}

class _KycInformationConfirmPageState
    extends ConsumerState<KycInformationConfirmPage> {
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
    _prefillFromOcr(widget.kycOcrResult);
    _setupRealNameAutoFill();
  }

  void _prefillFromOcr(KycOcrResult ocr) {
    // country -> countryCode（你现在模型只有 countryCode）
    // PH: 63 / CN: 86 / VN: 84 / default: 63
    final cc = _mapCountryToCode(ocr.country);


    kycForm.form.patchValue({
      'typeText': ocr.typeText,

      'firstName': ocr.firstName,
      'middleName': ocr.middleName,
      'lastName': ocr.lastName,
      'fullName': ocr.realName,

      'idNumber': ocr.idNumber ?? '',
      'birthday': DateFormatHelper.format(ocr.birthday, 'yyyy-MM-dd'),
      'gender': (ocr.gender ?? 'UNKNOWN'),

      'countryCode': cc,

      // expiryDate 可能为空
      'expiryDate': DateFormatHelper.format(ocr.expiryDate, 'yyyy-MM-dd'),
    });

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
    // 只要名字变动就自动更新 realName
    void sync() {
      final first = kycForm.firstNameControl.value ?? '';
      final middle = kycForm.middleNameControl.value;
      final last = kycForm.lastNameControl.value ?? '';
      final rn = _joinName(first, middle, last);
      // 避免频繁 set 同样值
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

  void submit() async {
    kycForm.form.markAllAsTouched();
    if (!kycForm.form.valid) return;

    final confirmed = kycForm.model;

    // TODO: 这里你可以把 confirmed 转成 SubmitKycDto 再 call API
    // 注意：idNumber / realName 都是你最终 submit 的关键字段
    debugPrint('Confirmed: ${confirmed.idNumber}, ${confirmed.realName}');

   final sessionId =  await _livenessDetection(context);
   

   final data = SubmitKycDto(
     sessionId: sessionId!,
     idType: widget.kycOcrResult.type,
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
     idCardFront: widget.kycOcrResult.idCardFront,
     idCardBack: widget.kycOcrResult.idCardBack,
     ocrRawData: widget.kycOcrResult.toJson(),
   );

   final kycResponseData = await GlobalUploadService().submitKyc(
      frontPath: widget.kycOcrResult.idCardFront!,
      backPath: widget.kycOcrResult.idCardBack,
      bodyData: data.toJson(),
   );

   if(!mounted) return;
    if(KycStatusEnum.fromStatus(kycResponseData.kycStatus) == KycStatusEnum.reviewing){
     // Navigate to KYC Status Page
      Navigator.of(context).pushReplacementNamed('/home');
    }

  }

  Future<String?> _livenessDetection(context) async{
   return ref.read(livenessNotifierProvider.notifier).startDetection(context);
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provinceProvider);
    final liveness = ref.watch(livenessNotifierProvider);

    return BaseScaffold(
      title: 'information-confirm'.tr(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ReactiveFormConfig(
            validationMessages: kKycValidationMessages,
            child: ReactiveForm(
              formGroup: kycForm.form,
              child: Column(
                children: [
                  SizedBox(height: 20.h),

                  LfInput(name: 'typeText', label: 'ID Type', readOnly: true),

                  SizedBox(height: 16.h),
                  LfInput(name: 'idNumber', label: 'ID Number', required: true),

                  SizedBox(height: 16.h),
                  LfInput(name: 'firstName', label: 'First Name'),
                  SizedBox(height: 16.h),
                  LfInput(name: 'middleName', label: 'Middle Name'),
                  SizedBox(height: 16.h),
                  LfInput(name: 'lastName', label: 'Last Name'),

                  SizedBox(height: 16.h),
                  LfInput(name: 'realName', label: 'Full Name', readOnly: true),

                  SizedBox(height: 16.h),
                  LfInput(
                    name: 'birthday',
                    label: 'Birthday (Adult Only, 21+)',
                    readOnly: true,
                  ),
                  SizedBox(height: 16.h),
                  LfInput(name: 'gender', label: 'Gender', readOnly: true),

                  SizedBox(height: 16.h),
                  LfWheelSelect(
                    name: 'province',
                    label: 'Province',
                    placeholder: 'Select your province',
                    required: true,
                    isLoading:
                    provincesAsync.isLoading || !provincesAsync.hasValue,
                    options: provincesAsync.when(
                      data: (list) => list,
                      error: (_, __) => [],
                      loading: () => [
                        (text: 'Loading...', value: -1, disabled: true),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),
                  ReactiveValueListenableBuilder<int>(
                    formControlName: 'province',
                    builder: (context, provinceControl, child) {
                      final provinceId = provinceControl.value;
                      final citiesAsync = ref.watch(cityProvider(provinceId ?? -1));
                      return LfWheelSelect(
                        name: 'city',
                        label: 'City',
                        placeholder: 'Select your city',
                        required: true,
                        isLoading:
                        citiesAsync.isLoading || !citiesAsync.hasValue,
                        options: citiesAsync.when(
                          data: (list) => list,
                          error: (_, __) => [],
                          loading: () => [
                            (text: 'Loading...', value: -1, disabled: true),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),
                  ReactiveValueListenableBuilder<int>(
                    formControlName: 'city',
                    builder: (context, cityControl, child) {
                      final cityId = cityControl.value;
                      final barangaysAsync =
                      ref.watch(barangaysProvider(cityId ?? -1));
                      return LfWheelSelect(
                        name: 'barangay',
                        label: 'Barangay',
                        placeholder: 'Select your barangay',
                        required: true,
                        isLoading:
                        barangaysAsync.isLoading || !barangaysAsync.hasValue,
                        options: barangaysAsync.when(
                          data: (list) => list,
                          error: (_, __) => [],
                          loading: () => [
                            (text: 'Loading...', value: -1, disabled: true),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),
                  LfInput(name: 'address', label: 'Address', required: true),

                  SizedBox(height: 16.h),
                  LfInput(name: 'postalCode', label: 'Postal Code', required: true),

                  SizedBox(height: 16.h),
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
            loading: liveness.isLoading,
            onPressed: submit,
            child: Text(
              'common.confirm'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}