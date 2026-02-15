// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupJoinRequestsHash() => r'cee0f8b0ab0c30750c7cd136f9d232dbb831bf15';

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

/// See also [groupJoinRequests].
@ProviderFor(groupJoinRequests)
const groupJoinRequestsProvider = GroupJoinRequestsFamily();

/// See also [groupJoinRequests].
class GroupJoinRequestsFamily
    extends Family<AsyncValue<List<GroupJoinRequestItem>>> {
  /// See also [groupJoinRequests].
  const GroupJoinRequestsFamily();

  /// See also [groupJoinRequests].
  GroupJoinRequestsProvider call(
    String groupId,
  ) {
    return GroupJoinRequestsProvider(
      groupId,
    );
  }

  @override
  GroupJoinRequestsProvider getProviderOverride(
    covariant GroupJoinRequestsProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'groupJoinRequestsProvider';
}

/// See also [groupJoinRequests].
class GroupJoinRequestsProvider
    extends AutoDisposeFutureProvider<List<GroupJoinRequestItem>> {
  /// See also [groupJoinRequests].
  GroupJoinRequestsProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupJoinRequests(
            ref as GroupJoinRequestsRef,
            groupId,
          ),
          from: groupJoinRequestsProvider,
          name: r'groupJoinRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupJoinRequestsHash,
          dependencies: GroupJoinRequestsFamily._dependencies,
          allTransitiveDependencies:
              GroupJoinRequestsFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupJoinRequestsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    FutureOr<List<GroupJoinRequestItem>> Function(GroupJoinRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupJoinRequestsProvider._internal(
        (ref) => create(ref as GroupJoinRequestsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupJoinRequestItem>> createElement() {
    return _GroupJoinRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupJoinRequestsProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupJoinRequestsRef
    on AutoDisposeFutureProviderRef<List<GroupJoinRequestItem>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupJoinRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupJoinRequestItem>>
    with GroupJoinRequestsRef {
  _GroupJoinRequestsProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupJoinRequestsProvider).groupId;
}

String _$chatGroupHash() => r'77c4ef765c865f0215014c0dd1ba9ee5b7d4da39';

abstract class _$ChatGroup
    extends BuildlessAutoDisposeAsyncNotifier<ConversationDetail> {
  late final String conversationId;

  FutureOr<ConversationDetail> build(
    String conversationId,
  );
}

/// See also [ChatGroup].
@ProviderFor(ChatGroup)
const chatGroupProvider = ChatGroupFamily();

/// See also [ChatGroup].
class ChatGroupFamily extends Family<AsyncValue<ConversationDetail>> {
  /// See also [ChatGroup].
  const ChatGroupFamily();

  /// See also [ChatGroup].
  ChatGroupProvider call(
    String conversationId,
  ) {
    return ChatGroupProvider(
      conversationId,
    );
  }

  @override
  ChatGroupProvider getProviderOverride(
    covariant ChatGroupProvider provider,
  ) {
    return call(
      provider.conversationId,
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
  String? get name => r'chatGroupProvider';
}

/// See also [ChatGroup].
class ChatGroupProvider extends AutoDisposeAsyncNotifierProviderImpl<ChatGroup,
    ConversationDetail> {
  /// See also [ChatGroup].
  ChatGroupProvider(
    String conversationId,
  ) : this._internal(
          () => ChatGroup()..conversationId = conversationId,
          from: chatGroupProvider,
          name: r'chatGroupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatGroupHash,
          dependencies: ChatGroupFamily._dependencies,
          allTransitiveDependencies: ChatGroupFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ChatGroupProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<ConversationDetail> runNotifierBuild(
    covariant ChatGroup notifier,
  ) {
    return notifier.build(
      conversationId,
    );
  }

  @override
  Override overrideWith(ChatGroup Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatGroupProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChatGroup, ConversationDetail>
      createElement() {
    return _ChatGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatGroupProvider && other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatGroupRef on AutoDisposeAsyncNotifierProviderRef<ConversationDetail> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatGroupProviderElement extends AutoDisposeAsyncNotifierProviderElement<
    ChatGroup, ConversationDetail> with ChatGroupRef {
  _ChatGroupProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatGroupProvider).conversationId;
}

String _$groupCreateControllerHash() =>
    r'1ad58013e49fdf29c91b1de1c9c3d827e8431ae8';

/// See also [GroupCreateController].
@ProviderFor(GroupCreateController)
final groupCreateControllerProvider =
    AutoDisposeAsyncNotifierProvider<GroupCreateController, String?>.internal(
  GroupCreateController.new,
  name: r'groupCreateControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupCreateControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupCreateController = AutoDisposeAsyncNotifier<String?>;
String _$groupJoinControllerHash() =>
    r'2f9cfcdba9e08caeaf215c2dd8d4f70cd44468a1';

/// See also [GroupJoinController].
@ProviderFor(GroupJoinController)
final groupJoinControllerProvider =
    AutoDisposeAsyncNotifierProvider<GroupJoinController, void>.internal(
  GroupJoinController.new,
  name: r'groupJoinControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupJoinControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupJoinController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
