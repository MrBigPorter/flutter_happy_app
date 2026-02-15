import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../toast/radix_toast.dart';
import '../../modal/dialog/radix_modal.dart';

class GroupMemberSelectPage extends ConsumerStatefulWidget {
  final String? existingGroupId;
  final String? preSelectedId;

  const GroupMemberSelectPage({
    super.key,
    this.existingGroupId,
    this.preSelectedId,
  });

  @override
  ConsumerState<GroupMemberSelectPage> createState() => _GroupMemberSelectPageState();
}

class _GroupMemberSelectPageState extends ConsumerState<GroupMemberSelectPage> {
  final Set<String> _selectedIds = {};
  String _searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();

  bool get isInviteMode => widget.existingGroupId != null;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedId != null && widget.preSelectedId!.isNotEmpty) {
      _selectedIds.add(widget.preSelectedId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactListProvider);

    // 状态监听保持不变
    final bool isLoading = isInviteMode
        ? ref.watch(chatGroupProvider(widget.existingGroupId!)).isLoading
        : ref.watch(groupCreateControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: _buildAppBar(context, isLoading),
      body: Column(
        children: [
          _buildSearchBar(context),
          if (_selectedIds.isNotEmpty) _buildSelectedList(context, contactState),
          Expanded(
            child: contactState.when(
              loading: () => _buildSkeletonList(context),
              error: (err, _) => Center(child: Text("Load failed: $err")),
              data: (friends) {
                // 客户端搜索过滤
                final filtered = friends.where((f) =>
                    f.nickname.toLowerCase().contains(_searchKeyword.toLowerCase())).toList();

                if (filtered.isEmpty) return _buildEmptyState(context);

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildMemberItem(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 模块化 UI 组件 ---

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLoading) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.bgPrimary,
      title: Text(isInviteMode ? "Invite Members" : "New Group",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
      centerTitle: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Center(
            child: InkWell(
              onTap: (_selectedIds.isEmpty || isLoading) ? null : _handleDoneAction,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _selectedIds.isEmpty ? context.bgSecondary : context.textBrandPrimary900,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: isLoading
                    ? SizedBox(width: 18.w, height: 18.w, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isInviteMode ? "Invite" : "Next", style: TextStyle(
                    color: _selectedIds.isEmpty ? context.textDisabled : Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchKeyword = val),
        decoration: InputDecoration(
          hintText: "Search friends...",
          prefixIcon: Icon(Icons.search, size: 20.r, color: context.textSecondary700),
          filled: true,
          fillColor: context.bgSecondary,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSelectedList(BuildContext context, AsyncValue<List<dynamic>> contactState) {
    return contactState.maybeWhen(
      data: (friends) {
        final selectedFriends = friends.where((f) => _selectedIds.contains(f.id)).toList();
        return Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: selectedFriends.length,
            itemBuilder: (context, index) {
              final user = selectedFriends[index];
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundImage: CachedNetworkImageProvider(UrlResolver.resolveImage(context, user.avatar)),
                    ),
                    Positioned(
                      right: 0, top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIds.remove(user.id)),
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(color: context.utilityError200, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 10.r, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }

  Widget _buildMemberItem(BuildContext context, dynamic user) {
    final isSelected = _selectedIds.contains(user.id);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) _selectedIds.remove(user.id);
          else _selectedIds.add(user.id);
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // 自定义勾选框
            Container(
              width: 22.r, height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? context.textBrandPrimary900 : context.borderPrimary, width: 2),
                color: isSelected ? context.textBrandPrimary900 : Colors.transparent,
              ),
              child: isSelected ? Icon(Icons.check, size: 14.r, color: Colors.white) : null,
            ),
            SizedBox(width: 16.w),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: context.bgSecondary,
              backgroundImage: CachedNetworkImageProvider(UrlResolver.resolveImage(context, user.avatar)),
            ),
            SizedBox(width: 12.w),
            Text(user.nickname, style: TextStyle(fontSize: 16.sp, color: context.textPrimary900, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64.r, color: context.textDisabled),
          SizedBox(height: 12.h),
          Text("No results for '$_searchKeyword'", style: TextStyle(color: context.textSecondary700)),
        ],
      ),
    );
  }

  // --- 业务逻辑保持不变 ---

  void _handleDoneAction() {
    if (isInviteMode) _executeInvite();
    else _showGroupNameDialog();
  }

  Future<void> _executeInvite() async {
    final success = await ref
        .read(chatGroupProvider(widget.existingGroupId!).notifier)
        .inviteMembers(_selectedIds.toList());

    if (!mounted) return;
    if (success) {
      RadixToast.success("Invitation sent");
      context.pop();
    } else {
      RadixToast.error("Failed to invite members");
    }
  }

  Future<void> _executeCreate(String name) async {
    final newGroupId = await ref
        .read(groupCreateControllerProvider.notifier)
        .create(name: name, memberIds: _selectedIds.toList());

    if (newGroupId != null && mounted) {
      RadixToast.success("Group created");
      context.go('/chat/room/$newGroupId');
    }
  }

  void _showGroupNameDialog() {
    final TextEditingController nameController = TextEditingController();
    RadixModal.show(
      title: "Group Name",
      builder: (ctx, _) => Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter group name",
            filled: true,
            fillColor: context.bgSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
          ),
        ),
      ),
      confirmText: "Create",
      onConfirm: (close) {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          close();
          _executeCreate(name);
        }
      },
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        leading: Skeleton.react(width: 40.r, height: 40.r, borderRadius: BorderRadius.circular(20.r)),
        title: Skeleton.react(width: 150.w, height: 16.h),
      ),
    );
  }
}