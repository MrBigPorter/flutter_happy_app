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

typedef ClientPaymentChannelsRechargeRef
    = AutoDisposeFutureProviderRef<List<PaymentChannelConfigItem>>;
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

typedef ClientPaymentChannelsWithdrawRef
    = AutoDisposeFutureProviderRef<List<PaymentChannelConfigItem>>;
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

typedef WalletBalanceRef = AutoDisposeFutureProviderRef<Balance>;
String _$rechargeStatusHash() => r'77ed9e57548e76ca3b4eafde5333a8f929d51262';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [rechargeStatus].
@ProviderFor(rechargeStatus)
const rechargeStatusProvider = RechargeStatusFamily();

/// See also [rechargeStatus].
class RechargeStatusFamily extends Family<AsyncValue<RechargeStatusResponse>> {
  /// See also [rechargeStatus].
  const RechargeStatusFamily();

  /// See also [rechargeStatus].
  RechargeStatusProvider call(
    String orderNo,
  ) {
    return RechargeStatusProvider(
      orderNo,
    );
  }

  @override
  RechargeStatusProvider getProviderOverride(
    covariant RechargeStatusProvider provider,
  ) {
    return call(
      provider.orderNo,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'rechargeStatusProvider';
}

/// See also [rechargeStatus].
class RechargeStatusProvider
    extends AutoDisposeFutureProvider<RechargeStatusResponse> {
  /// See also [rechargeStatus].
  RechargeStatusProvider(
    String orderNo,
  ) : this._internal(
          (ref) => rechargeStatus(
            ref as RechargeStatusRef,
            orderNo,
          ),
          from: rechargeStatusProvider,
          name: r'rechargeStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$rechargeStatusHash,
          dependencies: RechargeStatusFamily._dependencies,
          allTransitiveDependencies:
              RechargeStatusFamily._allTransitiveDependencies,
          orderNo: orderNo,
        );

  RechargeStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderNo,
  }) : super.internal();

  final String orderNo;

  @override
  Override overrideWith(
    FutureOr<RechargeStatusResponse> Function(RechargeStatusRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RechargeStatusProvider._internal(
        (ref) => create(ref as RechargeStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderNo: orderNo,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RechargeStatusResponse> createElement() {
    return _RechargeStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RechargeStatusProvider && other.orderNo == orderNo;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderNo.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RechargeStatusRef
    on AutoDisposeFutureProviderRef<RechargeStatusResponse> {
  /// The parameter `orderNo` of this provider.
  String get orderNo;
}

class _RechargeStatusProviderElement
    extends AutoDisposeFutureProviderElement<RechargeStatusResponse>
    with RechargeStatusRef {
  _RechargeStatusProviderElement(super.provider);

  @override
  String get orderNo => (origin as RechargeStatusProvider).orderNo;
}

String _$createRechargeHash() => r'9e259c7b9fb8f5592787bf4dd6e131f5f5178f38';

/// See also [CreateRecharge].
@ProviderFor(CreateRecharge)
final createRechargeProvider = AutoDisposeNotifierProvider<CreateRecharge,
    AsyncValue<RechargeResponse?>>.internal(
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
final createWithdrawProvider = AutoDisposeNotifierProvider<CreateWithdraw,
    AsyncValue<WalletWithdrawResponse?>>.internal(
  CreateWithdraw.new,
  name: r'createWithdrawProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createWithdrawHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateWithdraw
    = AutoDisposeNotifier<AsyncValue<WalletWithdrawResponse?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
