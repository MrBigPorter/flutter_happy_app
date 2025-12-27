// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kycNotifierHash() => r'caa31afd0e61fac80485b68eea17375cbc489bd8';

/// KYC 操作控制器
/// 负责：OCR 识别、提交 KYC 等动作
///
///
/// Copied from [KycNotifier].
@ProviderFor(KycNotifier)
final kycNotifierProvider =
    AutoDisposeAsyncNotifierProvider<KycNotifier, KycOcrResult?>.internal(
      KycNotifier.new,
      name: r'kycNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$kycNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$KycNotifier = AutoDisposeAsyncNotifier<KycOcrResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
