class AppPatterns {
  // Phone number: 10 digits, does not start with 0
  static final phone = RegExp(r'^[1-9]\d{9}$');
  // Email address
  static final email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  // Username: 3-15 characters, alphanumeric and underscores only
  static final username = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
  // phone code: exactly 6 digits
  static final phoneCode = RegExp(r'^\d{6}$');
  // invite code: 5-20 alphanumeric characters
  static final inviteCode = RegExp(r'^(?:[a-zA-Z0-9]{5,20})?$');
  // Strong password: 8-20 characters, at least one uppercase letter, one lowercase letter, one digit, and one special character
  static final strongPassword =
  RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,20}$');
  // OTP: exactly 4 digits
  static final otp4 = RegExp(r'^\d{4}$');
  // OTP: exactly 6 digits
  static final days = RegExp(r'^[1-9]\d*$');
  // Postal code: exactly 4 digits
  static final postal4 = RegExp(r'^\d{4}$');
}