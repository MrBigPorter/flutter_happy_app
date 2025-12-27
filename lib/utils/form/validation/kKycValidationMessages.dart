import 'package:reactive_forms/reactive_forms.dart';

final Map<String, ValidationMessageFunction> kKycValidationMessages = {
  // === 1. 通用基础验证 ===
  ValidationMessage.required: (_) => 'This field is required.',
  ValidationMessage.email: (_) => 'Please enter a valid email address.',
  ValidationMessage.number: (_) => 'Please enter a valid number.',

  // 长度校验 (通用)
  ValidationMessage.minLength: (error) =>
  'Minimum length is ${(error as Map)['requiredLength']}.',
  ValidationMessage.maxLength: (error) =>
  'Maximum length is ${(error as Map)['requiredLength']}.',

  // === 2. 身份与证件 (Identity) ===
  // 对应 IdNumberValidator() 返回的 'idNumber' key
  'idNumber': (_) => 'Invalid ID format. Please check again.',

  // 对应 RealName() 返回的 'realName' key
  'realName': (_) => 'Name contains invalid characters.',

  // 对应 IsAdult() 返回的 'underage' key (如果加了年龄校验)
  'underage': (_) => 'You must be at least 18 years old.',
  'invalidDate': (_) => 'Invalid date format.',

  'gender': (_) => 'Please select a gender.',
  'birthday': (_) => 'Please select your date of birth.',
  'countryCode': (_) => 'Invalid country code.',

  // === 3. 地址信息 (Address) ===
  'province': (_) => 'Province is required.',
  'city': (_) => 'City is required.',

  // 菲律宾核心字段
  'barangay': (_) => 'Barangay is required.',

  // 对应 Length(4) 或正则校验
  'postalCode': (_) => 'Postal Code must be 4 digits.',

  'address': (_) => 'Please enter your specific house no. / street.',

  // === 4. 图片与凭证 (Images) ===
  'idCardFront': (_) => 'Front ID photo is missing.',
  'idCardBack': (_) => 'Back ID photo is missing.',
  'faceImage': (_) => 'Selfie photo is missing.',

  // 活体检测失败
  'livenessScore': (_) => 'Liveness check failed. Please retry.',
};