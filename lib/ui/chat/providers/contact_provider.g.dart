// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSearchHash() => r'd1c3145a4b6222585728e5bada5ed471659b5b0d';

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

/// See also [userSearch].
@ProviderFor(userSearch)
const userSearchProvider = UserSearchFamily();

/// See also [userSearch].
class UserSearchFamily extends Family<AsyncValue<List<ChatUser>>> {
  /// See also [userSearch].
  const UserSearchFamily();

  /// See also [userSearch].
  UserSearchProvider call(
    String keyword,
  ) {
    return UserSearchProvider(
      keyword,
    );
  }

  @override
  UserSearchProvider getProviderOverride(
    covariant UserSearchProvider provider,
  ) {
    return call(
      provider.keyword,
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
  String? get name => r'userSearchProvider';
}

/// See also [userSearch].
class UserSearchProvider extends AutoDisposeFutureProvider<List<ChatUser>> {
  /// See also [userSearch].
  UserSearchProvider(
    String keyword,
  ) : this._internal(
          (ref) => userSearch(
            ref as UserSearchRef,
            keyword,
          ),
          from: userSearchProvider,
          name: r'userSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userSearchHash,
          dependencies: UserSearchFamily._dependencies,
          allTransitiveDependencies:
              UserSearchFamily._allTransitiveDependencies,
          keyword: keyword,
        );

  UserSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.keyword,
  }) : super.internal();

  final String keyword;

  @override
  Override overrideWith(
    FutureOr<List<ChatUser>> Function(UserSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserSearchProvider._internal(
        (ref) => create(ref as UserSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        keyword: keyword,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChatUser>> createElement() {
    return _UserSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSearchProvider && other.keyword == keyword;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, keyword.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserSearchRef on AutoDisposeFutureProviderRef<List<ChatUser>> {
  /// The parameter `keyword` of this provider.
  String get keyword;
}

class _UserSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatUser>>
    with UserSearchRef {
  _UserSearchProviderElement(super.provider);

  @override
  String get keyword => (origin as UserSearchProvider).keyword;
}

String _$chatContactsSearchHash() =>
    r'ed7aa181eb3c43a3e70516b1a993f2c9e30c948c';

/// See also [chatContactsSearch].
@ProviderFor(chatContactsSearch)
const chatContactsSearchProvider = ChatContactsSearchFamily();

/// See also [chatContactsSearch].
class ChatContactsSearchFamily extends Family<AsyncValue<List<ChatUser>>> {
  /// See also [chatContactsSearch].
  const ChatContactsSearchFamily();

  /// See also [chatContactsSearch].
  ChatContactsSearchProvider call(
    String keyword,
  ) {
    return ChatContactsSearchProvider(
      keyword,
    );
  }

  @override
  ChatContactsSearchProvider getProviderOverride(
    covariant ChatContactsSearchProvider provider,
  ) {
    return call(
      provider.keyword,
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
  String? get name => r'chatContactsSearchProvider';
}

/// See also [chatContactsSearch].
class ChatContactsSearchProvider
    extends AutoDisposeFutureProvider<List<ChatUser>> {
  /// See also [chatContactsSearch].
  ChatContactsSearchProvider(
    String keyword,
  ) : this._internal(
          (ref) => chatContactsSearch(
            ref as ChatContactsSearchRef,
            keyword,
          ),
          from: chatContactsSearchProvider,
          name: r'chatContactsSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatContactsSearchHash,
          dependencies: ChatContactsSearchFamily._dependencies,
          allTransitiveDependencies:
              ChatContactsSearchFamily._allTransitiveDependencies,
          keyword: keyword,
        );

  ChatContactsSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.keyword,
  }) : super.internal();

  final String keyword;

  @override
  Override overrideWith(
    FutureOr<List<ChatUser>> Function(ChatContactsSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatContactsSearchProvider._internal(
        (ref) => create(ref as ChatContactsSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        keyword: keyword,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChatUser>> createElement() {
    return _ChatContactsSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatContactsSearchProvider && other.keyword == keyword;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, keyword.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatContactsSearchRef on AutoDisposeFutureProviderRef<List<ChatUser>> {
  /// The parameter `keyword` of this provider.
  String get keyword;
}

class _ChatContactsSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatUser>>
    with ChatContactsSearchRef {
  _ChatContactsSearchProviderElement(super.provider);

  @override
  String get keyword => (origin as ChatContactsSearchProvider).keyword;
}

String _$contactListHash() => r'626086d5842ba5b2a8b14399b5ed561cec5aaaf9';

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
String _$friendRequestListHash() => r'bb11941069d639b8029f12f13fbec9712464740e';

/// See also [FriendRequestList].
@ProviderFor(FriendRequestList)
final friendRequestListProvider = AutoDisposeAsyncNotifierProvider<
    FriendRequestList, List<FriendRequest>>.internal(
  FriendRequestList.new,
  name: r'friendRequestListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$friendRequestListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FriendRequestList = AutoDisposeAsyncNotifier<List<FriendRequest>>;
String _$addFriendControllerHash() =>
    r'5d0c167b9c61aa4af809ebff214aa300989eb3f3';

abstract class _$AddFriendController
    extends BuildlessAutoDisposeAsyncNotifier<void> {
  late final String userId;

  FutureOr<void> build(
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
class AddFriendControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AddFriendController, void> {
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
  FutureOr<void> runNotifierBuild(
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
  AutoDisposeAsyncNotifierProviderElement<AddFriendController, void>
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

mixin AddFriendControllerRef on AutoDisposeAsyncNotifierProviderRef<void> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _AddFriendControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AddFriendController, void>
    with AddFriendControllerRef {
  _AddFriendControllerProviderElement(super.provider);

  @override
  String get userId => (origin as AddFriendControllerProvider).userId;
}

String _$handleRequestControllerHash() =>
    r'756247829bf0265191d0bf9d86eb762153a9cf94';

/// See also [HandleRequestController].
@ProviderFor(HandleRequestController)
final handleRequestControllerProvider =
    AutoDisposeAsyncNotifierProvider<HandleRequestController, void>.internal(
  HandleRequestController.new,
  name: r'handleRequestControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$handleRequestControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HandleRequestController = AutoDisposeAsyncNotifier<void>;
String _$groupMemberActionControllerHash() =>
    r'54f41bb837651b875c840f0bf5e2156c1ec8860e';

/// See also [GroupMemberActionController].
@ProviderFor(GroupMemberActionController)
final groupMemberActionControllerProvider = AutoDisposeNotifierProvider<
    GroupMemberActionController, AsyncValue<void>>.internal(
  GroupMemberActionController.new,
  name: r'groupMemberActionControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupMemberActionControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupMemberActionController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
