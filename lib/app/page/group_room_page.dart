import 'dart:async';
// 必须引入
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/index.dart';
import '../../core/models/groups.dart';
import '../../core/providers/product_provider.dart';
import '../../features/share/models/share_content.dart';
import '../../features/share/services/app_share_manager.dart';

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
    _startPolling();
  }

  void _startPolling() {
    // 启动轮询: 每3秒刷新一次
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        // 使用 invalidate 标记数据过期，触发静默刷新
        ref.invalidate(groupDetailProvider(widget.groupId));
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    // 监听状态变化：如果团购结束，停止轮询
    ref.listen(groupDetailProvider(widget.groupId), (previous, next) {
      next.whenData((group) {
        if (group.groupStatus != 1) {
          _stopPolling();
        }
      });
    });

    return BaseScaffold(
      title: 'Group Detail',
      body: groupAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (group) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: 1.sh - 100.h),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(context, group),
                  SizedBox(height: 24.h),
                  Text(
                    "Members (${group.members.length}/${group.maxMembers})",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildMemberSlots(context, group),
                  SizedBox(height: 30.h,),
                  _buildActionButtons(context, group),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建状态卡片
  Widget _buildStatusCard(BuildContext context, GroupDetailModel group) {
    bool isSuccess = group.groupStatus == 2;
    bool isFail = group.groupStatus == 3;
    bool isOngoing = group.groupStatus == 1;

    Color statusColor = isSuccess
        ? Colors.green
        : (isFail ? Colors.grey : Colors.orange);
    String statusText = isSuccess
        ? "Group Success!"
        : (isFail ? "Group Failed" : "Waiting for members...");

    // 获取毫秒时间戳，处理空值
    int endTime = group.expireAt ?? 0;

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
            isSuccess
                ? Icons.check_circle
                : (isFail ? Icons.cancel : Icons.access_time_filled),
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
                  endTime: endTime,
                  textStyle: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  onEnd: () {
                    // 倒计时结束，立即刷新一次以获取最新状态
                    ref.invalidate(groupDetailProvider(widget.groupId));
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 构建成员坑位列表
  Widget _buildMemberSlots(BuildContext context, GroupDetailModel group) {
    // 使用 List.generate 生成固定数量的坑位
    return Wrap(
      spacing: 16.w,
      runSpacing: 16.w,
      alignment: WrapAlignment.center,
      children: List.generate(group.maxMembers, (index) {
        // 尝试获取当前位置的成员
        GroupMemberItem? member;
        if (index < group.members.length) {
          member = group.members[index];
        }
        return _buildSingleSlot(context, member);
      }),
    );
  }

  // 构建单个坑位 (头像)
  Widget _buildSingleSlot(BuildContext context, GroupMemberItem? member) {
    bool isEmpty = member == null;
    String avatarUrl = member?.user?.avatar ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100], // 背景底色
            border: Border.all(
              color: isEmpty ? Colors.grey[300]! : Colors.orange,
              width: 2.w,
              style: BorderStyle.solid,
            ),
          ),
          child: isEmpty
              // 情况 A: 空位
              ? Icon(Icons.question_mark, color: Colors.grey[300], size: 24.w)
              : AppCachedImage(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: 32.w,
                  height: 32.w,
                  radius: BorderRadius.circular(28.w),
                  placeholder: Icon(
                    Icons.person,
                    size: 32.w,
                    color: Colors.grey[300],
                  ),
                  error: Icon(Icons.person, size: 32.w, color: Colors.grey),
                ),
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
              color: isEmpty ? Colors.grey : Colors.grey[800],
            ),
          ),
        ),
        // 团长标签
        if (member != null && member.isLeader)
          Container(
            margin: EdgeInsets.only(top: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              "Leader",
              style: TextStyle(color: Colors.white, fontSize: 8.sp),
            ),
          ),
      ],
    );
  }

  // 构建操作按钮
  Widget _buildActionButtons(BuildContext context, GroupDetailModel group) {

    String treasureName = group.treasure?.treasureName ?? '';
    String treasureImg = group.treasure?.treasureCoverImg ?? '';
    String treasureId = group.treasure?.treasureId ?? '';
    // 计算剩余人数 (假设 maxMembers 和 currentMembers 是你 Model 里的字段)
    final int remain = group.maxMembers - group.members.length;

    // 1. 进行中 -> 邀请好友
    if (group.groupStatus == 1) {
      return Column(
        children: [
          Button(
            width: double.infinity,
            onPressed: () {
              ShareManager.startShare(
                context,
                ShareContent.group(
                  id: treasureId,
                  groupId: group.groupId,
                  title: treasureName,
                  imageUrl: treasureImg,
                  desc: "快来加入我的【$treasureName】拼团，还差$remain人就成功啦！",
                ),
              );
            },
            child: Text(
              "Invite Friends",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          appRouter.go('/orders');
        },
        child: Text("View My Order", style: TextStyle(color: Colors.white)),
      );
    }

    // 3. 失败 -> 重新开团
    return Button(
      width: double.infinity,
      onPressed: () {
        appRouter.push('/product/$treasureId');
      },
      child: Text("Try Again", style: TextStyle(color: Colors.white)),
    );
  }
}
