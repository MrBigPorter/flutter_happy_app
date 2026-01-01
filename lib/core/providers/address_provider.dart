import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/address_res.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_provider.g.dart';

final addressListProvider = FutureProvider.autoDispose((ref) async {
  return await Api.addressListApi();
});

final addressDetailProvider = FutureProvider.family<AddressRes, String>((
  ref,
  addressId,
) async {
  return await Api.addressDetailApi(addressId);
});

@riverpod
class AddressManager extends _$AddressManager {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// 新增地址
  /// 场景：全屏表单 -> 使用全局 state 控制 Loading
  Future<bool> addAddress(AddressRes address) async {
    state = const AsyncValue.loading();

    try {
      await Api.addressCreateApi(address);
      ref.invalidate(addressListProvider); // 刷新地址列表
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace); // 设置错误状态
      return false;
    }
  }

  /// 更新地址
  Future<bool> updateAddress(String addressId,AddressRes address) async {
    state = const AsyncValue.loading();

    try {
      await Api.addressUpdateApi(addressId,address);
      ref.invalidate(addressListProvider); // 刷新地址列表
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace); // 设置错误状态
      return false;
    }
  }

  /// 删除地址
  Future<bool> deleteAddress(String addressId) async {
    try{
      await Api.addressDeleteApi(addressId);
      ref.invalidate(addressListProvider); // 刷新地址列表
      return true;
    } catch (error, stackTrace) {
      return false;
    }
  }

}
