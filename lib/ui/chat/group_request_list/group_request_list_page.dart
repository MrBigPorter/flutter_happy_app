import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import '../models/group_manage_req.dart';

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

    final success = await ref
        .read(groupJoinControllerProvider.notifier)
        .handleRequest(
        groupId: widget.groupId, requestId: requestId, isAccept: isAccept);

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
    final asyncList = ref.watch(groupJoinRequestsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: context.bgSecondary, // 浅灰背景
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
  final GroupJoinRequest request;
  final bool isProcessing;
  final Function(bool) onHandle;

  const _RequestCard({
    required this.request,
    required this.isProcessing,
    required this.onHandle,
  });

  @override
  Widget build(BuildContext context) {
    // status: 0=Pending, 1=Accepted, 2=Rejected
    final isPending = request.status == 0;
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
                  imageUrl: UrlResolver.resolveImage(
                      context, request.applicant?.avatar,
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
                      request.applicant?.nickname ?? "Unknown User",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // 使用 timeago 或简单的日期显示
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
              color: context.bgSecondary, // 浅色背景框
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
    final isAccepted = request.status == 1;
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