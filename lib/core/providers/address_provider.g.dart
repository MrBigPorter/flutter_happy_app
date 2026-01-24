// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$addressListHash() => r'a0bfc8646a96590c403f7b0068b73fa4203b920f';

/// See also [addressList].
@ProviderFor(addressList)
final addressListProvider =
    AutoDisposeFutureProvider<PageResult<AddressRes>>.internal(
  addressList,
  name: r'addressListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$addressListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AddressListRef = AutoDisposeFutureProviderRef<PageResult<AddressRes>>;
String _$addressDetailHash() => r'6e9b267aa46589577db10ca75cc0599553415be0';

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

/// See also [addressDetail].
@ProviderFor(addressDetail)
const addressDetailProvider = AddressDetailFamily();

/// See also [addressDetail].
class AddressDetailFamily extends Family<AsyncValue<AddressRes>> {
  /// See also [addressDetail].
  const AddressDetailFamily();

  /// See also [addressDetail].
  AddressDetailProvider call(
    String addressId,
  ) {
    return AddressDetailProvider(
      addressId,
    );
  }

  @override
  AddressDetailProvider getProviderOverride(
    covariant AddressDetailProvider provider,
  ) {
    return call(
      provider.addressId,
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
  String? get name => r'addressDetailProvider';
}

/// See also [addressDetail].
class AddressDetailProvider extends AutoDisposeFutureProvider<AddressRes> {
  /// See also [addressDetail].
  AddressDetailProvider(
    String addressId,
  ) : this._internal(
          (ref) => addressDetail(
            ref as AddressDetailRef,
            addressId,
          ),
          from: addressDetailProvider,
          name: r'addressDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$addressDetailHash,
          dependencies: AddressDetailFamily._dependencies,
          allTransitiveDependencies:
              AddressDetailFamily._allTransitiveDependencies,
          addressId: addressId,
        );

  AddressDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.addressId,
  }) : super.internal();

  final String addressId;

  @override
  Override overrideWith(
    FutureOr<AddressRes> Function(AddressDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AddressDetailProvider._internal(
        (ref) => create(ref as AddressDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        addressId: addressId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AddressRes> createElement() {
    return _AddressDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AddressDetailProvider && other.addressId == addressId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, addressId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AddressDetailRef on AutoDisposeFutureProviderRef<AddressRes> {
  /// The parameter `addressId` of this provider.
  String get addressId;
}

class _AddressDetailProviderElement
    extends AutoDisposeFutureProviderElement<AddressRes> with AddressDetailRef {
  _AddressDetailProviderElement(super.provider);

  @override
  String get addressId => (origin as AddressDetailProvider).addressId;
}

String _$selectedAddressHash() => r'bd8ea455919f4164b519b9f1741b82c66e0994fd';

/// See also [SelectedAddress].
@ProviderFor(SelectedAddress)
final selectedAddressProvider =
    AutoDisposeNotifierProvider<SelectedAddress, AddressRes?>.internal(
  SelectedAddress.new,
  name: r'selectedAddressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedAddressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedAddress = AutoDisposeNotifier<AddressRes?>;
String _$addressManagerHash() => r'6d9b60aa090bbff101986aeb9467c9844f525b8a';

/// See also [AddressManager].
@ProviderFor(AddressManager)
final addressManagerProvider =
    NotifierProvider<AddressManager, AsyncValue<void>>.internal(
  AddressManager.new,
  name: r'addressManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addressManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddressManager = Notifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
