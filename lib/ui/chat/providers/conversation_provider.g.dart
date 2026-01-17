// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatDetailHash() => r'0d52ccc26e0f89cb17c7647435bfae0aa7a1ddfa';

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

/// See also [chatDetail].
@ProviderFor(chatDetail)
const chatDetailProvider = ChatDetailFamily();

/// See also [chatDetail].
class ChatDetailFamily extends Family<AsyncValue<ConversationDetail>> {
  /// See also [chatDetail].
  const ChatDetailFamily();

  /// See also [chatDetail].
  ChatDetailProvider call(String conversationId) {
    return ChatDetailProvider(conversationId);
  }

  @override
  ChatDetailProvider getProviderOverride(
    covariant ChatDetailProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatDetailProvider';
}

/// See also [chatDetail].
class ChatDetailProvider extends AutoDisposeFutureProvider<ConversationDetail> {
  /// See also [chatDetail].
  ChatDetailProvider(String conversationId)
    : this._internal(
        (ref) => chatDetail(ref as ChatDetailRef, conversationId),
        from: chatDetailProvider,
        name: r'chatDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatDetailHash,
        dependencies: ChatDetailFamily._dependencies,
        allTransitiveDependencies: ChatDetailFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ChatDetailProvider._internal(
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
  Override overrideWith(
    FutureOr<ConversationDetail> Function(ChatDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatDetailProvider._internal(
        (ref) => create(ref as ChatDetailRef),
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
  AutoDisposeFutureProviderElement<ConversationDetail> createElement() {
    return _ChatDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatDetailProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatDetailRef on AutoDisposeFutureProviderRef<ConversationDetail> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatDetailProviderElement
    extends AutoDisposeFutureProviderElement<ConversationDetail>
    with ChatDetailRef {
  _ChatDetailProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatDetailProvider).conversationId;
}

String _$createGroupControllerHash() =>
    r'080da4c444c0e8e069beb6da404cbe7449e5f90d';

/// See also [CreateGroupController].
@ProviderFor(CreateGroupController)
final createGroupControllerProvider =
    AutoDisposeNotifierProvider<
      CreateGroupController,
      AsyncValue<ConversationIdResponse?>
    >.internal(
      CreateGroupController.new,
      name: r'createGroupControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createGroupControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateGroupController =
    AutoDisposeNotifier<AsyncValue<ConversationIdResponse?>>;
String _$createDirectChatControllerHash() =>
    r'9aca1d98d65f5b16888ff80fdf559a335813b296';

/// See also [CreateDirectChatController].
@ProviderFor(CreateDirectChatController)
final createDirectChatControllerProvider =
    AutoDisposeNotifierProvider<
      CreateDirectChatController,
      AsyncValue<ConversationIdResponse?>
    >.internal(
      CreateDirectChatController.new,
      name: r'createDirectChatControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createDirectChatControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateDirectChatController =
    AutoDisposeNotifier<AsyncValue<ConversationIdResponse?>>;
String _$userSearchControllerHash() =>
    r'fd0297440893e1df12e16064f3860807e49186e0';

/// See also [UserSearchController].
@ProviderFor(UserSearchController)
final userSearchControllerProvider =
    AutoDisposeNotifierProvider<
      UserSearchController,
      AsyncValue<List<ChatSender>>
    >.internal(
      UserSearchController.new,
      name: r'userSearchControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userSearchControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserSearchController =
    AutoDisposeNotifier<AsyncValue<List<ChatSender>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
