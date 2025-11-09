import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/form/fields/lf_input.dart';
import 'package:flutter_app/ui/form/fields/lf_password.dart';
import 'package:flutter_app/ui/form/fields/lf_select.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../ui/form/fields/lf_checkbox.dart';
import '../../ui/form/fields/lf_date.dart';
import '../../ui/form/fields/lf_radio.dart';
import '../../ui/form/fields/lf_switch.dart';
import '../../ui/form/fields/lf_textarea.dart';


class LoginPage extends StatelessWidget {
   LoginPage({super.key});

   final form = fb.group({
     'phone': ['',  Validators.minLength(10)],
     'password': ['', Validators.required, Validators.minLength(10)],
     'bio': [''],
     'birthday': FormControl<DateTime>(
        value: null,
        validators: [Validators.required],
     ),
     'agree': [false, Validators.requiredTrue],
     'marketing': [true],
     'gender': ['male'],
     'country': FormControl<String>(
       value: null,
       validators: [Validators.required],
     ),
   });


   @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ReactiveForm(
            formGroup: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LfInput(
                  name: 'phone',
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  helper: 'We will send a verification code to this number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('+1'),
                  ),
                  decorationBuilder: (ctx, d) => d.copyWith(
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),

                ),
                LfTextArea(
                    name: 'bio',
                    label: 'About you',
                    hint: 'Tell us something...',
                    helper: 'This will be displayed on your profile',
                ),
                const SizedBox(height: 12),
                LfPassword(
                  name:'password',
                  label: 'Password',
                  hint: 'Enter your password',
                ),

                LfDate(
                  name: 'birthday',
                  label: 'Birthday',
                  hint: 'Select a date',
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                ),
                const SizedBox(height: 12),

                LfCheckbox(name: 'agree', label: 'I agree to the Terms', helper: 'Required to continue',
                  validationMessages: {'required': (_) => 'You must accept the terms'},
                ),
                const SizedBox(height: 8),

                LfSwitch(name: 'marketing', label: 'Email me about product updates'),
                const SizedBox(height: 12),

                LfRadioGroup<String>(
                  name: 'gender',
                  label: 'Gender',
                  helper: 'Pick one',
                  wrap: true,
                  gap: 4.w,
                  options: const [
                    (text: 'Male',   value: 'male',   description: null, disabled: false),
                    (text: 'Female', value: 'female', description: null, disabled: false),
                    (text: 'Other',  value: 'other',  description: 'Non-binary / custom', disabled: false),
                  ],
                ),
                LfSelect<String>(
                    name: 'country',
                    label: 'Country',
                    options: [
                      (text: 'United States', value: 'us', disabled: false),
                      (text: 'Canada', value: 'ca', disabled: false),
                      (text: 'United Kingdom', value: 'uk', disabled: false),
                      (text: 'Australia', value: 'au', disabled: false),
                    ],
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}