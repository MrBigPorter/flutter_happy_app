import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OTP Request Provider
final otpRequestProvider = FutureProvider.family<OtpRequest, int> ((ref,phone){
  return Api.otpRequestApi(phone);
});

/// Verify OTP Provider
final optVerifyProvider = FutureProvider.family<void,OtpVerifyParams>((ref,OtpVerifyParams params) async {
  return Api.optVerifyApi(phone: params.phone, code: params.code);
});

/// Auth Login OTP Provider
typedef LoginWithOtpParams = ({
  int phone,
  int? inviteCode,
  int? countryCode
});

/// Login with OTP Provider
final loginWithOtpProvider = FutureProvider.family<AuthLoginOtp, LoginWithOtpParams>((ref, LoginWithOtpParams params) async{
  return await Api.loginWithOtpApi(
    phone: params.phone,
    inviteCode: params.inviteCode,
    countryCode: params.countryCode,
  );
});

/// profile provider
final profileProvider = FutureProvider<Profile>((ref) async {
  return await Api.profileApi();
});