import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart'; // 务必导入 Skeleton 组件
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/contact_provider.dart';

class UserSearchDialog extends ConsumerStatefulWidget {
  const UserSearchDialog({super.key});
  @override
  ConsumerState<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<UserSearchDialog> {
  final _searchCtl = TextEditingController();
  String _keyword = "";

  @override
  Widget build(BuildContext context) {
    // 监听搜索结果状态
    final searchState = ref.watch(userSearchProvider(_keyword));

    return AlertDialog(
      title: Text("Add Friend", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
      backgroundColor: context.bgPrimary,
      surfaceTintColor: Colors.transparent, // 去除 Material 3 的默认色调
      contentPadding: EdgeInsets.all(20.w), // 调整内边距让布局更舒服
      content: SizedBox(
        width: 360.w,
        height: 400.h,
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                hintText: "Search nickname/phone",
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: context.borderPrimary),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: context.textBrandPrimary900),
                  onPressed: () => setState(() => _keyword = _searchCtl.text),
                ),
              ),
              onSubmitted: (v) => setState(() => _keyword = v),
            ),

            SizedBox(height: 16.h), // 搜索框和列表的间距

            // 列表区域
            Expanded(
              child: searchState.when(
                // 1. 加载中：显示骨架屏
                loading: () => _buildSkeletonList(context),

                // 2. 出错
                error: (e, _) => Center(
                  child: Text("Search failed", style: TextStyle(color: context.textSecondary700)),
                ),

                // 3. 数据展示
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        _keyword.isEmpty ? "Enter keyword to search" : "No user found",
                        style: TextStyle(color: context.textSecondary700),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (ctx, i) {
                      final user = users[i];
                      // 监听添加好友按钮的状态（loading）
                      final addActionState = ref.watch(addFriendControllerProvider(user.id));

                      return ListTile(
                        contentPadding: EdgeInsets.zero, // 清除默认边距，完全自定义
                        leading: CircleAvatar(
                          radius: 20.r,
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          backgroundColor: context.bgSecondary,
                          child: user.avatar == null
                              ? Icon(Icons.person, color: context.textSecondary700, size: 20.r)
                              : null,
                        ),
                        title: Text(
                            user.nickname,
                            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900, fontWeight: FontWeight.w500)
                        ),
                        trailing: Button(
                          width: 64.w,
                          height: 32.h,
                          radius: 6.r,
                          loading: addActionState.isLoading,
                          onPressed: addActionState.isLoading
                              ? null
                              : () async {
                            final success = await ref
                                .read(addFriendControllerProvider(user.id).notifier)
                                .execute();

                            // 成功后刷新会话列表 (如果有必要的话，或者刷新好友列表)
                            ref.invalidate(conversationListProvider);

                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text("Add", style: TextStyle(fontSize: 12.sp)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 骨架屏构建方法
  Widget _buildSkeletonList(BuildContext context) {
    return ListView.separated(
      itemCount: 6, // 默认显示 6 个占位
      physics: const NeverScrollableScrollPhysics(), // 禁止滚动
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Row(
          children: [
            // 左侧头像骨架
            Skeleton.react(
                width: 40.r,
                height: 40.r,
                borderRadius: BorderRadius.circular(20.r)
            ),
            SizedBox(width: 16.w),
            // 中间昵称骨架
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(width: 120.w, height: 16.h),
                  SizedBox(height: 6.h),
                  Skeleton.react(width: 80.w, height: 12.h), // 模拟 ID 或其他信息
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // 右侧按钮骨架
            Skeleton.react(
                width: 64.w,
                height: 32.h,
                borderRadius: BorderRadius.circular(6.r)
            ),
          ],
        );
      },
    );
  }
}