import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactListPage extends ConsumerWidget {
  const ContactListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听好友列表
    final asyncContacts = ref.watch(contactListProvider);

    // 2. 监听好友申请列表 (为了显示小红点)
    // 这里的 friendRequestListProvider 是我们刚刚在 contact_provider.dart 里加的
    final asyncRequests = ref.watch(friendRequestListProvider);
    final int requestCount = asyncRequests.valueOrNull?.length ?? 0;

    return BaseScaffold(
      title: "Contacts",
      actions: [
        IconButton(
          icon: Icon(Icons.person_add_alt_1_outlined, size: 24.sp, color: context.textPrimary900),
          onPressed: () {
            // 跳转到搜索页
            appRouter.push('/contact/search');
          },
        ),
      ],
      body: Column(
        children: [
          _buildNewFriendEntry(context, requestCount),

          // 分割线
          Divider(height: 1, color: context.bgSecondary),

          // 下方：真实的好友列表
          Expanded(
            child: asyncContacts.when(
              loading: () => _buildSkeleton(context),
              error: (err, stack) => Center(child: Text("Load Error: $err")),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return _buildEmptyState(context);
                }

                // 暂时简单的 ListView，下一步我们会把它升级成 A-Z 索引列表
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final user = contacts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      leading: CircleAvatar(
                        radius: 20.r,
                        backgroundColor: context.bgBrandSecondary,
                        backgroundImage: user.avatar != null
                            ? CachedNetworkImageProvider(
                          UrlResolver.resolveImage(context, user.avatar!, logicalWidth: 40),
                        )
                            : null,
                        child: user.avatar == null
                            ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
                            style: TextStyle(color: context.textSecondary700))
                            : null,
                      ),
                      title: Text(
                        user.nickname,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: context.textPrimary900),
                      ),
                      onTap: () {
                        appRouter.push('/contact/profile/${user.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建“新的朋友”入口
  Widget _buildNewFriendEntry(BuildContext context, int count) {
    return InkWell(
      onTap: () {
        // 跳转到新的朋友申请列表页 (NewFriendPage)
        // 记得在 router 里注册这个路径
        appRouter.push('/contact/new-friends');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: context.bgPrimary,
        child: Row(
          children: [
            // 固定图标：橙色背景的添加好友图标
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.person_add, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 12.w),

            // 文字
            Expanded(
              child: Text(
                "New Friends",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: context.textPrimary900),
              ),
            ),

            // 小红点 (如果有申请)
            if (count > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),

            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Skeleton.react(width: 40.r, height: 40.r, borderRadius: BorderRadius.circular(20.r)),
              SizedBox(width: 16.w),
              Skeleton.react(width: 120.w, height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text("No contacts yet", style: TextStyle(color: context.textSecondary700)),
    );
  }
}