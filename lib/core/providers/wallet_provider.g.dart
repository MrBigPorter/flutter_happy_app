// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
