import 'package:reactive_forms/reactive_forms.dart';

final Map<String, ValidationMessageFunction> kGlobalValidationMessages = {
  'required': (_) => 'Required',

  'phone': (_) =>
  'Phone must be a valid 10-digit number starting with a non-zero digit.',
  'countryCode': (_) => 'Country code must be 1-3 digits.',
  'otp': (error) {
    if (error is Map && error['len'] != null) {
      return 'Enter the ${error['len']}-digit code.';
    }
    return 'Invalid code.';
  },
  'inviteCode': (_) => 'A combination of 5 to 20 digits or letters.',
  'password': (_) =>
  'Password must be 8-20 characters, incl. upper/lowercase, number & symbol.',
  'amount': (e) {
    if (e is Map && e['min'] != null && e['max'] != null) {
      return 'Please enter a number between ₱${e['min']} and ₱${e['max']}.';
    }
    return 'Invalid amount.';
  },
  'postalCode': (_) => 'Postal Code must be 4 digits.',
  'passwordMismatch': (_) => 'The two passwords do not match.',
};