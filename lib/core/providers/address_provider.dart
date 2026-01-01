import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/address_res.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_provider.g.dart';

//优化 1: 统一使用 Codegen 函数写法
@riverpod
Future<PageResult<AddressRes>> addressList(AddressListRef ref) {
  return Api.addressListApi();
}

//优化 2: 详情页 Provider 也改写 (Family 变体)
@riverpod
Future<AddressRes> addressDetail(AddressDetailRef ref, String addressId) {
  return Api.addressDetailApi(addressId);
}

@riverpod
class AddressManager extends _$AddressManager {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);


  /// 统一处理提交逻辑
  Future<bool> _performAction(Future<void> Function() action) async {
    state = const AsyncValue.loading();
// guard 自动处理 try-catch 和 state 赋值
    state = await AsyncValue.guard(action);

    if (!state.hasError) {
      // 刷新地址列表
      ref.invalidate(addressListProvider);
      return true;
    }
    return false;
  }

  // 优化 3: 使用 AsyncValue.guard 简化 try-catch
  /// Add 和 Update 逻辑高度相似，可以使用 guard 自动处理 loading/data/error 状态切换
  Future<bool> addAddress(AddressCreateDto address) async {
    return _performAction(() => Api.addressCreateApi(address));
  }

  /// 更新地址
  Future<bool> updateAddress(String addressId, AddressCreateDto address) async {
    final success = await _performAction(() =>
        Api.addressUpdateApi(addressId, address));
    if (success) {
      // 如果是更新列表
      ref.invalidate(addressListProvider);
      return success;
    }
    return false;
  }

  /// 删除地址
  Future<bool> deleteAddress(String addressId) async {
    // Delete 不走全局 loading，手动处理
    try {
      await Api.addressDeleteApi(addressId);
      ref.invalidate(addressListProvider);
      // 刷新地址列表
      return true;
    } catch (_) {
      return false;
    }
  }

}
