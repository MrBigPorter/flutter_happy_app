import 'package:reactive_forms/reactive_forms.dart';

final Map<String, ValidationMessageFunction> kDepositValidationMessages = {
  ValidationMessage.required: (_) => 'This field is required.',

  'amount': (control) {
    final err = control is FormControl ? control.errors['amount'] : null;

    print('Deposit amount validation error: $err');
    // 兜底：保证一定返回 String
    if (err is! Map) return 'Please enter a valid deposit amount.';

    final reason = err['reason'];
    final min = err['min'];
    final max = err['max'];

    if (reason == 'invalid') return 'Please enter a valid deposit amount.';
    if (reason == 'min') return 'Minimum deposit is $min.';
    if (reason == 'max') return 'Maximum deposit is $max.';

    if (min != null && max != null) return 'Deposit amount must be between $min and $max.';
    if (min != null) return 'Minimum deposit is $min.';
    return 'Please enter a valid deposit amount.';
  },
};