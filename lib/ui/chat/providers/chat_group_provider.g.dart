// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatGroupHash() => r'b31cc4048f499906bde0c4b3165f5ef89d8796b4';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
