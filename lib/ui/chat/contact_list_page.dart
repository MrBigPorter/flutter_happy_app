import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../utils/image_url.dart';


class ContactListPage extends ConsumerWidget {
  const ContactListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听好友列表
    final asyncContacts = ref.watch(contactListProvider);

    return BaseScaffold(
      title: "Contacts",
      body: asyncContacts.when(
        loading: () => _buildSkeleton(context),
        // 这里把错误详情显示出来，方便调试
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Load Error: $err", style: TextStyle(color: Colors.red)),
          ),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48.w, color: context.textSecondary700),
                  SizedBox(height: 10.h),
                  const Text("No friends yet"),
                  TextButton(
                    onPressed: () {
                      // 这里可以触发添加好友的弹窗，或者提示用户去右上角添加
                    },
                    child: const Text("Add Friend"),
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 72.w, color: context.bgSecondary),
            itemBuilder: (context, index) {
              final user = contacts[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                leading: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: context.bgSecondary,
                  backgroundImage: user.avatar != null
                      ? CachedNetworkImageProvider(
                    ImageUrl.build(
                      context,
                      user.avatar!,
                      logicalWidth: 48, // Radius 24 * 2
                    ),
                  )
                      : null,
                  child: user.avatar == null
                      ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?", style: TextStyle(color: context.textSecondary700))
                      : null,
                ),
                title: Text(
                  user.nickname,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: context.textPrimary900),
                ),
                onTap: () {
                  context.push('/contact/profile/${user.id}');
                },
              );
            },
          );
        },
      ),
    );
  }

  // 通讯录专属骨架屏
  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(24.r)),
              SizedBox(width: 16.w),
              Skeleton.react(width: 120.w, height: 16.h),
            ],
          ),
        );
      },
    );
  }
}