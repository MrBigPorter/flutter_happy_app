import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_debounce/easy_debounce.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import 'models/conversation.dart';

class ContactSearchPage extends ConsumerStatefulWidget {
  const ContactSearchPage({super.key});

  @override
  ConsumerState<ContactSearchPage> createState() => _ContactSearchPageState();
}

class _ContactSearchPageState extends ConsumerState<ContactSearchPage> {
  final TextEditingController _searchCtl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const String _debounceTag = 'search_debounce';
  String _keyword = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _focusNode.dispose();
    EasyDebounce.cancel(_debounceTag);
    super.dispose();
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      _debounceTag,
      const Duration(milliseconds: 500),
          () {
        if (value.trim() != _keyword) {
          setState(() {
            _keyword = value.trim();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(chatContactsSearchProvider(_keyword));

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary900, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40.h,
          margin: EdgeInsets.only(right: 16.w),
          child: TextField(
            controller: _searchCtl,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
            decoration: InputDecoration(
              hintText: "Search by ID / Phone / Nickname",
              hintStyle: TextStyle(color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
              filled: true,
              fillColor: context.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _keyword.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchCtl.clear();
                  EasyDebounce.cancel(_debounceTag);
                  setState(() => _keyword = "");
                },
                child: Icon(Icons.clear, color: Colors.grey, size: 20.sp),
              )
                  : null,
            ),
          ),
        ),
      ),
      body: _keyword.isEmpty
          ? _buildEmptyState(context)
          : searchAsync.when(
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Search failed: $err")),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                "No user found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: users.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return _UserSearchResultItem(user: users[index]);
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
          Icon(Icons.search, size: 64.sp, color: Colors.grey.withOpacity(0.3)),
          SizedBox(height: 16.h),
          Text(
            "Find friends globally",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: List.generate(
          3,
              (index) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              children: [
                Skeleton.react(width: 50.r, height: 50.r, borderRadius: BorderRadius.circular(25.r)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: 120.w, height: 16.h),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 80.w, height: 12.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 独立的 Item 组件
class _UserSearchResultItem extends ConsumerStatefulWidget {
  final ChatUser user;

  const _UserSearchResultItem({required this.user});

  @override
  ConsumerState<_UserSearchResultItem> createState() => _UserSearchResultItemState();
}

class _UserSearchResultItemState extends ConsumerState<_UserSearchResultItem> {
  // 乐观 UI 状态：如果用户在当前页面发起了申请，这个值会变为 true
  bool _optimisticSent = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final bool hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24.r,
            backgroundColor: Colors.blueAccent,
            backgroundImage: hasAvatar ? CachedNetworkImageProvider(user.avatar!) : null,
            onBackgroundImageError: hasAvatar
                ? (exception, stackTrace) => debugPrint("Avatar error: $exception")
                : null,
            child: !hasAvatar
                ? Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
              style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary900),
            )
                : null,
          ),
          SizedBox(width: 12.w),
          // 信息
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary900,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  "ID: ${user.id}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary700,
                    fontWeight: FontWeight.w400,
                  ),
                )
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // 按钮
          _buildActionButton(context, user),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ChatUser user) {

    // 1. 如果已经是好友 -> 显示 "Added" 且不可点击
    if (user.status == RelationshipStatus.friend) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Text(
          "Added",
          style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
        ),
      );
    }

    // 2. 如果已发送申请 (无论是后端返回的，还是刚才点击的) -> 显示 "Sent"
    if (user.status == RelationshipStatus.sent || _optimisticSent) {
      return Container(
        width: 70.w,
        height: 32.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.bgSecondary, // 灰色背景
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          "Sent",
          style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
        ),
      );
    }

    // 3. 陌生人 -> 显示 "Add" 按钮
    return Button(
      variant: ButtonVariant.primary,
      height: 32.h,
      width: 70.w,
      onPressed: () => _handleAdd(user.id),
      child: Text('Add', style: TextStyle(fontSize: 12.sp)),
    );
  }

  Future<void> _handleAdd(String userId) async {
    // 乐观更新
    setState(() => _optimisticSent = true);

    final success = await ref.read(addFriendControllerProvider(userId).notifier).execute();

    if (!success) {
      if (mounted) {
        // 失败回滚
        setState(() => _optimisticSent = false);
        RadixToast.error("Request failed");
      }
    } else {
      RadixToast.success("Friend request sent");
    }
  }
}