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

import '../../utils/media/url_resolver.dart';
import '../toast/radix_toast.dart';
import 'models/friend_request.dart';

class NewFriendPage extends ConsumerWidget {
  const NewFriendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
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
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isAccepted) {
      return Text(
        "Added",
        style: TextStyle(color: context.textSecondary700, fontSize: 14.sp, fontWeight: FontWeight.w500),
      );
    }

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
    setState(() => _isAccepted = true);

    final success = await ref
        .read(handleRequestControllerProvider.notifier)
        .execute(
      userId: widget.request.id,
      action: FriendRequestAction.accepted,
    );

    if (!success) {
      if (mounted) {
        setState(() => _isAccepted = false);
        RadixToast.error("Operation failed");
      }
    } else {
      //  修改标注：双重失效联动
      // 1. 刷新好友列表 (让通讯录出现新朋友)
      ref.invalidate(contactListProvider);

      // 2. 刷新申请列表 (让已处理的消息消失，从而让通讯录红点归零)
      ref.invalidate(friendRequestListProvider);
    }
  }
}