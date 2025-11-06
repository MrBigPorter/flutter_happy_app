import 'package:flutter/cupertino.dart';
import 'package:reactive_forms/reactive_forms.dart';

class LuckyForm extends StatelessWidget {
  final FormGroup form;
  final Widget child;

  const LuckyForm({
    super.key,
    required this.form,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: child,
    );
  }
}