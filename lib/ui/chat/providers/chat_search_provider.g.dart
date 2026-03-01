// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSearchControllerHash() =>
    r'69da54bb9fb062526ac6aff46aad2c1bf4cde99b';

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

abstract class _$ChatSearchController
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatUiModel>> {
  late final String conversationId;

  FutureOr<List<ChatUiModel>> build(
    String conversationId,
  );
}

/// See also [ChatSearchController].
@ProviderFor(ChatSearchController)
const chatSearchControllerProvider = ChatSearchControllerFamily();

/// See also [ChatSearchController].
class ChatSearchControllerFamily extends Family<AsyncValue<List<ChatUiModel>>> {
  /// See also [ChatSearchController].
  const ChatSearchControllerFamily();

  /// See also [ChatSearchController].
  ChatSearchControllerProvider call(
    String conversationId,
  ) {
    return ChatSearchControllerProvider(
      conversationId,
    );
  }

  @override
  ChatSearchControllerProvider getProviderOverride(
    covariant ChatSearchControllerProvider provider,
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
  String? get name => r'chatSearchControllerProvider';
}

/// See also [ChatSearchController].
class ChatSearchControllerProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChatSearchController, List<ChatUiModel>> {
  /// See also [ChatSearchController].
  ChatSearchControllerProvider(
    String conversationId,
  ) : this._internal(
          () => ChatSearchController()..conversationId = conversationId,
          from: chatSearchControllerProvider,
          name: r'chatSearchControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatSearchControllerHash,
          dependencies: ChatSearchControllerFamily._dependencies,
          allTransitiveDependencies:
              ChatSearchControllerFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ChatSearchControllerProvider._internal(
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
  FutureOr<List<ChatUiModel>> runNotifierBuild(
    covariant ChatSearchController notifier,
  ) {
    return notifier.build(
      conversationId,
    );
  }

  @override
  Override overrideWith(ChatSearchController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatSearchControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ChatSearchController,
      List<ChatUiModel>> createElement() {
    return _ChatSearchControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSearchControllerProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatSearchControllerRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChatUiModel>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatSearchControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChatSearchController,
        List<ChatUiModel>> with ChatSearchControllerRef {
  _ChatSearchControllerProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ChatSearchControllerProvider).conversationId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
