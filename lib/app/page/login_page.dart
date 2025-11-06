import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/form/ui_min.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';


class LoginPage extends StatelessWidget {
   LoginPage({super.key});

  final form = fb.group({
    'phone': ['', Validators.required, Validators.minLength(10)],
    'otp': ['', Validators.required, Validators.minLength(6)],
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: ReactiveForm(
            formGroup: form,
            child: Column(
              children: [
                ReactiveTextField<String>(
                  formControlName: 'phone',
                  keyboardType: TextInputType.phone,
                  validationMessages: lfMessages(
                    required: 'Phone number is required',
                    minLength: 'Phone number must be at least 10 digits',
                  ),
                  decoration: lfDecoration(
                    context,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    helper: 'We will send',
                    prefix: Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Text('+63'),
                    )
                  ),
                ),
                SizedBox(height: 12.w,),
                ReactiveTextField<String>(
                  formControlName: 'otp',
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 1,
                  decoration: lfDecoration(
                    context,
                    hint: 'Enter the OTP sent to your phone',
                  )
                ),
                ReactiveTextField(
                  formControlName: 'otp',
                  keyboardType: TextInputType.number,
                  textAlignVertical: TextAlignVertical.center,
                  validationMessages: lfMessages(
                    required: 'OTP is required',
                    minLength: 'OTP must be at least 6 digits',
                  ),
                  decoration: lfDecoration(
                    context,
                    hint: 'Enter the OTP sent to your phone',
                  ).copyWith(
                    labelText: null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  )
                ),
                SizedBox(height: 12.w,),
                ElevatedButton(
                  onPressed: () {
                    if (form.valid) {
                      // Handle valid form submission
                    } else {
                      form.markAllAsTouched();
                    }
                  },
                  child: Text('Login'),
                ),
              ],
            )
        )
      ),
    );
  }
}