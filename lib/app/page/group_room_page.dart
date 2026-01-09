import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/groups.dart';
import '../../core/providers/product_provider.dart';
import '../../ui/button/button.dart'; // 推荐引入 share_plus 库

class GroupRoomPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupRoomPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupRoomPage> createState() => _GroupRoomPageState();
}

class _GroupRoomPageState extends ConsumerState<GroupRoomPage> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // 启动轮询: 每3秒刷新一次状态
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // 只有当前页面在顶层时才刷新 (简单优化)
      if (mounted) {
        // 使用 ref.refresh 强制重新请求
        ref.refresh(groupDetailProvider(widget.groupId));
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return BaseScaffold(
      title: 'Group Detail',
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (group) {
          // 如果团已经结束 (成功或失败)，停止轮询
          if (group.groupStatus != 1) {
            _pollingTimer?.cancel();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // 1. 状态卡片
                _buildStatusCard(context, group),
                SizedBox(height: 24.w),

                // 2. 成员坑位 (核心)
                _buildMemberSlots(context, group),
                SizedBox(height: 40.w),

                // 3. 邀请/操作按钮
                _buildActionButtons(context, group),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, GroupForTreasureItem group) {
    bool isSuccess = group.groupStatus == 2;
    bool isFail = group.groupStatus == 3;
    bool isOngoing = group.groupStatus == 1;

    Color statusColor = isSuccess ? Colors.green : (isFail ? Colors.grey : Colors.orange);
    String statusText = isSuccess
        ? "Group Success!"
        : (isFail ? "Group Failed" : "Waiting for members...");

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 16.w),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : (isFail ? Icons.cancel : Icons.access_time_filled),
            size: 48.w,
            color: statusColor,
          ),
          SizedBox(height: 12.w),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (isOngoing) ...[
            SizedBox(height: 8.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Time Left: ", style: TextStyle(color: Colors.grey[700])),
                CountdownTimer(
                  endTime: group.expireAt,
                  textStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  onEnd: () {
                    // 倒计时结束，手动刷新一次看最终状态
                    ref.refresh(groupDetailProvider(widget.groupId));
                  },
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMemberSlots(BuildContext context, GroupForTreasureItem group) {
    // 假设最大5人，根据 maxMembers 生成坑位
    int max = group.maxMembers;
    List<Widget> slots = [];

    for (int i = 0; i < max; i++) {
      // 检查该位置是否有人
      // 注意：group.members 可能是空或者数量不够
      GroupMemberItem? member;
      if (group.members != null && i < group.members!.length) {
        member = group.members![i];
      }

      slots.add(_buildSingleSlot(context, member));
    }

    return Wrap(
      spacing: 16.w,
      runSpacing: 16.w,
      alignment: WrapAlignment.center,
      children: slots,
    );
  }

  Widget _buildSingleSlot(BuildContext context, GroupMemberItem? member) {
    bool isEmpty = member == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isEmpty ? Colors.grey[300]! : Colors.orange,
              width: 2.w,
              style: BorderStyle.solid,
            ),
            image: isEmpty ? null : DecorationImage(
              image: NetworkImage(member!.user?.avatar ?? ''),
              fit: BoxFit.cover,
            ),
          ),
          child: isEmpty
              ? Icon(Icons.question_mark, color: Colors.grey[300])
              : null,
        ),
        SizedBox(height: 8.w),
        Container(
          width: 60.w,
          alignment: Alignment.center,
          child: Text(
            isEmpty ? "Wait..." : (member!.user?.nickname ?? "User"),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ),
        if (member != null && member.isOwner == 1)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4.r)),
            child: Text("Leader", style: TextStyle(color: Colors.white, fontSize: 8.sp)),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GroupForTreasureItem group) {
    // 1. 进行中 -> 邀请好友
    if (group.groupStatus == 1) {
      return Column(
        children: [
          Button(
            width: double.infinity,
            onPressed: () {
              // 调用系统分享
              Share.share('Come and join my group! Treasure: ${group.treasureId} Link: https://yourapp.com/group/${group.groupId}');
            },
            child: Text("Invite Friends", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 12.w),
          Text(
            "Share link to your friends to join faster!",
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      );
    }

    // 2. 成功 -> 查看订单
    if (group.groupStatus == 2) {
      return Button(
        width: double.infinity,
        onPressed: () {
          // 跳转订单列表
          appRouter.go('/orders'); // 或其他路径
        },
        child: Text("View My Order", style: TextStyle(color: Colors.white)),
      );
    }

    // 3. 失败 -> 重新开团
    return Button(
      width: double.infinity,
      onPressed: () {
        appRouter.push('/product/${group.treasureId}');
      },
      child: Text("Try Again", style: TextStyle(color: Colors.white)),
    );
  }
}