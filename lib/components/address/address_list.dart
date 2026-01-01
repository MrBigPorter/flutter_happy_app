import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/models/address_res.dart';
import '../../core/providers/address_provider.dart';
import '../../ui/animations/transparent_fade_route.dart';
import '../../ui/button/variant.dart';
import '../../ui/toast/radix_toast.dart';
import 'address_manager_page.dart';

class AddressList extends ConsumerStatefulWidget {
  const AddressList({super.key});

  @override
  ConsumerState<AddressList> createState() => _AddressListState();
}

class _AddressListState extends ConsumerState<AddressList> {
  @override
  Widget build(BuildContext context) {
    // 监听 Provider 数据
    final addressListAsync = ref.watch(addressListProvider);

    return addressListAsync.when(
      data: (data) {
        //  获取真实数据 (假设 data 是 AddressListRes，里面有个 list 字段)
        // 如果 data 本身就是 List<AddressRes>，直接用 data
        final currentList = data.list;

        return Column(
          mainAxisSize: MainAxisSize.min, // 自适应高度
          children: [
            Flexible(
              fit: FlexFit.loose,// 关键：让 ListView 占据剩余空间
              child: currentList.isEmpty
                  ? _buildNoAddress()
                  //  传入真实数据
                  : _buildAddressList(currentList),
            ),
            Padding(padding: EdgeInsets.all(16.w), child: _buildAddButton())
          ],
        );
      },
      loading: () => Container(
        height: 200.h,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Container(
        height: 200.h,
        alignment: Alignment.center,
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildAddButton() {
    return Hero(
        tag: 'add-address-manager',
        child: SizedBox(
          width: double.infinity,
          height: 44.h,
          child: Button(
            variant: ButtonVariant.outline,
            leading: Icon(
              CupertinoIcons.add,
              size: 22.w,
              color: context.textPrimary900,
            ),
            onPressed: () {
              Navigator.of(context).push(
                  TransparentFadeRoute(
                    child: AddressManagerPage(
                      onClose: () {
                        Navigator.of(context).pop();
                      },
                    )
                  )
              );
            },
            child: Text(
              'add-new-address'.tr(),
              style: TextStyle(
                fontSize: context.textSm,
                height: context.leadingSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
    );
  }

  Widget _buildNoAddress() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120.w,
            height: 120.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  bottom: 25.w,
                  child: Icon(
                    Icons.map_outlined,
                    size: 60.w,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 20.w,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_off_rounded,
                      size: 32.w,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.w),
          Text(
            "No address yet",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textPrimary900, // 修正颜色引用
            ),
          ),
          SizedBox(height: 4.w),
          Text(
            "Please add a shipping address to continue",
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textSecondary700, // 修正颜色引用
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(List<AddressRes> items) {
    // 关键优化：去掉 shrinkWrap: true
    // 让 ListView 占据 Flexible 给它的剩余空间，并自己处理滚动
    return ListView.separated(
      shrinkWrap: false,
      // 配合 Column MainAxisSize.min 使用
      physics: const AlwaysScrollableScrollPhysics(),
      // 避免弹窗内的弹性效果冲突
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final address = items[index];
        //  Item Widget，性能更好，且方便处理局部 Loading
        return _AddressItem(key: ValueKey(address.addressId), address: address);
      },
    );
  }
}

// ✨✨✨ 提取出来的独立 Item 组件 ✨✨✨
class _AddressItem extends ConsumerStatefulWidget {
  final AddressRes address;

  const _AddressItem({super.key, required this.address});

  @override
  ConsumerState<_AddressItem> createState() => _AddressItemState();
}

class _AddressItemState extends ConsumerState<_AddressItem> {
  bool _isDeleting = false; // 局部 Loading 状态

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    // 调用 Manager
    final success = await ref
        .read(addressManagerProvider.notifier)
        .deleteAddress(widget.address.addressId);

    if(success) {
      if (mounted) {
        RadixToast.success( 'Address deleted successfully');
      }
    } else {
      if (mounted) {
        RadixToast.error('Failed to delete address');
      }
    }


    if (mounted) {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.address.isDefault == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: isSelected ? Border.all(color: context.bgErrorPrimary, width: 1.w)
            : Border.all(color: context.alphaBlack10, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: context.bgSecondary,
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Slidable(
           key: ValueKey(widget.address.addressId), // 已经在父级传了 key
          endActionPane: ActionPane(
            // DrawerMotion: 按钮紧贴着卡片边缘拉出来 (最像 iOS/微信)
            // ScrollMotion: 按钮固定在底部 (像旧版 iOS)
            motion: const DrawerMotion(),
            extentRatio: 0.25, // 删除按钮占整个卡片的 25%
            dismissible: DismissiblePane(onDismissed: ()=>_handleDelete()),
            children: [
              CustomSlidableAction(
                onPressed: (context) => _handleDelete(),
                backgroundColor: context.bgErrorPrimary,
                foregroundColor: context.textWhite,
                // 如果正在删除，显示转圈，否则显示图标
                child: _isDeleting
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child:  CircularProgressIndicator(
                    color: context.textWhite,
                    strokeWidth: 2,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 20.w),
                    SizedBox(height: 4.h),
                    Text("Delete", style: TextStyle(fontSize: 10.sp)),
                  ],
                ),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              // TODO: 选中逻辑
            },
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.address.contactName ?? '',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: context.textWhite,
                              ),
                            ),
                            if (isSelected) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.w,
                                ),
                                decoration: BoxDecoration(
                                  color: context.utilityBrand50,
                                  border: Border.all(
                                    color: context.utilityBrand200,
                                  ),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  "Default",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: context.utilityBrand700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 6.w),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone_rounded,
                              size: 14.w,
                              color: context.textSecondary700,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              widget.address.phone,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: context.textSecondary700,
                                fontFamily: "Monospace",
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          widget.address.fullAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.textSecondary700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        TransparentFadeRoute(
                          child: AddressManagerPage(
                            address: widget.address,
                            onClose: () {
                              Navigator.of(context).pop();
                            },
                          )
                        )
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 12.w, top: 2.w, bottom: 20.w),
                      color: Colors.transparent,
                      child: Icon(
                        Icons.edit_square,
                        size: 20.w,
                        color: context.textSecondary700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
