import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/form/fields/lf_input.dart';
import 'package:flutter_app/utils/form/kyc_forms/kyc_information_confirm_forms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
    // Pre-fill the form with data from kycOcrResult
    final ocr = widget.kycOcrResult;
    print("OCR Result: $ocr");
    kycForm.form.patchValue({
      'idType': ocr.idType,
      'firstName': ocr.firstName,
      'middleName': ocr.middleName,
      'lastName': ocr.lastName,
      'birthday': ocr.birthday,
       'country': ocr.country,
    });

  }


  void submit() {
    kycForm.form.markAllAsTouched();
    if (kycForm.form.valid) {
      // Process the confirmed information
      final confirmedData = kycForm.model;
      // You can now use confirmedData as needed
      print('Confirmed Data: $confirmedData');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'information-confirm'.tr(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ReactiveFormConfig(
            validationMessages: kKycValidationMessages,
            child: ReactiveForm(
              formGroup: kycForm.form,
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  LfInput(name: 'idType', label: 'ID Type', readOnly: true),
                  SizedBox(height: 16.h),
                  LfInput(
                    name: 'firstName',
                    label: 'First Name',
                    readOnly: true,
                  ),
                  SizedBox(height: 16.h),
                  LfInput(
                    name: 'middleName',
                    label: 'Middle Name',
                    readOnly: true,
                  ),
                  SizedBox(height: 16.h),
                  LfInput(name: 'lastName', label: 'Last Name', readOnly: true),
                  SizedBox(height: 16.h),
                  LfInput(
                    name: 'birthday',
                    label: 'Birthday (Adult Only, 21+)',
                    readOnly: true,
                  ),
                  SizedBox(height: 16.h),
                  LfInput(name: 'gender', label: 'Gender', readOnly: true),
                  SizedBox(height: 16.h),
                  LfInput(name: 'province', label: 'Province', required: true),
                  SizedBox(height: 16.h),
                  LfInput(name: 'city', label: 'City', required: true),
                  SizedBox(height: 16.h),
                  LfInput(name: 'address', label: 'Address', required: true),
                  SizedBox(height: 16.h),
                  LfInput(
                    name: 'postalCode',
                    label: 'Postal Code',
                    required: true,
                  ),
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
