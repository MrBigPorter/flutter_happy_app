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

  // 定义防抖的 Tag
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
    //  页面销毁时取消防抖任务，防止内存泄漏或报错
    EasyDebounce.cancel(_debounceTag);
    super.dispose();
  }

  // 使用 EasyDebounce 进行防抖
  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      _debounceTag,
      const Duration(milliseconds: 500), // 500ms 延迟
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
    final searchAsync = ref.watch(userSearchProvider(_keyword));

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        backgroundColor:context.bgPrimary,
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
              fillColor:context.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _keyword.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchCtl.clear();
                  EasyDebounce.cancel(_debounceTag); // 清除时也取消正在进行的防抖
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

class _UserSearchResultItem extends ConsumerStatefulWidget {
  final ChatUser user;

  const _UserSearchResultItem({required this.user});

  @override
  ConsumerState<_UserSearchResultItem> createState() => _UserSearchResultItemState();
}

class _UserSearchResultItemState extends ConsumerState<_UserSearchResultItem> {
  bool _isSent = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

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
            backgroundImage: (user.avatar?.isNotEmpty == true)
                ? NetworkImage(user.avatar!)
                : null,
            child: user.avatar == null
                ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
                style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary900))
                : null,
          ),
          SizedBox(width: 12.w),

         Expanded(child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // 1. 昵称 (占据主要空间，过长省略)
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

             SizedBox(width: 8.w), // 间距

             // 2. ID (跟在后面)
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
         ),),

          SizedBox(width: 8.w),

          // 按钮
          _buildActionButton(context, user)
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ChatUser user) {
    return Button(
      variant: ButtonVariant.primary,
      disabled: _isSent,
      height: 32.h,
      width: 70.w,
      onPressed: () => _handleAdd(user.id),
      child: Text( _isSent ? 'Send' : 'Add', style: TextStyle(fontSize: 12.sp)),
    );
  }

  Future<void> _handleAdd(String userId) async {
    setState(() => _isSent = true);
    final success = await ref.read(addFriendControllerProvider(userId).notifier).execute();

    if (!success) {
      if (mounted) {
        setState(() => _isSent = false);
        RadixToast.error("Request failed");
      }
    } else {
      RadixToast.success("Friend request sent");
    }
  }
}