import 'package:reactive_forms/reactive_forms.dart';

final Map<String, ValidationMessageFunction> kAddressValidationMessages = {
  'required': (_) => 'Required',
  'firstName': (_) => 'First Name must contain only letters and spaces.',
  'middleName': (_) => 'Middle Name must contain only letters and spaces.',
  'lastName': (_) => 'Last Name must contain only letters and spaces.',
  'contactName': (_) => 'Contact Name must contain only letters and spaces.',
  'fullAddress': (_) => 'Full Address is required.',
  'provinceId': (_) => 'Province is required.',
  'cityId': (_) => 'City is required.',
  'barangayId': (_) => 'Barangay is required.',
  'label': (_) => 'Label must contain only letters and spaces.',
  'isDefault': (_) => 'Default selection is required.',
  'phone': (_) =>
  'Phone must be a valid 10-digit number starting with a non-zero digit.',
  'postalCode': (_) => 'Postal Code must be 4 digits.',
};