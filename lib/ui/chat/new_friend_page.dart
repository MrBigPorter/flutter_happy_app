import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../utils/url_resolver.dart';
import '../toast/radix_toast.dart';
import 'models/friend_request.dart';

class NewFriendPage extends ConsumerWidget {
  const NewFriendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听申请列表
    final asyncRequests = ref.watch(friendRequestListProvider);

    return BaseScaffold(
      title: "New Friends",
      body: asyncRequests.when(
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Load failed: $err")),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64.sp, color: context.textSecondary700.withOpacity(0.3)),
                  SizedBox(height: 16.h),
                  Text("No friend requests", style: TextStyle(color: context.textSecondary700)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              return _RequestItem(request: requests[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: EdgeInsets.only(top: 10.h),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(8.r)),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(width: 100.w, height: 16.h),
                  SizedBox(height: 6.h),
                  Skeleton.react(width: 150.w, height: 12.h),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestItem extends ConsumerStatefulWidget {
  final FriendRequest request;
  const _RequestItem({required this.request});

  @override
  ConsumerState<_RequestItem> createState() => _RequestItemState();
}

class _RequestItemState extends ConsumerState<_RequestItem> {
  // 局部状态：控制按钮显示 "Added"
  // 默认是 false，点击同意后变为 true
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 1. 头像
          CircleAvatar(
            radius: 24.r,
            backgroundColor: context.bgBrandSecondary,
            backgroundImage: (req.avatar?.isNotEmpty == true)
                ? CachedNetworkImageProvider(UrlResolver.resolveImage(context, req.avatar!))
                : null,
            child: req.avatar == null
                ? Text(req.nickname[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold))
                : null,
          ),
          SizedBox(width: 12.w),

          // 2. 信息 (昵称 + 理由)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.nickname,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                ),
                SizedBox(height: 4.h),
                Text(
                  req.reason?.isNotEmpty == true ? req.reason! : "Request to add you",
                  style: TextStyle(fontSize: 13.sp, color: context.textSecondary700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. 操作区 (接受按钮 或 状态文字)
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // 如果已同意，显示灰色文字
    if (_isAccepted) {
      return Text(
        "Added",
        style: TextStyle(color: context.textSecondary700, fontSize: 14.sp, fontWeight: FontWeight.w500),
      );
    }

    // 否则显示接受按钮
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: ButtonVariant.primary,
          height: 30.h,
          width: 60.w,
          onPressed: _handleAccept,
          child: Text("Accept", style: TextStyle(fontSize: 12.sp)),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    // 1. 乐观 UI：立即变灰，给用户即时反馈
    setState(() => _isAccepted = true);

    // 2. 调用 Controller 执行网络请求
    final success = await ref
        .read(handleRequestControllerProvider.notifier)
        .execute(
      userId: widget.request.id, // 这里传的是申请人的 ID
      action: FriendRequestAction.accepted, // 传枚举值
    );

    // 3. 如果失败，回滚状态并提示
    if (!success) {
      if (mounted) {
        setState(() => _isAccepted = false);
        RadixToast.error("Operation failed");
      }
    } else {
      // 成功其实不需要额外提示，变成 "Added" 就够了
      // 如果需要，可以 RadixToast.success("Added");
    }
  }
}