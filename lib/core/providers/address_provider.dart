import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_provider.g.dart';

@riverpod
class SelectedAddress extends _$SelectedAddress {
  @override
  AddressRes? build() {
    final listAsync = ref.watch(addressListProvider);

    return listAsync.when(
      data: (data) {
        final list = data.list;
        if (list.isEmpty) return null;

        try {
          // state 可能还没初始化 (第一次运行)，所以要 try-catch 或者判空
          // 注意：在 build 期间读取 state 是比较特殊的，
          // 但为了对比“旧值”和“新值”，这是必须的。
          if (state != null) {
            // 检查当前选中的 ID 是否还在新列表里
            final currentId = state!.addressId;
            final stillExists = list.any((addr) => addr.addressId == currentId);
            if (stillExists) {
              // 如果存在，保持不变
              return list.firstWhere((addr) => addr.addressId == currentId);
            }
          }
        } catch (_) {
          // 第一次运行时 state 未初始化，会报错，直接忽略，走下面的默认逻辑
        }

        // 1. 找默认地址
        // 2. 没默认就找第一条
        return list.firstWhere(
            (address)=> address.isDefault == true,
            orElse: () => list.first
        );
      },
      // 优化：Loading 时保持上一次的状态 (如果有的话)，防止闪烁
      // 如果还没加载过，返回 null
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // 选择地址
  void select(AddressRes address) {
    state = address;
  }
}

//优化 1: 统一使用 Codegen 函数写法
@riverpod
Future<PageResult<AddressRes>> addressList(AddressListRef ref) {
  return Api.addressListApi();
}

//1. 小写 @riverpod (最常用)
//特点：默认开启 autoDispose（没人监听时自动销毁）
//优化 2: 详情页 Provider 也改写 (Family 变体)
@riverpod
Future<AddressRes> addressDetail(AddressDetailRef ref, String addressId) {
  return Api.addressDetailApi(addressId);
}

//大写 @Riverpod：是一个类（构造函数），用于“自定义配置”（比如保活）。
@Riverpod(keepAlive: true)
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
    final success = await _performAction(
      () => Api.addressUpdateApi(addressId, address),
    );
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
    } catch (e, s) {
      //  必须加上这行打印！看看控制台输出了什么 
      print('❌ 删除失败详细报错: $e');
      print(s); // 打印堆栈
      return false;
    }
  }
}
