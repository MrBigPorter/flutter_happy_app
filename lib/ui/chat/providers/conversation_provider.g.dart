// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationListHash() => r'c68ac7e848f9c00e29285e57dc28de22f60c7e1f';

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
String _$chatDetailHash() => r'4ee1e7e985d67c19d4b36d3de88dd830f6103af3';

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

abstract class _$ChatDetail
    extends BuildlessAutoDisposeAsyncNotifier<ConversationDetail> {
  late final String conversationId;

  FutureOr<ConversationDetail> build(
    String conversationId,
  );
}

/// See also [ChatDetail].
@ProviderFor(ChatDetail)
const chatDetailProvider = ChatDetailFamily();

/// See also [ChatDetail].
class ChatDetailFamily extends Family<AsyncValue<ConversationDetail>> {
  /// See also [ChatDetail].
  const ChatDetailFamily();

  /// See also [ChatDetail].
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

/// See also [ChatDetail].
class ChatDetailProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChatDetail, ConversationDetail> {
  /// See also [ChatDetail].
  ChatDetailProvider(
    String conversationId,
  ) : this._internal(
          () => ChatDetail()..conversationId = conversationId,
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
  FutureOr<ConversationDetail> runNotifierBuild(
    covariant ChatDetail notifier,
  ) {
    return notifier.build(
      conversationId,
    );
  }

  @override
  Override overrideWith(ChatDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatDetailProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ChatDetail, ConversationDetail>
      createElement() {
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

mixin ChatDetailRef on AutoDisposeAsyncNotifierProviderRef<ConversationDetail> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChatDetail,
        ConversationDetail> with ChatDetailRef {
  _ChatDetailProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatDetailProvider).conversationId;
}

String _$conversationSettingsControllerHash() =>
    r'0c90a8deeb3e40581267a26760357ae06cfa0489';

/// See also [ConversationSettingsController].
@ProviderFor(ConversationSettingsController)
final conversationSettingsControllerProvider = AutoDisposeAsyncNotifierProvider<
    ConversationSettingsController, void>.internal(
  ConversationSettingsController.new,
  name: r'conversationSettingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationSettingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversationSettingsController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
