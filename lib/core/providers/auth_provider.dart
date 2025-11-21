import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// 1) 发送 OTP
@Riverpod(keepAlive: true)
class SendOtpCtrl extends _$SendOtpCtrl {
  @override
  AsyncValue<OtpRequest?> build() => const AsyncData(null);

  Future<OtpRequest> run(String phone) async {
    state = const AsyncLoading();

    try {
      final res = await Api.otpRequestApi(phone);
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 2) 校验 OTP
@Riverpod(keepAlive: true)
class VerifyOtpCtrl extends _$VerifyOtpCtrl {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> run(String phone, String code) async {
    state = const AsyncLoading();

    try {
      await Api.optVerifyApi(phone: phone, code: code);
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 3) 登录参数
typedef LoginWithOtpParams = ({
String phone,
});

/// 4) OTP 登录
@Riverpod(keepAlive: true)
class AuthLoginOtpCtrl extends _$AuthLoginOtpCtrl {
  @override
  AsyncValue<AuthLoginOtp?> build() => const AsyncData(null);

  Future<AuthLoginOtp> run(LoginWithOtpParams params) async {
    state = const AsyncLoading();

    try {
      final res = await Api.loginWithOtpApi(
        phone: params.phone,
      );
      state = AsyncData(res);
      return res;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// 5) Profile Provider（函数式写法：注意是小写 @riverpod）
@riverpod
Future<Profile> profile(ProfileRef ref) async {
  return Api.profileApi();
}