// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contactListHash() => r'8c5bb5908515b1bcaaf1f4273698906426384d16';

/// See also [ContactList].
@ProviderFor(ContactList)
final contactListProvider =
    AutoDisposeAsyncNotifierProvider<ContactList, List<ChatUser>>.internal(
  ContactList.new,
  name: r'contactListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$contactListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ContactList = AutoDisposeAsyncNotifier<List<ChatUser>>;
String _$createGroupControllerHash() =>
    r'05c609e110392f2ad23204639fadd8c592b01ed5';

/// See also [CreateGroupController].
@ProviderFor(CreateGroupController)
final createGroupControllerProvider = AutoDisposeNotifierProvider<
    CreateGroupController, AsyncValue<CreateGroupResponse?>>.internal(
  CreateGroupController.new,
  name: r'createGroupControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createGroupControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateGroupController
    = AutoDisposeNotifier<AsyncValue<CreateGroupResponse?>>;
String _$addFriendControllerHash() =>
    r'08f3ed1a8e12e4396764ee72a5e97d20ead6b0cb';

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

abstract class _$AddFriendController
    extends BuildlessAutoDisposeNotifier<AsyncValue<void>> {
  late final String userId;

  AsyncValue<void> build(
    String userId,
  );
}

/// See also [AddFriendController].
@ProviderFor(AddFriendController)
const addFriendControllerProvider = AddFriendControllerFamily();

/// See also [AddFriendController].
class AddFriendControllerFamily extends Family<AsyncValue<void>> {
  /// See also [AddFriendController].
  const AddFriendControllerFamily();

  /// See also [AddFriendController].
  AddFriendControllerProvider call(
    String userId,
  ) {
    return AddFriendControllerProvider(
      userId,
    );
  }

  @override
  AddFriendControllerProvider getProviderOverride(
    covariant AddFriendControllerProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'addFriendControllerProvider';
}

/// See also [AddFriendController].
class AddFriendControllerProvider extends AutoDisposeNotifierProviderImpl<
    AddFriendController, AsyncValue<void>> {
  /// See also [AddFriendController].
  AddFriendControllerProvider(
    String userId,
  ) : this._internal(
          () => AddFriendController()..userId = userId,
          from: addFriendControllerProvider,
          name: r'addFriendControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$addFriendControllerHash,
          dependencies: AddFriendControllerFamily._dependencies,
          allTransitiveDependencies:
              AddFriendControllerFamily._allTransitiveDependencies,
          userId: userId,
        );

  AddFriendControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  AsyncValue<void> runNotifierBuild(
    covariant AddFriendController notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(AddFriendController Function() create) {
    return ProviderOverride(
      origin: this,
      override: AddFriendControllerProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AddFriendController, AsyncValue<void>>
      createElement() {
    return _AddFriendControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AddFriendControllerProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AddFriendControllerRef
    on AutoDisposeNotifierProviderRef<AsyncValue<void>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _AddFriendControllerProviderElement
    extends AutoDisposeNotifierProviderElement<AddFriendController,
        AsyncValue<void>> with AddFriendControllerRef {
  _AddFriendControllerProviderElement(super.provider);

  @override
  String get userId => (origin as AddFriendControllerProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
