import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import 'package:flutter_app/ui/chat/models/group_manage_req.dart';

class GroupRequestListPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupRequestListPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupRequestListPage> createState() => _GroupRequestListPageState();
}

class _GroupRequestListPageState extends ConsumerState<GroupRequestListPage> {
  // 记录正在操作的 Item ID，实现局部 Loading
  final Set<String> _processingIds = {};

  Future<void> _handleRequest(String requestId, bool isAccept) async {
    setState(() => _processingIds.add(requestId));

    // 调用 Controller 处理
    final success = await ref
        .read(groupJoinControllerProvider.notifier)
        .handleRequest(
        groupId: widget.groupId,
        requestId: requestId,
        isAccept: isAccept
    );

    if (mounted) {
      setState(() => _processingIds.remove(requestId));
      if (success) {
        RadixToast.success(isAccept ? "Member added" : "Request rejected");
      } else {
        RadixToast.error("Operation failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Provider
    final asyncList = ref.watch(groupJoinRequestsProvider(widget.groupId));
    print("GroupRequestListPage: rebuild with state = ${asyncList.value.toString()}");

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        title: Text("Join Applications",
            style: TextStyle(
                color: context.textPrimary900, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: context.bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary900),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text("Load failed: $err",
                style: TextStyle(color: context.textSecondary700))),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: requests.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final req = requests[index];
              return _RequestCard(
                request: req,
                isProcessing: _processingIds.contains(req.id),
                onHandle: (accept) => _handleRequest(req.id, accept),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined,
              size: 80.r, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text("No pending requests",
              style: TextStyle(
                  fontSize: 16.sp, color: context.textSecondary700)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  // 1. 【修改】类型改为 GroupJoinRequestItem
  final GroupJoinRequestItem request;
  final bool isProcessing;
  final Function(bool) onHandle;

  const _RequestCard({
    required this.request,
    required this.isProcessing,
    required this.onHandle,
  });

  @override
  Widget build(BuildContext context) {
    // 2. 【修改】使用 Enum 判断状态
    final isPending = request.status == GroupRequestStatus.pending;

    // 3. 【修改】字段名改为 createTime (int)
    final dateStr = DateTime.fromMillisecondsSinceEpoch(request.createdAt);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Time
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: CachedNetworkImage(
                  // applicant 现在是非空的，可以直接用
                  imageUrl: UrlResolver.resolveImage(
                      context, request.applicant.avatar,
                      logicalWidth: 40),
                  width: 40.r,
                  height: 40.r,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      Container(color: Colors.grey[300]),
                ),
              ),
              SizedBox(width: 12.w),
              // Name & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.applicant.nickname,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // 时间显示
                    Text(
                      "${dateStr.month}/${dateStr.day} ${dateStr.hour}:${dateStr.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondary700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Middle: Reason Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: context.bgSecondary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Apply Reason: ",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondary700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: request.reason.isEmpty ? "None" : request.reason,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textPrimary900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Bottom: Action Buttons
          isPending
              ? _buildPendingActions(context)
              : _buildHandledStatus(context),
        ],
      ),
    );
  }

  // 状态：待处理 (显示按钮)
  Widget _buildPendingActions(BuildContext context) {
    if (isProcessing) {
      return Center(
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(strokeWidth: 2.r),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => onHandle(false), // Reject
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text("Reject",
                style: TextStyle(
                    color: context.textSecondary700, fontSize: 14.sp)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onHandle(true), // Accept
            style: ElevatedButton.styleFrom(
              backgroundColor: context.textBrandPrimary900,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text("Accept",
                style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ),
      ],
    );
  }

  // 状态：已处理 (显示结果)
  Widget _buildHandledStatus(BuildContext context) {
    // 4. 【修改】使用 Enum 判断
    final isAccepted = request.status == GroupRequestStatus.accepted;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAccepted ? Icons.check_circle : Icons.cancel,
            size: 16.r,
            color: isAccepted ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 6.w),
          Text(
            isAccepted ? "Added" : "Rejected",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isAccepted ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}