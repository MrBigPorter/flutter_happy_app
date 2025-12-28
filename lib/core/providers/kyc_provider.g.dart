// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kycNotifierHash() => r'da85f859e1783c9a4703e15faed9388741370e0e';

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
