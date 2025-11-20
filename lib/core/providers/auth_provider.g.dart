// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'4735d11297367d1c60385ceb5bf1b4f9fe31979a';

/// 5) Profile Provider（函数式写法：注意是小写 @riverpod）
///
/// Copied from [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeFutureProvider<Profile>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeFutureProviderRef<Profile>;
String _$sendOtpCtrlHash() => r'7c9a3b5bbd1180952d7982e08ed85d4af6d0f67d';

/// 1) 发送 OTP
///
/// Copied from [SendOtpCtrl].
@ProviderFor(SendOtpCtrl)
final sendOtpCtrlProvider =
    NotifierProvider<SendOtpCtrl, AsyncValue<OtpRequest?>>.internal(
      SendOtpCtrl.new,
      name: r'sendOtpCtrlProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sendOtpCtrlHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SendOtpCtrl = Notifier<AsyncValue<OtpRequest?>>;
String _$verifyOtpCtrlHash() => r'ac379466866445e0fafaaf62286a99d78566cbb3';

/// 2) 校验 OTP
///
/// Copied from [VerifyOtpCtrl].
@ProviderFor(VerifyOtpCtrl)
final verifyOtpCtrlProvider =
    NotifierProvider<VerifyOtpCtrl, AsyncValue<void>>.internal(
      VerifyOtpCtrl.new,
      name: r'verifyOtpCtrlProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$verifyOtpCtrlHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VerifyOtpCtrl = Notifier<AsyncValue<void>>;
String _$authLoginOtpCtrlHash() => r'7ac963e6dd2a1153c976c58e28bc09993a29e763';

/// 4) OTP 登录
///
/// Copied from [AuthLoginOtpCtrl].
@ProviderFor(AuthLoginOtpCtrl)
final authLoginOtpCtrlProvider =
    NotifierProvider<AuthLoginOtpCtrl, AsyncValue<AuthLoginOtp?>>.internal(
      AuthLoginOtpCtrl.new,
      name: r'authLoginOtpCtrlProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authLoginOtpCtrlHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthLoginOtpCtrl = Notifier<AsyncValue<AuthLoginOtp?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
