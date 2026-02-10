// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatDetailHash() => r'aa54ed1a7d28349853e16f6254d3b6629f6a7276';

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
  ChatDetailProvider call(
    String conversationId,
  ) {
    return ChatDetailProvider(
      conversationId,
    );
  }

  @override
  ChatDetailProvider getProviderOverride(
    covariant ChatDetailProvider provider,
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
  String? get name => r'chatDetailProvider';
}

/// See also [chatDetail].
class ChatDetailProvider extends AutoDisposeStreamProvider<ConversationDetail> {
  /// See also [chatDetail].
  ChatDetailProvider(
    String conversationId,
  ) : this._internal(
          (ref) => chatDetail(
            ref as ChatDetailRef,
            conversationId,
          ),
          from: chatDetailProvider,
          name: r'chatDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatDetailHash,
          dependencies: ChatDetailFamily._dependencies,
          allTransitiveDependencies:
              ChatDetailFamily._allTransitiveDependencies,
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
    Stream<ConversationDetail> Function(ChatDetailRef provider) create,
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
  AutoDisposeStreamProviderElement<ConversationDetail> createElement() {
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

mixin ChatDetailRef on AutoDisposeStreamProviderRef<ConversationDetail> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatDetailProviderElement
    extends AutoDisposeStreamProviderElement<ConversationDetail>
    with ChatDetailRef {
  _ChatDetailProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatDetailProvider).conversationId;
}

String _$conversationListHash() => r'15ca0ea0fc0c406f00284b02cb13026f51c2e236';

/// See also [ConversationList].
@ProviderFor(ConversationList)
final conversationListProvider =
    AsyncNotifierProvider<ConversationList, List<Conversation>>.internal(
  ConversationList.new,
  name: r'conversationListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversationList = AsyncNotifier<List<Conversation>>;
String _$createDirectChatControllerHash() =>
    r'd1917cffb85efa129a375c0f1bb0c820f1a072f7';

/// See also [CreateDirectChatController].
@ProviderFor(CreateDirectChatController)
final createDirectChatControllerProvider = AutoDisposeNotifierProvider<
    CreateDirectChatController, AsyncValue<ConversationIdResponse?>>.internal(
  CreateDirectChatController.new,
  name: r'createDirectChatControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createDirectChatControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateDirectChatController
    = AutoDisposeNotifier<AsyncValue<ConversationIdResponse?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
