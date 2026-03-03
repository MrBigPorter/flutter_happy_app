// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myCouponsByStatusHash() => r'dd766fa25a839f866eb2e48b65e87b498a01cab6';

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

/// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
///
/// Copied from [myCouponsByStatus].
@ProviderFor(myCouponsByStatus)
const myCouponsByStatusProvider = MyCouponsByStatusFamily();

/// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
///
/// Copied from [myCouponsByStatus].
class MyCouponsByStatusFamily extends Family<AsyncValue<List<UserCoupon>>> {
  /// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
  ///
  /// Copied from [myCouponsByStatus].
  const MyCouponsByStatusFamily();

  /// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
  ///
  /// Copied from [myCouponsByStatus].
  MyCouponsByStatusProvider call(
    int status,
  ) {
    return MyCouponsByStatusProvider(
      status,
    );
  }

  @override
  MyCouponsByStatusProvider getProviderOverride(
    covariant MyCouponsByStatusProvider provider,
  ) {
    return call(
      provider.status,
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
  String? get name => r'myCouponsByStatusProvider';
}

/// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
///
/// Copied from [myCouponsByStatus].
class MyCouponsByStatusProvider extends FutureProvider<List<UserCoupon>> {
  /// 加上 keepAlive: true，让它在切换 Tab 和页面时共享同一个缓存
  ///
  /// Copied from [myCouponsByStatus].
  MyCouponsByStatusProvider(
    int status,
  ) : this._internal(
          (ref) => myCouponsByStatus(
            ref as MyCouponsByStatusRef,
            status,
          ),
          from: myCouponsByStatusProvider,
          name: r'myCouponsByStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$myCouponsByStatusHash,
          dependencies: MyCouponsByStatusFamily._dependencies,
          allTransitiveDependencies:
              MyCouponsByStatusFamily._allTransitiveDependencies,
          status: status,
        );

  MyCouponsByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final int status;

  @override
  Override overrideWith(
    FutureOr<List<UserCoupon>> Function(MyCouponsByStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MyCouponsByStatusProvider._internal(
        (ref) => create(ref as MyCouponsByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  FutureProviderElement<List<UserCoupon>> createElement() {
    return _MyCouponsByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyCouponsByStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MyCouponsByStatusRef on FutureProviderRef<List<UserCoupon>> {
  /// The parameter `status` of this provider.
  int get status;
}

class _MyCouponsByStatusProviderElement
    extends FutureProviderElement<List<UserCoupon>> with MyCouponsByStatusRef {
  _MyCouponsByStatusProviderElement(super.provider);

  @override
  int get status => (origin as MyCouponsByStatusProvider).status;
}

String _$myValidCouponsHash() => r'48f0cf83578a9dbcd5dcab4a9daeeaeea090a17d';

/// 魔法就在这里：它不自己发请求，而是去监听核心 Provider！
/// 这样既做到了 0 冗余代码，又让首页和独立管理页【共享同一个数据缓存】
///
/// Copied from [myValidCoupons].
@ProviderFor(myValidCoupons)
final myValidCouponsProvider = FutureProvider<List<UserCoupon>>.internal(
  myValidCoupons,
  name: r'myValidCouponsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myValidCouponsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyValidCouponsRef = FutureProviderRef<List<UserCoupon>>;
String _$availableCouponsForOrderHash() =>
    r'4ad4655b64ce37761bf51826cab3d12b99d6cdb6';

/// 结算页：获取当前订单【满足门槛】的可用优惠券
///
/// Copied from [availableCouponsForOrder].
@ProviderFor(availableCouponsForOrder)
const availableCouponsForOrderProvider = AvailableCouponsForOrderFamily();

/// 结算页：获取当前订单【满足门槛】的可用优惠券
///
/// Copied from [availableCouponsForOrder].
class AvailableCouponsForOrderFamily
    extends Family<AsyncValue<List<UserCoupon>>> {
  /// 结算页：获取当前订单【满足门槛】的可用优惠券
  ///
  /// Copied from [availableCouponsForOrder].
  const AvailableCouponsForOrderFamily();

  /// 结算页：获取当前订单【满足门槛】的可用优惠券
  ///
  /// Copied from [availableCouponsForOrder].
  AvailableCouponsForOrderProvider call(
    double orderAmount,
  ) {
    return AvailableCouponsForOrderProvider(
      orderAmount,
    );
  }

  @override
  AvailableCouponsForOrderProvider getProviderOverride(
    covariant AvailableCouponsForOrderProvider provider,
  ) {
    return call(
      provider.orderAmount,
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
  String? get name => r'availableCouponsForOrderProvider';
}

/// 结算页：获取当前订单【满足门槛】的可用优惠券
///
/// Copied from [availableCouponsForOrder].
class AvailableCouponsForOrderProvider
    extends AutoDisposeFutureProvider<List<UserCoupon>> {
  /// 结算页：获取当前订单【满足门槛】的可用优惠券
  ///
  /// Copied from [availableCouponsForOrder].
  AvailableCouponsForOrderProvider(
    double orderAmount,
  ) : this._internal(
          (ref) => availableCouponsForOrder(
            ref as AvailableCouponsForOrderRef,
            orderAmount,
          ),
          from: availableCouponsForOrderProvider,
          name: r'availableCouponsForOrderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$availableCouponsForOrderHash,
          dependencies: AvailableCouponsForOrderFamily._dependencies,
          allTransitiveDependencies:
              AvailableCouponsForOrderFamily._allTransitiveDependencies,
          orderAmount: orderAmount,
        );

  AvailableCouponsForOrderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderAmount,
  }) : super.internal();

  final double orderAmount;

  @override
  Override overrideWith(
    FutureOr<List<UserCoupon>> Function(AvailableCouponsForOrderRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableCouponsForOrderProvider._internal(
        (ref) => create(ref as AvailableCouponsForOrderRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderAmount: orderAmount,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<UserCoupon>> createElement() {
    return _AvailableCouponsForOrderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableCouponsForOrderProvider &&
        other.orderAmount == orderAmount;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderAmount.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvailableCouponsForOrderRef
    on AutoDisposeFutureProviderRef<List<UserCoupon>> {
  /// The parameter `orderAmount` of this provider.
  double get orderAmount;
}

class _AvailableCouponsForOrderProviderElement
    extends AutoDisposeFutureProviderElement<List<UserCoupon>>
    with AvailableCouponsForOrderRef {
  _AvailableCouponsForOrderProviderElement(super.provider);

  @override
  double get orderAmount =>
      (origin as AvailableCouponsForOrderProvider).orderAmount;
}

String _$claimableCouponsHash() => r'b8cb67d9500db9b7222391efbd0c79fdf0e14518';

/// 领券大厅：获取可以领取的券
///
/// Copied from [claimableCoupons].
@ProviderFor(claimableCoupons)
final claimableCouponsProvider =
    AutoDisposeFutureProvider<List<ClaimableCoupon>>.internal(
  claimableCoupons,
  name: r'claimableCouponsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$claimableCouponsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ClaimableCouponsRef
    = AutoDisposeFutureProviderRef<List<ClaimableCoupon>>;
String _$selectedCouponHash() => r'aa85d432205830c7d3c87e7ab882507d4b74e1b0';

/// 结算页选中的优惠券 (Apply)
///
/// Copied from [SelectedCoupon].
@ProviderFor(SelectedCoupon)
final selectedCouponProvider =
    AutoDisposeNotifierProvider<SelectedCoupon, UserCoupon?>.internal(
  SelectedCoupon.new,
  name: r'selectedCouponProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCouponHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCoupon = AutoDisposeNotifier<UserCoupon?>;
String _$couponActionHash() => r'339cdbd838e75234b780b3114b73874012c7c25c';

/// See also [CouponAction].
@ProviderFor(CouponAction)
final couponActionProvider =
    AutoDisposeAsyncNotifierProvider<CouponAction, void>.internal(
  CouponAction.new,
  name: r'couponActionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$couponActionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CouponAction = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
