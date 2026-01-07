// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientPaymentChannelsRechargeHash() =>
    r'6487566d8e54c844d9e4c55ede2b493f4dd4be22';

/// See also [clientPaymentChannelsRecharge].
@ProviderFor(clientPaymentChannelsRecharge)
final clientPaymentChannelsRechargeProvider =
    AutoDisposeFutureProvider<List<PaymentChannelConfigItem>>.internal(
      clientPaymentChannelsRecharge,
      name: r'clientPaymentChannelsRechargeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clientPaymentChannelsRechargeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClientPaymentChannelsRechargeRef =
    AutoDisposeFutureProviderRef<List<PaymentChannelConfigItem>>;
String _$clientPaymentChannelsWithdrawHash() =>
    r'38ac04adc03360f72e4f33aca0ed9d170309bce7';

/// See also [clientPaymentChannelsWithdraw].
@ProviderFor(clientPaymentChannelsWithdraw)
final clientPaymentChannelsWithdrawProvider =
    AutoDisposeFutureProvider<List<PaymentChannelConfigItem>>.internal(
      clientPaymentChannelsWithdraw,
      name: r'clientPaymentChannelsWithdrawProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clientPaymentChannelsWithdrawHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClientPaymentChannelsWithdrawRef =
    AutoDisposeFutureProviderRef<List<PaymentChannelConfigItem>>;
String _$walletBalanceHash() => r'47f3319f0a079a5247d1e27809c475199b2ba1d4';

/// See also [walletBalance].
@ProviderFor(walletBalance)
final walletBalanceProvider = AutoDisposeFutureProvider<Balance>.internal(
  walletBalance,
  name: r'walletBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletBalanceRef = AutoDisposeFutureProviderRef<Balance>;
String _$createRechargeHash() => r'9e259c7b9fb8f5592787bf4dd6e131f5f5178f38';

/// See also [CreateRecharge].
@ProviderFor(CreateRecharge)
final createRechargeProvider =
    AutoDisposeNotifierProvider<
      CreateRecharge,
      AsyncValue<RechargeResponse?>
    >.internal(
      CreateRecharge.new,
      name: r'createRechargeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createRechargeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateRecharge = AutoDisposeNotifier<AsyncValue<RechargeResponse?>>;
String _$createWithdrawHash() => r'8a516a636bc5fc70b32b58a58266ba3f0423dc3d';

/// See also [CreateWithdraw].
@ProviderFor(CreateWithdraw)
final createWithdrawProvider =
    AutoDisposeNotifierProvider<
      CreateWithdraw,
      AsyncValue<WalletWithdrawResponse?>
    >.internal(
      CreateWithdraw.new,
      name: r'createWithdrawProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createWithdrawHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateWithdraw =
    AutoDisposeNotifier<AsyncValue<WalletWithdrawResponse?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
